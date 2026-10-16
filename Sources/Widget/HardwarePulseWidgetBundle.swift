// HardwarePulseWidgetBundle.swift
// WidgetKit extension: desktop, StandBy, and lock-screen widgets showing
// CPU / memory / GPU / disk utilization.

import WidgetKit
import SwiftUI

@main
struct HardwarePulseWidgetBundle: WidgetBundle {
    var body: some Widget {
        HardwarePulseWidget()
    }
}

struct PulseEntry: TimelineEntry {
    let date: Date
    let pulse: HardwarePulse?
}

struct PulseProvider: TimelineProvider {
    func placeholderEntry() -> PulseEntry {
        PulseEntry(
            date: Date(),
            pulse: HardwarePulse(
                cpuUsage: 23, memoryUsage: 54, memoryTotal: 17179869184, diskUsage: 68
            )
        )
    }

    func placeholder(in context: Context) -> PulseEntry {
        placeholderEntry()
    }

    func getSnapshot(in context: Context, completion: @escaping (PulseEntry) -> Void) {
        if let pulse = HardwarePulseStore.load(appGroupID: WidgetConfiguration.appGroupID) {
            completion(PulseEntry(date: Date(), pulse: pulse))
        } else {
            completion(placeholderEntry())
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PulseEntry>) -> Void) {
        guard let pulse = HardwarePulseStore.load(appGroupID: WidgetConfiguration.appGroupID) else {
            completion(Timeline(entries: [placeholderEntry()], policy: .atEnd))
            return
        }
        let entry = PulseEntry(date: Date(), pulse: pulse)
        let refresh = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(refresh)))
    }
}

enum WidgetConfiguration {
    static let appGroupID = "group.com.example.hardwarepulse"
}

struct HardwarePulseWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: "HardwarePulseWidget",
            provider: PulseProvider()
        ) { entry in
            HardwarePulseWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Hardware Pulse")
        .description("Live CPU, memory, GPU, and disk utilization.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryCircular,
            .accessoryInline,
            .accessoryRectangular,
        ])
    }
}
