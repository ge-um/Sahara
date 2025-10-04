//
//  ToastView.swift
//  Sahara
//
//  Created by 금가경 on 10/4/25.
//

import SnapKit
import UIKit

final class ToastView: UIView {
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.85)
        view.layer.cornerRadius = 12
        return view
    }()

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = FontSystem.galmuriMono(size: 14)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    init(message: String) {
        super.init(frame: .zero)
        messageLabel.text = message
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(containerView)
        containerView.addSubview(messageLabel)

        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        messageLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 16, left: 20, bottom: 16, right: 20))
        }
    }

    func show(in view: UIView, duration: TimeInterval = 2.0) {
        view.addSubview(self)

        snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().offset(40)
            make.trailing.lessThanOrEqualToSuperview().offset(-40)
        }

        alpha = 0
        transform = CGAffineTransform(scaleX: 0.8, y: 0.8)

        view.layoutIfNeeded()

        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5) {
            self.alpha = 1
            self.transform = .identity
        } completion: { _ in
            UIView.animate(withDuration: 0.2, delay: duration, options: .curveEaseIn) {
                self.alpha = 0
                self.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            } completion: { _ in
                self.removeFromSuperview()
            }
        }
    }
}
