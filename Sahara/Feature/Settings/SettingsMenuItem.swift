//
//  SettingsMenuItem.swift
//  Sahara
//
//  Created by 금가경 on 1/11/25.
//

import Foundation

enum SettingsMenuItem: CaseIterable {
    case weeklyReport
    case contactDeveloper
    case releaseNotes
    case versionInfo

    var title: String {
        switch self {
        case .weeklyReport:
            return NSLocalizedString("settings.weekly_report", comment: "")
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
        case .weeklyReport:
            return NSLocalizedString("settings.weekly_report_desc", comment: "")
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
        case .weeklyReport, .versionInfo:
            return false
        }
    }

    var hasToggle: Bool {
        switch self {
        case .weeklyReport:
            return true
        default:
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
