//
//  UIView+GlassCard.swift
//  Sahara
//

import UIKit

extension UIView {
    func applyGlassCardStyle(cornerRadius: CGFloat = DesignToken.CornerRadius.card) {
        backgroundColor = .token(.backgroundGlass)
        layer.cornerRadius = cornerRadius
        layer.borderWidth = 0.5
        layer.borderColor = DesignToken.Overlay.border.cgColor
        clipsToBounds = true
    }
}
