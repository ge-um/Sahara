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

    private let userDefaults = UserDefaults.standard
    private enum Keys {
        static let hasSelectedLanguage = "has_selected_language"
    }

    private init() {}

    var hasSelectedLanguage: Bool {
        return userDefaults.bool(forKey: Keys.hasSelectedLanguage)
    }

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

    var isSupportedSystemLanguage: Bool {
        if let preferredLanguage = Locale.preferredLanguages.first {
            let languageCode = preferredLanguage.components(separatedBy: "-").first ?? preferredLanguage
            return ["ko", "en", "ja", "zh"].contains(languageCode)
        }
        return false
    }

    var currentLanguage: Language {
        if let languages = userDefaults.array(forKey: "AppleLanguages") as? [String],
           let firstLanguage = languages.first {
            let languageCode = firstLanguage.components(separatedBy: "-").first ?? firstLanguage

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
                break
            }
        }

        return systemLanguage
    }

    var currentLanguageDescription: String {
        return currentLanguage.localizedDescription
    }

    func setLanguage(_ language: Language) {
        userDefaults.set([language.rawValue], forKey: "AppleLanguages")
        userDefaults.set(true, forKey: Keys.hasSelectedLanguage)
        userDefaults.synchronize()
        Bundle.setLanguage(language)
    }
}
