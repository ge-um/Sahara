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
        label.font = FontSystem.galmuriMono(size: 14)
        label.textColor = UIColor(hex: "#666666")
        label.textAlignment = .center
        return label
    }()

    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = FontSystem.galmuriMono(size: 28)
        label.textColor = .black
        label.textAlignment = .center
        return label
    }()

    private let unitLabel: UILabel = {
        let label = UILabel()
        label.font = FontSystem.galmuriMono(size: 14)
        label.textColor = UIColor(hex: "#666666")
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
        backgroundColor = UIColor(hex: "#D2D1E4").withAlphaComponent(0.3)
        layer.cornerRadius = 12
        clipsToBounds = true

        addSubview(titleLabel)
        addSubview(valueLabel)
        addSubview(unitLabel)

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.horizontalEdges.equalToSuperview().inset(8)
        }

        valueLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.horizontalEdges.equalToSuperview().inset(8)
        }

        unitLabel.snp.makeConstraints { make in
            make.top.equalTo(valueLabel.snp.bottom).offset(4)
            make.horizontalEdges.equalToSuperview().inset(8)
            make.bottom.equalToSuperview().offset(-16)
        }
    }

    func configure(title: String, value: String, unit: String = "") {
        titleLabel.text = title
        valueLabel.text = value
        unitLabel.text = unit
    }
}
