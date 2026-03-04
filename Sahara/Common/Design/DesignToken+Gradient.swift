//
//  DesignToken+Gradient.swift
//  Sahara
//
//  Created by 금가경 on 3/4/26.
//

import UIKit

extension DesignToken {

    enum Gradient {
        case primary
        case tabBar
        case ctaPink
        case ctaBlue
        case subtle
        case warm
        case fresh
        case highlight

        var colors: [CGColor] {
            switch self {
            case .primary:
                return [
                    UIColor(hex: "#FFBDFF").cgColor,
                    UIColor(hex: "#F9FFFF").cgColor,
                    UIColor(hex: "#6CA9FF").cgColor
                ]
            case .tabBar:
                return [
                    UIColor(hex: "#E8EAFF").cgColor,
                    UIColor(hex: "#BDBCBD").cgColor
                ]
            case .ctaPink:
                return [
                    UIColor(hex: "#FF009F").cgColor,
                    UIColor(hex: "#DB0E8C").cgColor
                ]
            case .ctaBlue:
                return [
                    UIColor(hex: "#4F7BFE").cgColor,
                    UIColor(hex: "#0213CC").cgColor
                ]
            case .subtle:
                return [
                    UIColor.white.cgColor,
                    UIColor(hex: "#A6A3B4").cgColor
                ]
            case .warm:
                return [
                    UIColor(hex: "#A6FDAB").cgColor,
                    UIColor(hex: "#EFFFE4").cgColor,
                    UIColor(hex: "#963F28").cgColor
                ]
            case .fresh:
                return [
                    UIColor(hex: "#FFFFC5").cgColor,
                    UIColor(hex: "#9BDA2A").cgColor
                ]
            case .highlight:
                return [
                    UIColor(hex: "#FFFFC5").cgColor,
                    UIColor(hex: "#9BDA2A").cgColor
                ]
            }
        }

        var locations: [NSNumber] {
            switch self {
            case .primary, .warm:
                return [0.0, 0.5, 1.0]
            case .tabBar:
                return [0.22, 1.0]
            case .ctaPink, .ctaBlue, .subtle, .fresh, .highlight:
                return [0.0, 1.0]
            }
        }

        var startPoint: CGPoint {
            CGPoint(x: 0.5, y: 0.0)
        }

        var endPoint: CGPoint {
            CGPoint(x: 0.5, y: 1.0)
        }
    }
}
