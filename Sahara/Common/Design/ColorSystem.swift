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
        case barBack
        case buttonPink
        case blueGradient
        case grayGradient
        case whiteGray

        var colors: [CGColor] {
            switch self {
            case .pinkBlue:
                return [
                    ColorSystem.gradientPink.cgColor,
                    ColorSystem.gradientWhite.cgColor,
                    ColorSystem.gradientBlue.cgColor
                ]
            case .barBack:
                return [
                    UIColor(hex: "E8EAFF").cgColor,
                    UIColor(hex: "BDBCBD").cgColor
                ]
            case .buttonPink:
                return [
                    UIColor(hex: "FF009F").cgColor,
                    UIColor(hex: "DB0E8C").cgColor
                ]
            case .blueGradient:
                return [
                    UIColor(hex: "4F7BFE").cgColor,
                    UIColor(hex: "0213CC").cgColor
                ]
            case .grayGradient:
                return [
                    UIColor.white.cgColor,
                    UIColor(hex: "A6A3B4").cgColor
                ]
            case .whiteGray:
                return [
                    UIColor.white.cgColor,
                    UIColor(white: 0.9, alpha: 1.0).cgColor
                ]
            }
        }

        var locations: [NSNumber] {
            switch self {
            case .pinkBlue:
                return [0.0, 0.5, 1.0]
            case .barBack:
                return [0.22, 1.0]
            case .buttonPink, .blueGradient, .grayGradient, .whiteGray:
                return [0.0, 1.0]
            }
        }

        var startPoint: CGPoint {
            switch self {
            case .pinkBlue:
                return CGPoint(x: 0.5, y: 0.0)
            case .barBack, .buttonPink, .blueGradient, .grayGradient, .whiteGray:
                return CGPoint(x: 0.5, y: 0)
            }
        }

        var endPoint: CGPoint {
            switch self {
            case .pinkBlue:
                return CGPoint(x: 0.5, y: 1.0)
            case .barBack, .buttonPink, .blueGradient, .grayGradient, .whiteGray:
                return CGPoint(x: 0.5, y: 1)
            }
        }
    }
}
