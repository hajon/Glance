// MenuBarContentView.swift
// Popover UI shown from the menu bar item.

import SwiftUI

struct MenuBarContentView: View {
    @StateObject private var model = MenuBarModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "speedometer")
                Text("Glance")
                    .font(.headline)
                Spacer()
                Text(model.pulse.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            GaugeRow(label: "CPU", value: model.pulse.cpuUsage, color: .blue)
            GaugeRow(label: "Memory", value: model.pulse.memoryUsage, color: .green)
            if let gpu = model.pulse.gpuUsage {
                GaugeRow(label: "GPU", value: gpu, color: .purple)
            }
            GaugeRow(label: "Disk", value: model.pulse.diskUsage, color: .orange)

            Text("Memory: \(MenuBarModel.usedBytes(for: model.pulse)) / \(PulseMath.formattedBytes(model.pulse.memoryTotal))")
                .font(.caption)
                .foregroundStyle(.secondary)

            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(16)
        .frame(width: 280)
        .onAppear { model.start() }
        .onDisappear { model.stop() }
    }
}

struct GaugeRow: View {
    let label: String
    let value: Double
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .frame(width: 60, alignment: .leading)
                .foregroundStyle(.secondary)
            ProgressView(value: value, total: 100)
                .progressViewStyle(.linear)
                .tint(color)
            Text(String(format: "%.0f%%", value))
                .monospacedDigit()
                .frame(width: 40, alignment: .trailing)
        }
        .font(.callout)
    }
}

final class MenuBarModel: ObservableObject {
    static func usedBytes(for pulse: GlancePulse) -> Double {
        pulse.memoryTotal * pulse.memoryUsage / 100
    }
    @Published var pulse = GlancePulse(
        cpuUsage: 0, memoryUsage: 0, memoryTotal: 0, diskUsage: 0
    )
    private var timer: Timer?
    private let sampler = PulseSampler()

    func start() {
        sampler.cpuUsage() // prime baseline
        pulse = sampler.sample()
        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.pulse = self.sampler.sample()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }
}

extension PulseMath {
    static func formattedBytes(_ bytes: Double) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(bytes))
    }
}
