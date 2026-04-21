//
//  TabButton.swift
//  Sahara
//
//  Created by 금가경 on 10/8/25.
//

import SnapKit
import UIKit

final class TabButton: UIView {
    private let backgroundView: TabBackgroundView = {
        let view = TabBackgroundView()
        view.alpha = 0
        return view
    }()

    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 4
        return stack
    }()

    private let iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .token(.textPrimary)
        return imageView
    }()

    private let label: UILabel = {
        let label = UILabel()
        label.font = .typography(.caption)
        label.textColor = .token(.textPrimary)
        return label
    }()

    private var backgroundWidthConstraint: Constraint?

    var onTap: (() -> Void)?

    init(icon: UIImage?, title: String) {
        super.init(frame: .zero)
        iconView.image = icon
        label.text = title
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(backgroundView)
        addSubview(stackView)

        stackView.addArrangedSubview(iconView)
        stackView.addArrangedSubview(label)

        backgroundView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.height.equalTo(48)
            backgroundWidthConstraint = make.width.equalTo(48).constraint
        }

        stackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        iconView.snp.makeConstraints { make in
            make.width.height.equalTo(24)
        }

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tapGesture)
        isUserInteractionEnabled = true
        isAccessibilityElement = true
        accessibilityTraits = .button
    }

    @objc private func handleTap() {
        onTap?()
    }

    func setBackgroundWidth(_ width: CGFloat) {
        backgroundWidthConstraint?.update(offset: width)
    }

    func setSelected(_ isSelected: Bool) {
        UIView.animate(withDuration: 0.2) {
            self.backgroundView.alpha = isSelected ? 1 : 0
            self.stackView.alpha = isSelected ? 1.0 : 0.5
        }
    }
}
