//
//  MemoryTracker.swift
//  Sahara
//
//  Created by 금가경 on 3/3/26.
//

import Foundation
import OSLog

final class MemoryTracker {

    struct Snapshot {
        let label: String
        let memoryMB: Double
        let timestamp: CFAbsoluteTime
    }

    private static var snapshots: [Snapshot] = []

    static func measure(_ label: String) {
        let memory = currentMemoryMB()
        let snapshot = Snapshot(label: label, memoryMB: memory, timestamp: CFAbsoluteTimeGetCurrent())
        snapshots.append(snapshot)
        Logger.performance.info("[\(label)] Memory: \(String(format: "%.1f", memory)) MB")
    }

    static func compare(_ label1: String, _ label2: String) {
        guard let s1 = snapshots.last(where: { $0.label == label1 }),
              let s2 = snapshots.last(where: { $0.label == label2 }) else {
            Logger.performance.warning("Cannot compare: missing snapshot")
            return
        }

        let diff = s2.memoryMB - s1.memoryMB
        let elapsed = s2.timestamp - s1.timestamp
        Logger.performance.notice(
            "[\(label1) → \(label2)] Δ \(String(format: "%+.1f", diff)) MB, \(String(format: "%.0f", elapsed * 1000)) ms"
        )
    }

    static func reset() {
        snapshots.removeAll()
    }

    private static func currentMemoryMB() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return 0 }
        return Double(info.resident_size) / (1024 * 1024)
    }
}
