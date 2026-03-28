//
//  TabButton.swift
//  Sahara
//
//  Created by 금가경 on 10/8/25.
//

import SnapKit
import UIKit

final class TabButton: UIView {
    private let backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = .token(.tabBackground)
        view.layer.cornerRadius = 8
        view.clipsToBounds = true
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
        imageView.tintColor = .black
        return imageView
    }()

    private let label: UILabel = {
        let label = UILabel()
        label.font = .typography(.tiny)
        label.textColor = .black
        return label
    }()

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
            make.width.height.equalTo(48)
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
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateInnerShadow()
    }

    private func updateInnerShadow() {
        backgroundView.layer.sublayers?.removeAll(where: { $0.name == "innerShadow" })

        let innerShadow = CALayer()
        innerShadow.name = "innerShadow"
        innerShadow.frame = backgroundView.bounds

        let path = UIBezierPath(roundedRect: backgroundView.bounds.insetBy(dx: -20, dy: -20), cornerRadius: 8)
        let cutout = UIBezierPath(roundedRect: backgroundView.bounds, cornerRadius: 8).reversing()
        path.append(cutout)

        innerShadow.shadowPath = path.cgPath
        innerShadow.masksToBounds = true
        innerShadow.shadowColor = UIColor.black.cgColor
        innerShadow.shadowOffset = CGSize(width: 0, height: 4)
        innerShadow.shadowOpacity = 0.25
        innerShadow.shadowRadius = 4
        innerShadow.cornerRadius = 8

        backgroundView.layer.addSublayer(innerShadow)
    }

    @objc private func handleTap() {
        onTap?()
    }

    func setSelected(_ isSelected: Bool) {
        UIView.animate(withDuration: 0.2) {
            self.backgroundView.alpha = isSelected ? 1 : 0
        }
    }
}
