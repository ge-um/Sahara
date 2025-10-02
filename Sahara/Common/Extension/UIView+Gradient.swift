//
//  UIView+Gradient.swift
//  Sahara
//
//  Created by 금가경 on 10/2/25.
//

import UIKit

extension UIView {
    func applyGradient(_ gradient: ColorSystem.Gradient) {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = bounds
        gradientLayer.colors = gradient.colors
        gradientLayer.locations = gradient.locations
        gradientLayer.startPoint = gradient.startPoint
        gradientLayer.endPoint = gradient.endPoint
        layer.insertSublayer(gradientLayer, at: 0)
    }

    func applyDotPattern(dotSize: CGFloat, spacing: CGFloat, color: UIColor) {
        let dotLayer = CAShapeLayer()
        dotLayer.frame = bounds

        let dotPath = UIBezierPath()

        var y: CGFloat = 0
        while y < bounds.height {
            var x: CGFloat = 0
            while x < bounds.width {
                let dotRect = CGRect(x: x, y: y, width: dotSize, height: dotSize)
                dotPath.append(UIBezierPath(ovalIn: dotRect))
                x += spacing
            }
            y += spacing
        }

        dotLayer.path = dotPath.cgPath
        dotLayer.fillColor = color.cgColor
        layer.insertSublayer(dotLayer, at: 1)
    }

    func applyGradientWithDots(_ gradient: ColorSystem.Gradient, dotSize: CGFloat, spacing: CGFloat, dotColor: UIColor) {
        applyGradient(gradient)
        applyDotPattern(dotSize: dotSize, spacing: spacing, color: dotColor)
    }
}
