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

        // Component-specific
        case tabBackground

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
        case display
        case emphasis
        case title
        case body
        case label
        case caption
        case tiny
        case small

        var font: UIFont {
            switch self {
            case .display:  return FontSystem.galmuriMono(size: 20)
            case .emphasis: return FontSystem.galmuriMono(size: 18)
            case .title:    return FontSystem.galmuriMono(size: 16)
            case .body:     return FontSystem.galmuriMono(size: 14)
            case .label:    return FontSystem.galmuriMono(size: 13)
            case .caption:  return FontSystem.galmuriMono(size: 12)
            case .tiny:     return FontSystem.galmuriMono(size: 11)
            case .small:    return FontSystem.galmuriMono(size: 10)
            }
        }

        var numericFont: UIFont {
            switch self {
            case .display:  return FontSystem.galmuri11(size: 20)
            case .emphasis: return FontSystem.galmuri11(size: 18)
            case .title:    return FontSystem.galmuri11(size: 16)
            case .body:     return FontSystem.galmuri11(size: 14)
            case .label:    return FontSystem.galmuri11(size: 13)
            case .caption:  return FontSystem.galmuri11(size: 12)
            case .tiny:     return FontSystem.galmuri11(size: 11)
            case .small:    return FontSystem.galmuri11(size: 10)
            }
        }

        var letterSpacing: CGFloat {
            switch self {
            case .display, .emphasis, .title: return 0
            case .body, .label, .caption, .tiny, .small: return -0.6
            }
        }

        func attributedString(_ text: String, color: UIColor) -> NSAttributedString {
            text.attributedString(font: font, letterSpacing: letterSpacing, color: color)
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

    // MARK: - Overlay Tokens

    enum Overlay {
        static let border = UIColor.black.withAlphaComponent(0.06)
        static let subtleBorder = UIColor.black.withAlphaComponent(0.15)
        static let dimOverlay = UIColor.black.withAlphaComponent(0.3)
        static let heavyOverlay = UIColor.black.withAlphaComponent(0.5)
        static let toastBackground = UIColor.black.withAlphaComponent(0.85)
        static let whiteButton = UIColor.white.withAlphaComponent(0.8)
    }

}
