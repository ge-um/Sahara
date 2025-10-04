//
//  EmptyStateView.swift
//  Sahara
//
//  Created by 금가경 on 10/2/25.
//

import SnapKit
import UIKit

final class EmptyStateView: UIView {
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        return label
    }()

    private let actionButton: UIButton = {
        let button = UIButton()
        button.layer.cornerRadius = 8
        button.clipsToBounds = true
        button.titleLabel?.numberOfLines = 1
        button.titleLabel?.adjustsFontSizeToFitWidth = false
        return button
    }()

    private let buttonGradientLayer = CAGradientLayer()

    var onActionButtonTapped: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        applyGradientBackground()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        buttonGradientLayer.frame = actionButton.bounds
    }

    private func applyGradientBackground() {
        // 배경은 부모 뷰에서 처리
    }

    private func setupUI() {
        backgroundColor = .clear

        addSubview(messageLabel)
        addSubview(actionButton)

        messageLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-64)
            make.horizontalEdges.equalToSuperview().inset(40)
        }

        actionButton.snp.makeConstraints { make in
            make.top.equalTo(messageLabel.snp.bottom).offset(24)
            make.centerX.equalToSuperview()
            make.height.equalTo(50)
            make.width.greaterThanOrEqualTo(150)
            make.width.lessThanOrEqualTo(250)
        }

        // 버튼 그라디언트 설정
        buttonGradientLayer.colors = ColorSystem.Gradient.buttonPink.colors
        buttonGradientLayer.locations = ColorSystem.Gradient.buttonPink.locations
        buttonGradientLayer.startPoint = ColorSystem.Gradient.buttonPink.startPoint
        buttonGradientLayer.endPoint = ColorSystem.Gradient.buttonPink.endPoint
        actionButton.layer.insertSublayer(buttonGradientLayer, at: 0)

        actionButton.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
    }

    @objc private func actionButtonTapped() {
        onActionButtonTapped?()
    }

    func configure(message: String, buttonTitle: String) {
        messageLabel.attributedText = FontSystem.TextStyle.emptyStateMessage.attributedString(message, color: .black)
        actionButton.setAttributedTitle(FontSystem.TextStyle.buttonTitle.attributedString(buttonTitle, color: .white), for: .normal)
        actionButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        actionButton.sizeToFit()
    }
}
