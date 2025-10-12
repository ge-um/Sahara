//
//  SettingsMenuItem.swift
//  Sahara
//
//  Created by 금가경 on 1/11/25.
//

import Foundation

enum SettingsMenuItem: CaseIterable {
    case contactDeveloper
    case releaseNotes
    case versionInfo

    var title: String {
        switch self {
        case .contactDeveloper:
            return NSLocalizedString("settings.contact_developer", comment: "")
        case .releaseNotes:
            return NSLocalizedString("settings.release_notes", comment: "")
        case .versionInfo:
            return NSLocalizedString("settings.version_info", comment: "")
        }
    }

    var subtitle: String? {
        switch self {
        case .versionInfo:
            return appVersion
        default:
            return nil
        }
    }

    var isSelectable: Bool {
        switch self {
        case .contactDeveloper, .releaseNotes:
            return true
        case .versionInfo:
            return false
        }
    }

    private var appVersion: String {
        guard let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            return "1.0.0"
        }
        return version
    }
}
