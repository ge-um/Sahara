//
//  UIView+Gradient.swift
//  Sahara
//
//  Created by 금가경 on 10/2/25.
//

import UIKit

extension UIView {
    func applyGradient(_ gradient: DesignToken.Gradient, removeExisting: Bool = false) {
        if removeExisting {
            layer.sublayers?.filter { $0 is CAGradientLayer }.forEach { $0.removeFromSuperlayer() }
        }

        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = bounds
        #if targetEnvironment(macCatalyst)
        gradientLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        #endif
        gradientLayer.colors = gradient.colors
        gradientLayer.locations = gradient.locations
        gradientLayer.startPoint = gradient.startPoint
        gradientLayer.endPoint = gradient.endPoint
        layer.insertSublayer(gradientLayer, at: 0)
    }

    func applyDotPattern(dotSize: CGFloat, spacing: CGFloat, color: UIColor) {
        let tileSize = CGSize(width: spacing, height: spacing)
        let renderer = UIGraphicsImageRenderer(size: tileSize)
        let patternImage = renderer.image { ctx in
            ctx.cgContext.setFillColor(color.cgColor)
            ctx.cgContext.fillEllipse(in: CGRect(x: 0, y: 0, width: dotSize, height: dotSize))
        }
        let patternLayer = CALayer()
        patternLayer.backgroundColor = UIColor(patternImage: patternImage).cgColor
        patternLayer.frame = bounds
        #if targetEnvironment(macCatalyst)
        patternLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        #endif
        layer.insertSublayer(patternLayer, at: 1)
    }

    func applyGradientWithDots(_ gradient: DesignToken.Gradient, dotSize: CGFloat, spacing: CGFloat, dotColor: UIColor) {
        applyGradient(gradient)
        applyDotPattern(dotSize: dotSize, spacing: spacing, color: dotColor)
    }
}
