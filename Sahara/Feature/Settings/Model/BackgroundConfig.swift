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
}

struct BackgroundConfig: Codable, Equatable {
    var theme: BackgroundTheme
    var isDotPatternEnabled: Bool

    static let `default` = BackgroundConfig(
        theme: .gradient(gradientId: "primary"),
        isDotPatternEnabled: true
    )
}
