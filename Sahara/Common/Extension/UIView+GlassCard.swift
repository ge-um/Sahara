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
        layer.borderColor = UIColor.black.withAlphaComponent(0.06).cgColor
        clipsToBounds = true
    }
}
