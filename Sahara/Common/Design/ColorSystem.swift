//
//  ColorSystem.swift
//  Sahara
//
//  Created by 금가경 on 10/2/25.
//

import UIKit

enum ColorSystem {
    static let skyBlue = UIColor(hex: "#6CA9FF")
    static let paleWhite = UIColor(hex: "#F9FFFF")
    static let lightPink = UIColor(hex: "#FFBDFF")

    static let limeGreen = UIColor(hex: "#D9F266")
    static let purpleGray20 = UIColor(hex: "#2C2A37").withAlphaComponent(0.2)
    static let white30 = UIColor.white.withAlphaComponent(0.3)
    static let lavender20 = UIColor(hex: "#D2D1E4").withAlphaComponent(0.2)
    static let darkGray = UIColor(hex: "#4A4A4A")
    static let charcoal = UIColor(hex: "#1A1A1A")
    static let mediumGray = UIColor(hex: "#494949")
    static let lightGray = UIColor(hex: "#A2A2A2")
    static let darkestGray = UIColor(hex: "#555555")

    static let white = UIColor.white
    static let black = UIColor.black
    static let clear = UIColor.clear
    static let systemRed = UIColor.systemRed
    static let systemBlue = UIColor.systemBlue
    static let systemGray6 = UIColor.systemGray6
    static let label = UIColor.label
    static let secondaryLabel = UIColor.secondaryLabel
    static let systemBackground = UIColor.systemBackground

    enum Gradient {
        case pinkToBlue
        case paleBlueToGray
        case hotPink
        case royalBlue
        case whiteToGray
        case mintToOrange
        case lemonToLime
        case yellowGreen

        var colors: [CGColor] {
            switch self {
            case .pinkToBlue:
                return [
                    ColorSystem.lightPink.cgColor,
                    ColorSystem.paleWhite.cgColor,
                    ColorSystem.skyBlue.cgColor
                ]
            case .paleBlueToGray:
                return [
                    UIColor(hex: "E8EAFF").cgColor,
                    UIColor(hex: "BDBCBD").cgColor
                ]
            case .hotPink:
                return [
                    UIColor(hex: "FF009F").cgColor,
                    UIColor(hex: "DB0E8C").cgColor
                ]
            case .royalBlue:
                return [
                    UIColor(hex: "4F7BFE").cgColor,
                    UIColor(hex: "0213CC").cgColor
                ]
            case .whiteToGray:
                return [
                    UIColor.white.cgColor,
                    UIColor(hex: "A6A3B4").cgColor
                ]
            case .mintToOrange:
                return [
                    UIColor(hex: "A6FDAB").cgColor,
                    UIColor(hex: "EFFFE4").cgColor,
                    UIColor(hex: "963F28").cgColor
                ]
            case .lemonToLime:
                return [
                    UIColor(hex: "FFFFC5").cgColor,
                    UIColor(hex: "9BDA2A").cgColor
                ]
            case .yellowGreen:
                return [
                    UIColor(hex: "FFFFC5").cgColor,
                    UIColor(hex: "9BDA2A").cgColor
                ]
            }
        }

        var locations: [NSNumber] {
            switch self {
            case .pinkToBlue, .mintToOrange:
                return [0.0, 0.5, 1.0]
            case .paleBlueToGray:
                return [0.22, 1.0]
            case .hotPink, .royalBlue, .whiteToGray, .lemonToLime, .yellowGreen:
                return [0.0, 1.0]
            }
        }

        var startPoint: CGPoint {
            switch self {
            case .pinkToBlue, .mintToOrange, .lemonToLime, .yellowGreen:
                return CGPoint(x: 0.5, y: 0.0)
            case .paleBlueToGray, .hotPink, .royalBlue, .whiteToGray:
                return CGPoint(x: 0.5, y: 0)
            }
        }

        var endPoint: CGPoint {
            switch self {
            case .pinkToBlue, .mintToOrange, .lemonToLime, .yellowGreen:
                return CGPoint(x: 0.5, y: 1.0)
            case .paleBlueToGray, .hotPink, .royalBlue, .whiteToGray:
                return CGPoint(x: 0.5, y: 1)
            }
        }
    }
}
