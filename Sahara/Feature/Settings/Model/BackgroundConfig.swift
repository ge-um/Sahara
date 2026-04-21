//
//  BackgroundConfig.swift
//  Sahara
//

import Foundation

enum BackgroundTheme: Codable, Equatable {
    case solidColor(hex: String)
    case gradient(gradientId: String)
    case customGradient(startHex: String, endHex: String)
    case photo(fileName: String)

    var analyticsName: String {
        switch self {
        case .solidColor: return "solid_color"
        case .gradient: return "gradient"
        case .customGradient: return "custom_gradient"
        case .photo: return "photo"
        }
    }

    var analyticsDetail: String {
        switch self {
        case .solidColor(let hex): return hex
        case .gradient(let gradientId): return gradientId
        case .customGradient(let startHex, let endHex): return "\(startHex)-\(endHex)"
        case .photo: return "custom"
        }
    }
}

struct BackgroundConfig: Codable, Equatable {
    var theme: BackgroundTheme
    var isDotPatternEnabled: Bool

    static let `default` = BackgroundConfig(
        theme: .gradient(gradientId: "primary"),
        isDotPatternEnabled: false
    )
}
