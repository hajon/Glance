// PulseMathTests.swift
// Unit tests for the pure derivation logic (compile on any platform).

import XCTest
@testable import GlanceCore

final class PulseMathTests: XCTestCase {
    func testUsageDelta() {
        let previous = CPUUsage(user: 100, system: 50, idle: 50)
        let current = CPUUsage(user: 150, system: 60, idle: 90)
        let result = PulseMath.usage(from: previous, to: current)
        XCTAssertEqual(result.user, 50.0 / 100.0 * 100, accuracy: 0.001)
        XCTAssertEqual(result.system, 10.0 / 100.0 * 100, accuracy: 0.001)
        XCTAssertEqual(result.idle, 40.0 / 100.0 * 100, accuracy: 0.001)
        XCTAssertEqual(result.total, 100.0 - result.idle, accuracy: 0.001)
    }

    func testIdenticalTicksReportIdle() {
        let ticks = CPUUsage(user: 100, system: 50, idle: 50)
        let result = PulseMath.usage(from: ticks, to: ticks)
        XCTAssertEqual(result.idle, 100, accuracy: 0.001)
        XCTAssertEqual(result.total, 0, accuracy: 0.001)
    }

    func testClampsNegativeDeltas() {
        let previous = CPUUsage(user: 100, system: 50, idle: 50)
        let current = CPUUsage(user: 80, system: 60, idle: 60)
        let result = PulseMath.usage(from: previous, to: current)
        XCTAssertEqual(result.user, 0, accuracy: 0.001)
        XCTAssertEqual(result.system, 10.0 / 20.0 * 100, accuracy: 0.001)
    }

    func testStaleness() {
        let fresh = GlancePulse(
            timestamp: Date(), cpuUsage: 10, memoryUsage: 50, memoryTotal: 100, diskUsage: 40
        )
        let stale = GlancePulse(
            timestamp: Date(timeIntervalSinceNow: -1000),
            cpuUsage: 10, memoryUsage: 50, memoryTotal: 100, diskUsage: 40
        )
        XCTAssertFalse(fresh.isStale)
        XCTAssertTrue(stale.isStale)
    }

    func testCodableRoundTrip() throws {
        let pulse = GlancePulse(
            timestamp: Date(timeIntervalSince1970: 1_700_000_000),
            cpuUsage: 42.5, memoryUsage: 60, memoryTotal: 17_179_869_184,
            gpuUsage: 12.5, diskUsage: 70
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let data = try encoder.encode(pulse)
        let decoded = try decoder.decode(GlancePulse.self, from: data)
        XCTAssertEqual(pulse, decoded)
    }
}
