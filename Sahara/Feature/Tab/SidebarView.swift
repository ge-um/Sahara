//
//  SidebarView.swift
//  Sahara
//
//  Created by 금가경 on 3/16/26.
//

import SnapKit
import UIKit

final class SidebarView: UIView {
    static let width: CGFloat = 72

    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 8
        return stack
    }()

    private var tabButtons: [TabItem: TabButton] = [:]

    var onTabSelected: ((TabItem) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        clipsToBounds = true
        applyGradient(.sidebar)

        addSubview(stackView)

        for item in TabItem.allCases {
            let button = TabButton(icon: item.icon, title: item.title)
            button.onTap = { [weak self] in
                self?.onTabSelected?(item)
            }
            button.snp.makeConstraints { make in
                make.width.height.equalTo(56)
            }
            stackView.addArrangedSubview(button)
            tabButtons[item] = button
        }

        stackView.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide).offset(16)
            make.centerX.equalToSuperview()
        }
    }

    func setSelectedTab(_ tab: TabItem) {
        for (item, button) in tabButtons {
            button.setSelected(item == tab)
        }
    }
}
