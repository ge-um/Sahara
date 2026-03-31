//
//  StatCardView.swift
//  Sahara
//
//  Created by 금가경 on 10/8/25.
//

import SnapKit
import UIKit

final class StatCardView: UIView {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .typography(.caption)
        label.textColor = .token(.textTertiary)
        label.textAlignment = .center
        return label
    }()

    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = DesignToken.Typography.emphasis.numericFont
        label.textColor = .token(.textPrimary)
        label.textAlignment = .center
        return label
    }()

    private let unitLabel: UILabel = {
        let label = UILabel()
        label.font = .typography(.body)
        label.textColor = .token(.textTertiary)
        label.textAlignment = .center
        return label
    }()

    init() {
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        applyGlassCardStyle()

        let stackView = UIStackView(arrangedSubviews: [titleLabel, valueLabel, unitLabel])
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.alignment = .center

        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.horizontalEdges.equalToSuperview().inset(8)
        }
    }

    func configure(title: String, value: String, unit: String = "") {
        titleLabel.text = title
        valueLabel.text = value
        unitLabel.text = unit
    }
}
