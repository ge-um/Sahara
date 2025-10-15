//
//  SettingsMenuCell.swift
//  Sahara
//
//  Created by 금가경 on 1/11/25.
//

import SnapKit
import UIKit

final class SettingsMenuCell: UICollectionViewCell, IsIdentifiable {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = FontSystem.galmuriMono(size: 14)
        label.textColor = ColorSystem.labelPrimary
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = FontSystem.galmuriMono(size: 14)
        label.textColor = ColorSystem.labelSecondary
        return label
    }()

    private let chevronImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "chevron.right")
        imageView.tintColor = ColorSystem.labelPrimary
        imageView.contentMode = .scaleAspectFit
        return imageView
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

        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(chevronImageView)

        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.centerY.equalToSuperview()
        }

        subtitleLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
        }

        chevronImageView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(20)
        }
    }

    func configure(with item: SettingsMenuItem) {
        titleLabel.text = item.title

        if let subtitle = item.subtitle {
            subtitleLabel.text = subtitle
            subtitleLabel.isHidden = false
            chevronImageView.isHidden = true
        } else {
            subtitleLabel.isHidden = true
            chevronImageView.isHidden = false
        }
    }
}
