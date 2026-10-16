// GlanceApp.swift
// Menu bar host app: samples hardware metrics and publishes them to the
// shared App Group container for the widget extension.

import SwiftUI
import WidgetKit

@main
struct GlanceApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra("Glance", systemImage: "speedometer") {
            MenuBarContentView()
        }
        .menuBarExtraStyle(.window)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var timer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let sampler = PulseSampler()
        sampler.cpuUsage() // prime tick baseline
        let timer = Timer(timeInterval: 5, repeats: true) { _ in
            let pulse = sampler.sample()
            GlancePulseStore.save(pulse, appGroupID: AppConfiguration.appGroupID)
            WidgetCenter.shared.reloadAllTimelines()
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func applicationWillTerminate(_ notification: Notification) {
        timer?.invalidate()
    }
}

enum AppConfiguration {
    static let appGroupID = "group.com.example.glance"
}
