//
//  SettingsMenuItem.swift
//  Sahara
//
//  Created by 금가경 on 1/11/25.
//

import Foundation

enum SettingsMenuItem: CaseIterable {
    case language
    case cloudSync
    case exportPhotos
    case exportBackup
    case importBackup
    case serviceNews
    case contactDeveloper
    case releaseNotes
    case versionInfo

    var title: String {
        switch self {
        case .language:
            return NSLocalizedString("settings.language", comment: "")
        case .cloudSync:
            return NSLocalizedString("settings.cloud_sync", comment: "")
        case .exportPhotos:
            return NSLocalizedString("settings.export_photos", comment: "")
        case .exportBackup:
            return NSLocalizedString("settings.export_backup", comment: "")
        case .importBackup:
            return NSLocalizedString("settings.import_backup", comment: "")
        case .serviceNews:
            return NSLocalizedString("settings.service_news", comment: "")
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
        case .language:
            return LanguageService.shared.currentLanguageDescription
        case .cloudSync:
            return NSLocalizedString("settings.cloud_sync_desc", comment: "")
        case .serviceNews:
            return NSLocalizedString("settings.service_news_desc", comment: "")
        case .versionInfo:
            return appVersion
        default:
            return nil
        }
    }

    var isSelectable: Bool {
        switch self {
        case .language, .contactDeveloper, .releaseNotes, .exportPhotos, .exportBackup, .importBackup:
            return true
        case .cloudSync, .serviceNews, .versionInfo:
            return false
        }
    }

    var hasToggle: Bool {
        switch self {
        case .cloudSync, .serviceNews:
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
