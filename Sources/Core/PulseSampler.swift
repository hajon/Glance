// PulseSampler.swift
// Samples hardware utilization on macOS. Pure derivation logic is separated
// from the mach/IOKit calls so it can be unit tested on any platform.

import Foundation

#if canImport(Darwin)
import Darwin
#endif

public struct CPUUsage: Equatable, Sendable {
    public var user: Double
    public var system: Double
    public var idle: Double

    public var total: Double { 100.0 - idle }

    public init(user: Double, system: Double, idle: Double) {
        self.user = user
        self.system = system
        self.idle = idle
    }
}

public enum PulseMath {
    /// Derives percentages between two cumulative tick snapshots.
    public static func usage(from previous: CPUUsage, to current: CPUUsage) -> CPUUsage {
        let dUser = max(0, current.user - previous.user)
        let dSystem = max(0, current.system - previous.system)
        let dIdle = max(0, current.idle - previous.idle)
        let total = dUser + dSystem + dIdle
        guard total > 0 else { return CPUUsage(user: 0, system: 0, idle: 100) }
        return CPUUsage(
            user: dUser / total * 100,
            system: dSystem / total * 100,
            idle: dIdle / total * 100
        )
    }
}

public final class PulseSampler: @unchecked Sendable {
    private var previousTicks: CPUUsage?

    public init() {}

    /// Cumulative CPU ticks across all cores (user, system, idle).
    public func cumulativeTicks() -> CPUUsage {
        var cpuLoad = host_cpu_load_info()
        var count = mach_msg_type_number_t(
            MemoryLayout<host_cpu_load_info_data_t>.stride / MemoryLayout<integer_t>.stride
        )
        let result = withUnsafeMutablePointer(to: &cpuLoad) { loadPtr in
            host_statistics(
                mach_host_self(),
                HOST_CPU_LOAD_INFO,
                loadPtr.withMemoryRebound(
                    to: integer_t.self,
                    capacity: Int(count)
                ) { $0 },
                &count
            )
        }
        guard result == KERN_SUCCESS else {
            return CPUUsage(user: 0, system: 0, idle: 100)
        }
        return CPUUsage(
            user: Double(cpuLoad.cpu_ticks[CPU_STATE_USER]),
            system: Double(cpuLoad.cpu_ticks[CPU_STATE_SYSTEM]),
            idle: Double(cpuLoad.cpu_ticks[CPU_STATE_IDLE])
        )
    }

    /// Percentage CPU usage since the previous call (0 on first call).
    public func cpuUsage() -> Double {
        let current = cumulativeTicks()
        defer { previousTicks = current }
        guard let previous = previousTicks else { return 0 }
        return PulseMath.usage(from: previous, to: current).total
    }

    /// Used and total physical memory in bytes.
    public func memoryUsage() -> (used: Double, total: Double) {
        var stats = vm_statistics64_data_t()
        var count = mach_msg_type_number_t(
            MemoryLayout<vm_statistics64_data_t>.stride / MemoryLayout<integer_t>.stride
        )
        let result = withUnsafeMutablePointer(to: &stats) { statsPtr in
            statsPtr.withMemoryRebound(
                to: integer_t.self,
                capacity: Int(count)
            ) { intPtr in
                host_statistics64(mach_host_self(), HOST_VM_INFO64, intPtr, &count)
            }
        }
        guard result == KERN_SUCCESS else { return (0, 0) }
        let pageSize = Double(vm_kernel_page_size)
        let free = Double(stats.free_count + stats.inactive_count) * pageSize
        let total = Double(ProcessInfo.processInfo.physicalMemory)
        return (max(0, total - free), total)
    }

    /// Root volume used fraction in percent (0...100).
    public func diskUsage() -> Double {
        let url = URL(fileURLWithPath: "/")
        guard
            let values = try? url.resourceValues(
                forKeys: [.volumeTotalCapacityKey, .volumeAvailableCapacityKey]
            ),
            let total = values.volumeTotalCapacity,
            let available = values.volumeAvailableCapacity,
            total > 0
        else { return 0 }
        return Double(total - available) / Double(total) * 100
    }

    /// GPU utilization on Apple Silicon via IOKit accelerator statistics.
    /// Returns nil on unsupported hardware or when the key is unavailable.
    public func gpuUsage() -> Double? {
        #if canImport(IOKit)
        var iterator = io_iterator_t(0)
        guard
            IOServiceGetMatchingServices(
                kIOMainPortDefault,
                IOServiceMatching("IOAccelerator"),
                &iterator
            ) == KERN_SUCCESS,
            iterator != IO_OBJECT_NULL
        else { return nil }
        defer { IOObjectRelease(iterator) }

        var utilization: Double?
        while utilization == nil {
            let entry = IOIteratorNext(iterator)
            if entry == IO_OBJECT_NULL { break }
            defer { IOObjectRelease(entry) }
            utilization = gpuUtilization(entry)
        }
        return utilization
        #else
        return nil
        #endif
    }

    #if canImport(IOKit)
    private func gpuUtilization(_ entry: io_object_t) -> Double? {
        guard
            let raw = IORegistryEntrySearchCFProperty(
                entry,
                "IOGraphicsAccelerator",
                "PerformanceStatistics" as CFString,
                kCFAllocatorDefault,
                UInt32(kIORegistryIterateParents | kIORegistryIterateRecursively)
            ),
            let stats = raw as? [String: Any]
        else { return nil }
        for key in ["Device Utilization %", "GPU Utilization %"] {
            if let value = stats[key] as? NSNumber { return value.doubleValue }
        }
        return nil
    }
    #endif

    /// Captures one full pulse snapshot.
    public func sample() -> GlancePulse {
        let (used, total) = memoryUsage()
        return GlancePulse(
            cpuUsage: cpuUsage(),
            memoryUsage: total > 0 ? used / total * 100 : 0,
            memoryTotal: total,
            gpuUsage: gpuUsage(),
            diskUsage: diskUsage()
        )
    }
}
