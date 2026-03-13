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
            deviceModel: DeviceInfo.displayName
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

    static var displayName: String {
        #if targetEnvironment(macCatalyst)
        var size: size_t = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        var model = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &model, &size, nil, 0)
        return String(cString: model)
        #else
        let code = modelIdentifier

        let deviceModelMap: [String: String] = [
            "iPhone14,2": "iPhone 13 Pro",
            "iPhone14,3": "iPhone 13 Pro Max",
            "iPhone14,4": "iPhone 13 mini",
            "iPhone14,5": "iPhone 13",
            "iPhone14,6": "iPhone SE (3rd generation)",
            "iPhone14,7": "iPhone 14",
            "iPhone14,8": "iPhone 14 Plus",
            "iPhone15,2": "iPhone 14 Pro",
            "iPhone15,3": "iPhone 14 Pro Max",
            "iPhone15,4": "iPhone 15",
            "iPhone15,5": "iPhone 15 Plus",
            "iPhone16,1": "iPhone 15 Pro",
            "iPhone16,2": "iPhone 15 Pro Max",
            "iPhone17,1": "iPhone 16 Pro",
            "iPhone17,2": "iPhone 16 Pro Max",
            "iPhone17,3": "iPhone 16",
            "iPhone17,4": "iPhone 16 Plus",
            "arm64": "Simulator",
            "x86_64": "Simulator"
        ]

        return deviceModelMap[code] ?? code
        #endif
    }
}
