//
//  CustomNavigationBar.swift
//  Sahara
//
//  Created by 금가경 on 10/2/25.
//

import SnapKit
import UIKit

final class CustomNavigationBar: UIView {
    private let containerView: UIView = {
        let view = UIView()
        return view
    }()

    private let leftButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "chevron.left")
        config.baseForegroundColor = .black
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 8)
        let button = UIButton(configuration: config)
        return button
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.textAlignment = .center
        return label
    }()

    private let rightStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.alignment = .center
        return stackView
    }()

    let contentLeadingGuide = UILayoutGuide()

    var onLeftButtonTapped: (() -> Void)?
    private var contentLeadingConstraint: Constraint?
    private var titleCenterXConstraint: Constraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        NotificationCenter.default.addObserver(
            self, selector: #selector(floatingWindowStateChanged),
            name: .floatingWindowStateDidChange, object: nil
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        enableSwipeBackGesture()
        updateLeadingForWindowControls(isFloating: isInFloatingWindow)
    }

    @objc private func floatingWindowStateChanged() {
        updateLeadingForWindowControls(isFloating: isInFloatingWindow)
    }

    private func updateLeadingForWindowControls(isFloating: Bool) {
        // 76: macOS 윈도우 컨트롤(신호등) 너비 + 여백
        let leading: CGFloat = isFloating ? 76 : 16
        contentLeadingConstraint?.update(offset: leading)
        let titleOffset: CGFloat = (leading - 16) / 2
        titleCenterXConstraint?.update(offset: titleOffset)
    }

    private func enableSwipeBackGesture() {
        var responder: UIResponder? = self
        while let nextResponder = responder?.next {
            if let viewController = nextResponder as? UIViewController {
                viewController.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
                viewController.navigationController?.interactivePopGestureRecognizer?.delegate = nil
                break
            }
            responder = nextResponder
        }
    }

    private func setupUI() {
        backgroundColor = .clear

        addLayoutGuide(contentLeadingGuide)
        addSubview(containerView)
        containerView.applyGradient(.tabBar)
        containerView.addSubview(leftButton)
        containerView.addSubview(titleLabel)
        containerView.addSubview(rightStackView)

        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        contentLeadingGuide.snp.makeConstraints { make in
            contentLeadingConstraint = make.leading.equalToSuperview().offset(16).constraint
            make.top.bottom.equalToSuperview()
            make.width.equalTo(0)
        }

        leftButton.snp.makeConstraints { make in
            make.leading.equalTo(contentLeadingGuide.snp.trailing)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(44)
        }

        titleLabel.snp.makeConstraints { make in
            titleCenterXConstraint = make.centerX.equalToSuperview().constraint
            make.centerY.equalToSuperview()
        }

        rightStackView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }

        leftButton.addTarget(self, action: #selector(leftButtonTapped), for: .touchUpInside)
    }

    @objc private func leftButtonTapped() {
        onLeftButtonTapped?()
    }

    func configure(title: String) {
        titleLabel.font = FontSystem.galmuriMono(size: 14)
        titleLabel.text = title
    }

    func addRightButton(title: String? = nil, image: UIImage? = nil, tintColor: UIColor = .black, action: @escaping () -> Void) {
        let button = UIButton()

        if let title = title {
            button.setTitle(title, for: .normal)
            button.titleLabel?.font = FontSystem.galmuriMono(size: 16)
            button.setTitleColor(tintColor, for: .normal)
        }

        if let image = image {
            var config = UIButton.Configuration.plain()
            config.image = image
            config.baseForegroundColor = tintColor
            button.configuration = config
        }

        button.snp.makeConstraints { make in
            make.width.height.equalTo(44)
        }

        let actionClosure = action
        button.addAction(UIAction { _ in actionClosure() }, for: .touchUpInside)

        rightStackView.addArrangedSubview(button)
    }

    func hideLeftButton() {
        leftButton.isHidden = true
    }

    func showLeftButton() {
        leftButton.isHidden = false
    }

    func setLeftButtonImage(_ image: UIImage?) {
        var config = leftButton.configuration
        config?.image = image
        leftButton.configuration = config
    }

    func setRightButtonHidden(_ hidden: Bool) {
        rightStackView.isHidden = hidden
    }
}
