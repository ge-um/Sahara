//
//  FontSystem.swift
//  Sahara
//
//  Created by 금가경 on 10/2/25.
//

import UIKit

enum FontSystem {
    static func galmuriMono(size: CGFloat) -> UIFont {
        return UIFont(name: "GalmuriMono11", size: size) ?? .systemFont(ofSize: size)
    }

    static func galmuriBold(size: CGFloat) -> UIFont {
        return UIFont(name: "Galmuri11-Bold", size: size) ?? .systemFont(ofSize: size, weight: .bold)
    }

    static func galmuri14(size: CGFloat) -> UIFont {
        return UIFont(name: "Galmuri14", size: size) ?? .systemFont(ofSize: size)
    }

    enum TextStyle {
        case emptyStateMessage
        case tabBarLabel
        case navigationTitle
        case buttonTitle

        var font: UIFont {
            switch self {
            case .emptyStateMessage:
                return galmuriMono(size: 14)
            case .tabBarLabel:
                return galmuriMono(size: 12)
            case .navigationTitle:
                return galmuriMono(size: 14)
            case .buttonTitle:
                return galmuriMono(size: 14)
            }
        }

        var letterSpacing: CGFloat {
            switch self {
            case .emptyStateMessage, .tabBarLabel, .buttonTitle:
                return -6
            case .navigationTitle:
                return 0
            }
        }

        func attributedString(_ text: String, color: UIColor) -> NSAttributedString {
            return text.attributedString(font: font, letterSpacing: letterSpacing, color: color)
        }
    }
}
