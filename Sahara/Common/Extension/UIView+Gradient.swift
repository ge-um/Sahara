//
//  UIView+Gradient.swift
//  Sahara
//
//  Created by 금가경 on 10/2/25.
//

import UIKit

private final class GradientBackgroundView: UIView {
    override class var layerClass: AnyClass { CAGradientLayer.self }

    func configure(_ gradient: DesignToken.Gradient) {
        let gl = layer as! CAGradientLayer
        gl.colors = gradient.colors
        gl.locations = gradient.locations
        gl.startPoint = gradient.startPoint
        gl.endPoint = gradient.endPoint
    }
}

private final class DotPatternBackgroundView: UIView {
    func configure(dotSize: CGFloat, spacing: CGFloat, color: UIColor) {
        let tileSize = CGSize(width: spacing, height: spacing)
        let renderer = UIGraphicsImageRenderer(size: tileSize)
        let patternImage = renderer.image { ctx in
            ctx.cgContext.setFillColor(color.cgColor)
            ctx.cgContext.fillEllipse(in: CGRect(x: 0, y: 0, width: dotSize, height: dotSize))
        }
        backgroundColor = UIColor(patternImage: patternImage)
    }
}

extension UIView {
    func applyGradient(_ gradient: DesignToken.Gradient, removeExisting: Bool = false) {
        if let existing = subviews.first(where: { $0 is GradientBackgroundView }) as? GradientBackgroundView {
            existing.configure(gradient)
            return
        }

        let bgView = GradientBackgroundView()
        bgView.configure(gradient)
        bgView.isUserInteractionEnabled = false
        insertSubview(bgView, at: 0)
        bgView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    func applyDotPattern(dotSize: CGFloat, spacing: CGFloat, color: UIColor) {
        if subviews.contains(where: { $0 is DotPatternBackgroundView }) { return }

        let bgView = DotPatternBackgroundView()
        bgView.configure(dotSize: dotSize, spacing: spacing, color: color)
        bgView.isUserInteractionEnabled = false
        insertSubview(bgView, at: 1)
        bgView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    func applyGradientWithDots(_ gradient: DesignToken.Gradient, dotSize: CGFloat, spacing: CGFloat, dotColor: UIColor) {
        applyGradient(gradient)
        applyDotPattern(dotSize: dotSize, spacing: spacing, color: dotColor)
    }
}
