//
//  ColorSystem.swift
//  Sahara
//
//  Created by 금가경 on 10/2/25.
//

import UIKit

enum ColorSystem {
    static let gradientBlue = UIColor(hex: "#6CA9FF")
    static let gradientWhite = UIColor(hex: "#F9FFFF")
    static let gradientPink = UIColor(hex: "#FFBDFF")

    static let buttonYellow = UIColor(hex: "#D9F266")

    enum Gradient {
        case pinkBlue

        var colors: [CGColor] {
            switch self {
            case .pinkBlue:
                return [
                    ColorSystem.gradientPink.cgColor,
                    ColorSystem.gradientWhite.cgColor,
                    ColorSystem.gradientBlue.cgColor
                ]
            }
        }

        var locations: [NSNumber] {
            switch self {
            case .pinkBlue:
                return [0.0, 0.5, 1.0]
            }
        }
    }
}
