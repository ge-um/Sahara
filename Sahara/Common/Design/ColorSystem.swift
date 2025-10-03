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
    static let cardBackground = UIColor(hex: "#2C2A37").withAlphaComponent(0.2)
    static let calendarBackground = UIColor.white.withAlphaComponent(0.3)
    static let labelPrimary = UIColor(hex: "#4A4A4A")
    static let labelSecondary = UIColor(hex: "#1A1A1A")
    static let labelTitle = UIColor.black
    static let labelInactive = UIColor(hex: "#494949")
    static let labelNotCurrentMonth = UIColor(hex: "#A2A2A2")

    enum Gradient {
        case pinkBlue
        case barBack
        case buttonPink
        case blueGradient
        case grayGradient
        case cardInfoBackground
        case searchLocationButton
        case saveShareButton

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
            case .cardInfoBackground:
                return [
                    UIColor(hex: "A6FDAB").cgColor,
                    UIColor(hex: "EFFFE4").cgColor,
                    UIColor(hex: "963F28").cgColor
                ]
            case .searchLocationButton:
                return [
                    UIColor(hex: "FFFFC5").cgColor,
                    UIColor(hex: "9BDA2A").cgColor
                ]
            case .saveShareButton:
                return [
                    UIColor(hex: "FFFFC5").cgColor,
                    UIColor(hex: "9BDA2A").cgColor
                ]
            }
        }

        var locations: [NSNumber] {
            switch self {
            case .pinkBlue, .cardInfoBackground:
                return [0.0, 0.5, 1.0]
            case .barBack:
                return [0.22, 1.0]
            case .buttonPink, .blueGradient, .grayGradient, .searchLocationButton, .saveShareButton:
                return [0.0, 1.0]
            }
        }

        var startPoint: CGPoint {
            switch self {
            case .pinkBlue, .cardInfoBackground, .searchLocationButton, .saveShareButton:
                return CGPoint(x: 0.5, y: 0.0)
            case .barBack, .buttonPink, .blueGradient, .grayGradient:
                return CGPoint(x: 0.5, y: 0)
            }
        }

        var endPoint: CGPoint {
            switch self {
            case .pinkBlue, .cardInfoBackground, .searchLocationButton, .saveShareButton:
                return CGPoint(x: 0.5, y: 1.0)
            case .barBack, .buttonPink, .blueGradient, .grayGradient:
                return CGPoint(x: 0.5, y: 1)
            }
        }
    }
}
