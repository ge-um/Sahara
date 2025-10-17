//
//  LanguageManager.swift
//  Sahara
//
//  Created by 금가경 on 10/17/25.
//

import Foundation

enum Language: String, CaseIterable {
    case korean = "ko"
    case english = "en"
    case japanese = "ja"
    case chinese = "zh-Hans"

    var localizedDescription: String {
        switch self {
        case .korean:
            return "한국어"
        case .english:
            return "English"
        case .japanese:
            return "日本語"
        case .chinese:
            return "简体中文"
        }
    }
}

final class LanguageManager {
    static let shared = LanguageManager()

    private init() {}

    var systemLanguage: Language {
        if let preferredLanguage = Locale.preferredLanguages.first {
            let languageCode = preferredLanguage.components(separatedBy: "-").first ?? preferredLanguage

            switch languageCode {
            case "ko":
                return .korean
            case "en":
                return .english
            case "ja":
                return .japanese
            case "zh":
                return .chinese
            default:
                return .english
            }
        }

        return .english
    }

    var currentLanguage: Language {
        return systemLanguage
    }

    var currentLanguageDescription: String {
        return currentLanguage.localizedDescription
    }
}
