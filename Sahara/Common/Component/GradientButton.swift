//
//  GradientButton.swift
//  Sahara
//
//  Created by 금가경 on 10/2/25.
//

import UIKit

final class GradientButton: UIButton {
    private var currentGradient: DesignToken.Gradient?

    init(title: String) {
        super.init(frame: .zero)
        configure(title: title)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var titleText: String = ""

    private func configure(title: String) {
        titleText = title
        var config = UIButton.Configuration.plain()

        let attributedTitle = AttributedString(
            title,
            attributes: AttributeContainer([
                .font: UIFont.typography(.caption),
                .kern: -6.0 / 10,
                .foregroundColor: UIColor.white
            ])
        )
        config.attributedTitle = attributedTitle
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
        config.background.cornerRadius = 0

        configuration = config
        clipsToBounds = true

        layer.masksToBounds = true
    }

    func setGradient(_ gradient: DesignToken.Gradient, isSelected: Bool = true, textColor: UIColor? = nil) {
        currentGradient = gradient

        var config = configuration
        let color: UIColor = textColor ?? (isSelected ? .token(.textOnAccent) : .token(.textSecondary))
        let attributedTitle = AttributedString(
            titleText,
            attributes: AttributeContainer([
                .font: UIFont.typography(.caption),
                .kern: -6.0 / 10,
                .foregroundColor: color
            ])
        )
        config?.attributedTitle = attributedTitle
        configuration = config

        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2

        if let gradient = currentGradient {
            applyGradient(gradient, removeExisting: true)
        }
    }
}
