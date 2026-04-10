//
//  TabBackgroundView.swift
//  Sahara
//
//  Created by 금가경 on 4/10/26.
//

import UIKit

final class TabBackgroundView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .token(.tabBackground)
        layer.cornerRadius = 8
        clipsToBounds = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateInnerShadow()
    }

    private func updateInnerShadow() {
        layer.sublayers?.removeAll(where: { $0.name == "innerShadow" })

        let innerShadow = CALayer()
        innerShadow.name = "innerShadow"
        innerShadow.frame = bounds

        let path = UIBezierPath(roundedRect: bounds.insetBy(dx: -20, dy: -20), cornerRadius: 8)
        let cutout = UIBezierPath(roundedRect: bounds, cornerRadius: 8).reversing()
        path.append(cutout)

        innerShadow.shadowPath = path.cgPath
        innerShadow.masksToBounds = true
        innerShadow.shadowColor = UIColor.black.cgColor
        innerShadow.shadowOffset = CGSize(width: 0, height: 4)
        innerShadow.shadowOpacity = 0.25
        innerShadow.shadowRadius = 4
        innerShadow.cornerRadius = 8

        layer.addSublayer(innerShadow)
    }
}
