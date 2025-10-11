//
//  SettingsSectionHeader.swift
//  Sahara
//
//  Created by 금가경 on 1/11/25.
//

import SnapKit
import UIKit

final class SettingsSectionHeader: UICollectionReusableView {
    static let identifier = "SettingsSectionHeader"

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = FontSystem.galmuriMono(size: 12)
        label.textColor = ColorSystem.labelSecondary
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureUI() {
        backgroundColor = .clear

        addSubview(titleLabel)

        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.bottom.equalToSuperview().offset(-8)
        }
    }

    func configure(with title: String) {
        titleLabel.text = title
    }
}
