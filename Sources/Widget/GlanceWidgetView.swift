// GlanceWidgetView.swift
// Widget views for each size family.

import SwiftUI
import WidgetKit

struct GlanceWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: PulseEntry

    var body: some View {
        switch entry.pulse {
        case .some(let pulse):
            content(pulse)
        case .none:
            UnavailableView()
        }
    }

    @ViewBuilder
    private func content(_ pulse: GlancePulse) -> some View {
        switch family {
        case .systemSmall: SmallView(pulse: pulse)
        case .systemMedium: MediumView(pulse: pulse)
        case .accessoryCircular: CircularView(pulse: pulse)
        case .accessoryInline: InlineView(pulse: pulse)
        case .accessoryRectangular: RectangularView(pulse: pulse)
        default: SmallView(pulse: pulse)
        }
    }
}

struct SmallView: View {
    let pulse: GlancePulse

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Glance", systemImage: "speedometer")
                .font(.caption.weight(.semibold))
                .lineLimit(1)
            MetricRow(label: "CPU", value: pulse.cpuUsage, color: .blue)
            MetricRow(label: "RAM", value: pulse.memoryUsage, color: .green)
            if let gpu = pulse.gpuUsage {
                MetricRow(label: "GPU", value: gpu, color: .purple)
            }
            MetricRow(label: "Disk", value: pulse.diskUsage, color: .orange)
        }
        .padding(4)
    }
}

struct MediumView: View {
    let pulse: GlancePulse

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading) {
                Text("CPU")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(String(format: "%.0f%%", pulse.cpuUsage))
                    .font(.title2.weight(.bold))
                    .contentTransition(.numericText())
                Spacer()
                Text("RAM")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(String(format: "%.0f%%", pulse.memoryUsage))
                    .font(.title2.weight(.bold))
            }
            Divider()
            VStack(alignment: .leading) {
                if let gpu = pulse.gpuUsage {
                    Text("GPU")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.0f%%", gpu))
                        .font(.title2.weight(.bold))
                }
                Spacer()
                Text("Disk")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(String(format: "%.0f%%", pulse.diskUsage))
                    .font(.title2.weight(.bold))
            }
            Spacer()
        }
        .padding(4)
    }
}

struct CircularView: View {
    let pulse: GlancePulse

    var body: some View {
        Gauge(value: pulse.cpuUsage, in: 0...100) {
            Text("CPU")
        } currentValueLabel: {
            Text(String(format: "%.0f", pulse.cpuUsage))
                .font(.headline)
        }
        .gaugeStyle(.accessoryCircular)
    }
}

struct InlineView: View {
    let pulse: GlancePulse

    var body: some View {
        Text("CPU \(String(format: "%.0f%%", pulse.cpuUsage)) · RAM \(String(format: "%.0f%%", pulse.memoryUsage))")
    }
}

struct RectangularView: View {
    let pulse: GlancePulse

    var body: some View {
        VStack(alignment: .leading) {
            Text("Glance")
                .font(.headline)
            Text("CPU \(String(format: "%.0f%%", pulse.cpuUsage))")
            Text("RAM \(String(format: "%.0f%%", pulse.memoryUsage))")
            if let gpu = pulse.gpuUsage {
                Text("GPU \(String(format: "%.0f%%", gpu))")
            }
            Text("Disk \(String(format: "%.0f%%", pulse.diskUsage))")
        }
    }
}

struct UnavailableView: View {
    var body: some View {
        ContentUnavailableView(
            "Waiting for data",
            systemImage: "speedometer",
            description: Text("Launch the Glance menu bar app to start sampling.")
        )
    }
}

struct MetricRow: View {
    let label: String
    let value: Double
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.caption2)
                .frame(width: 32, alignment: .leading)
                .foregroundStyle(.secondary)
            ProgressView(value: value, total: 100)
                .tint(color)
            Text(String(format: "%.0f", value))
                .font(.caption2.monospacedDigit())
                .frame(width: 26, alignment: .trailing)
        }
    }
}
