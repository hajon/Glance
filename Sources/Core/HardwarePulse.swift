// HardwarePulse.swift
// Shared data model exchanged between the host app and the widget extension
// through the shared App Group container.

import Foundation

public struct HardwarePulse: Codable, Equatable, Sendable {
    public var timestamp: Date
    public var cpuUsage: Double
    public var memoryUsage: Double
    public var memoryTotal: Double
    public var gpuUsage: Double?
    public var diskUsage: Double

    public init(
        timestamp: Date = Date(),
        cpuUsage: Double,
        memoryUsage: Double,
        memoryTotal: Double,
        gpuUsage: Double? = nil,
        diskUsage: Double
    ) {
        self.timestamp = timestamp
        self.cpuUsage = cpuUsage
        self.memoryUsage = memoryUsage
        self.memoryTotal = memoryTotal
        self.gpuUsage = gpuUsage
        self.diskUsage = diskUsage
    }

    public var isStale: Bool {
        Date().timeIntervalSince(timestamp) > 900
    }
}

public enum HardwarePulseStore {
    public static func url(appGroupID: String) -> URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
            .appendingPathComponent("hardware-pulse.json")
    }

    public static func save(_ pulse: HardwarePulse, appGroupID: String) {
        guard let url = url(appGroupID: appGroupID) else { return }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(pulse) {
            try? data.write(to: url, options: .atomic)
        }
    }

    public static func load(appGroupID: String) -> HardwarePulse? {
        guard let url = url(appGroupID: appGroupID),
              let data = try? Data(contentsOf: url) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(HardwarePulse.self, from: data)
    }
}
