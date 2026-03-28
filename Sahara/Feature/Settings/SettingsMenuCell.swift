//
//  SettingsMenuCell.swift
//  Sahara
//
//  Created by 금가경 on 1/11/25.
//

import SnapKit
import UIKit

final class SettingsMenuCell: UICollectionViewCell, IsIdentifiable {
    var onToggleChanged: ((Bool) -> Void)?

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = FontSystem.galmuriMono(size: 14)
        label.textColor = .token(.textSecondary)
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = FontSystem.galmuriMono(size: 10)
        label.textColor = .token(.textPrimary)
        label.numberOfLines = 0
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = FontSystem.galmuriMono(size: 14)
        label.textColor = .token(.textPrimary)
        return label
    }()

    private let chevronImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "chevron.right")
        imageView.tintColor = .token(.iconTint)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private lazy var toggleSwitch: UISwitch = {
        let toggle = UISwitch()
        toggle.onTintColor = .token(.accent)
        toggle.addTarget(self, action: #selector(toggleChanged), for: .valueChanged)
        return toggle
    }()

    private var labelStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 4
        stack.alignment = .leading
        return stack
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

        labelStackView.addArrangedSubview(titleLabel)
        labelStackView.addArrangedSubview(descriptionLabel)

        contentView.addSubview(labelStackView)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(chevronImageView)
        contentView.addSubview(toggleSwitch)

        labelStackView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualTo(toggleSwitch.snp.leading).offset(-12)
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

        toggleSwitch.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
        }

    }

    @objc private func toggleChanged() {
        onToggleChanged?(toggleSwitch.isOn)
    }

    func configure(with item: SettingsMenuItem) {
        titleLabel.text = item.title

        if item.hasToggle {
            descriptionLabel.text = item.subtitle
            descriptionLabel.isHidden = item.subtitle == nil
            toggleSwitch.isHidden = false
            subtitleLabel.isHidden = true
            chevronImageView.isHidden = true

            if case .serviceNews = item {
                toggleSwitch.setOn(NotificationSettings.shared.isServiceNewsEnabled, animated: false)
            }
            if case .cloudSync = item {
                toggleSwitch.setOn(CloudSyncService.current?.isEnabled ?? false, animated: false)
            }
        } else {
            descriptionLabel.isHidden = true
            toggleSwitch.isHidden = true

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
}
