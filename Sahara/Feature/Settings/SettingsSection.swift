//
//  SettingsSection.swift
//  Sahara
//
//  Created by 금가경 on 1/11/25.
//

import Foundation

enum SettingsSectionType {
    case general
    case dataManagement
    case notifications
    case support
    case about

    var title: String {
        switch self {
        case .general:
            return NSLocalizedString("settings.section_general", comment: "")
        case .dataManagement:
            return NSLocalizedString("settings.section_data", comment: "")
        case .notifications:
            return NSLocalizedString("settings.section_notifications", comment: "")
        case .support:
            return NSLocalizedString("settings.section_support", comment: "")
        case .about:
            return NSLocalizedString("settings.section_about", comment: "")
        }
    }
}

struct SettingsSection {
    let type: SettingsSectionType
    let items: [SettingsMenuItem]

    var title: String {
        return type.title
    }
}

