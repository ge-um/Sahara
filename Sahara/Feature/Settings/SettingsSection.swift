//
//  SettingsSection.swift
//  Sahara
//
//  Created by 금가경 on 1/11/25.
//

import Foundation
import RxDataSources

enum SettingsSectionType {
    case support
    case about

    var title: String {
        switch self {
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

extension SettingsSection: SectionModelType {
    typealias Item = SettingsMenuItem

    init(original: SettingsSection, items: [SettingsMenuItem]) {
        self = original
        self = SettingsSection(type: original.type, items: items)
    }
}
