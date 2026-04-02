//
//  SettingsSectionView.swift
//  Sahara
//

import SnapKit
import UIKit

final class SettingsSectionView: UIView {
    private(set) var itemViews: [SettingsItemView] = []

    private let headerLabel: UILabel = {
        let label = UILabel()
        label.font = .typography(.caption)
        label.textColor = .token(.textTertiary)
        return label
    }()

    private let cardContainer: UIView = {
        let view = UIView()
        view.applyGlassCardStyle()
        return view
    }()

    private let itemStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0
        return stack
    }()

    init(section: SettingsSection) {
        super.init(frame: .zero)
        headerLabel.text = section.title
        buildItems(section.items)
        configureUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func buildItems(_ items: [SettingsMenuItem]) {
        for (index, menuItem) in items.enumerated() {
            let itemView = SettingsItemView(item: menuItem)
            itemViews.append(itemView)
            itemStackView.addArrangedSubview(itemView)

            if index < items.count - 1 {
                let separator = createSeparator()
                itemStackView.addArrangedSubview(separator)
            }
        }
    }

    private func createSeparator() -> UIView {
        let container = UIView()
        let line = UIView()
        line.backgroundColor = DesignToken.Overlay.border

        container.addSubview(line)

        container.snp.makeConstraints { make in
            make.height.equalTo(0.5)
        }

        line.snp.makeConstraints { make in
            make.verticalEdges.equalToSuperview()
            make.horizontalEdges.equalToSuperview().inset(20)
        }

        return container
    }

    private func configureUI() {
        addSubview(headerLabel)
        addSubview(cardContainer)
        cardContainer.addSubview(itemStackView)

        headerLabel.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.equalToSuperview().offset(20)
        }

        cardContainer.snp.makeConstraints { make in
            make.top.equalTo(headerLabel.snp.bottom).offset(8)
            make.horizontalEdges.equalToSuperview()
            make.bottom.equalToSuperview()
        }

        itemStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func refresh() {
        itemViews.forEach { $0.refresh() }
    }
}
