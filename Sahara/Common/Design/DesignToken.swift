//
//  DesignToken.swift
//  Sahara
//
//  Created by 금가경 on 3/4/26.
//

import UIKit

enum DesignToken {

    // MARK: - Color Tokens

    enum Color: String {

        // Text
        case textPrimary
        case textSecondary
        case textTertiary
        case textOnAccent

        // Background
        case backgroundPrimary
        case backgroundCard
        case backgroundOverlay
        case backgroundGlass

        // Accent
        case accent

        // Functional
        case destructive
        case info
        case border

        // Component-specific
        case tabBackground
        case iconTint
        case navigationText

        var uiColor: UIColor {
            guard let color = UIColor(named: rawValue) else {
                assertionFailure("Missing color asset: \(rawValue)")
                return .magenta
            }
            return color
        }

        var cgColor: CGColor {
            uiColor.cgColor
        }
    }

    // MARK: - Typography Tokens

    enum Typography {
        case title
        case headline
        case body
        case caption
        case small

        var font: UIFont {
            switch self {
            case .title:    return FontSystem.galmuri14(size: 16)
            case .headline: return FontSystem.galmuriBold(size: 15)
            case .body:     return FontSystem.galmuriMono(size: 14)
            case .caption:  return FontSystem.galmuriMono(size: 12)
            case .small:    return FontSystem.galmuriMono(size: 10)
            }
        }

        var letterSpacing: CGFloat {
            switch self {
            case .title, .headline: return 0
            case .body, .caption, .small: return -0.6
            }
        }
    }

    // MARK: - Spacing Tokens

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 40
    }

    // MARK: - Corner Radius Tokens

    enum CornerRadius {
        static let card: CGFloat = 12
        static let button: CGFloat = 8
    }

}
