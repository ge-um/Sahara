//
//  SidebarView.swift
//  Sahara
//
//  Created by 금가경 on 3/16/26.
//

import SnapKit
import UIKit

final class SidebarView: UIView {
    static let width: CGFloat = {
        let maxLabelWidth = TabItem.allCases
            .map { $0.title.size(withAttributes: [.font: UIFont.typography(.caption)]).width }
            .max() ?? 0
        let buttonSize = max(56, ceil(maxLabelWidth) + 16)
        let padding: CGFloat = {
            #if targetEnvironment(macCatalyst)
            return 44
            #else
            return 24
            #endif
        }()
        return buttonSize + padding
    }()

    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 8
        return stack
    }()

    private var tabButtons: [TabItem: TabButton] = [:]
    private var stackTopConstraint: Constraint?

    var onTabSelected: ((TabItem) -> Void)?

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

    private func setupUI() {
        clipsToBounds = true
        applyGradient(.sidebar)

        addSubview(stackView)

        let maxLabelWidth = TabItem.allCases
            .map { $0.title.size(withAttributes: [.font: UIFont.typography(.caption)]).width }
            .max() ?? 0
        let bgWidth = max(48, ceil(maxLabelWidth) + 16)
        let buttonSize = max(56, bgWidth)

        for item in TabItem.allCases {
            let button = TabButton(icon: item.icon, title: item.title)
            button.accessibilityIdentifier = item.accessibilityId
            button.onTap = { [weak self] in
                self?.onTabSelected?(item)
            }
            button.setBackgroundWidth(bgWidth)
            button.snp.makeConstraints { make in
                make.width.equalTo(buttonSize)
                make.height.equalTo(56)
            }
            stackView.addArrangedSubview(button)
            tabButtons[item] = button
        }

        stackView.snp.makeConstraints { make in
            stackTopConstraint = make.top.equalTo(safeAreaLayoutGuide).offset(16).constraint
            make.centerX.equalToSuperview()
        }
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        updateTopForWindowControls(isFloating: isInFloatingWindow)
    }

    @objc private func floatingWindowStateChanged() {
        updateTopForWindowControls(isFloating: isInFloatingWindow)
    }

    private func updateTopForWindowControls(isFloating: Bool) {
        // 48: 윈도우 컨트롤(신호등) 아래 충분한 여백 확보
        let top: CGFloat = isFloating ? 48 : 16
        stackTopConstraint?.update(offset: top)
    }

    func setSelectedTab(_ tab: TabItem) {
        for (item, button) in tabButtons {
            button.setSelected(item == tab)
        }
    }
}
