//
//  BackupMetadata.swift
//  Sahara
//
//  Created by 금가경 on 3/8/26.
//

import Foundation
import UIKit

struct BackupMetadata: Codable {
    let appVersion: String
    let schemaVersion: UInt64
    let cardCount: Int
    let createdAt: Date
    let deviceModel: String

    static func create(cardCount: Int) -> BackupMetadata {
        BackupMetadata(
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown",
            schemaVersion: RealmManager.currentSchemaVersion,
            cardCount: cardCount,
            createdAt: Date(),
            deviceModel: DeviceInfo.modelIdentifier
        )
    }
}

enum DeviceInfo {
    static var modelIdentifier: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        return withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(validatingUTF8: $0) ?? UIDevice.current.model
            }
        }
    }
}
