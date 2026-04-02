//
//  SettingsItemView.swift
//  Sahara
//

import RxCocoa
import RxSwift
import SnapKit
import UIKit

final class SettingsItemView: UIView {
    let item: SettingsMenuItem
    var onToggleChanged: ((Bool) -> Void)?

    private(set) var tapSubject = PublishRelay<Void>()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .typography(.label)
        label.textColor = .token(.textSecondary)
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .typography(.small)
        label.textColor = .token(.textPrimary)
        label.numberOfLines = 0
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .typography(.label)
        label.textColor = .token(.textSecondary)
        return label
    }()

    private let chevronImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "chevron.right")
        imageView.tintColor = .token(.textSecondary)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private lazy var toggleSwitch: UISwitch = {
        let toggle = UISwitch()
        toggle.onTintColor = .token(.accent)
        toggle.addTarget(self, action: #selector(toggleChanged), for: .valueChanged)
        return toggle
    }()

    private let labelStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 4
        stack.alignment = .leading
        return stack
    }()

    init(item: SettingsMenuItem) {
        self.item = item
        super.init(frame: .zero)
        configureUI()
        refresh()

        if item.isSelectable {
            let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
            addGestureRecognizer(tap)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureUI() {
        backgroundColor = .clear

        labelStackView.addArrangedSubview(titleLabel)
        labelStackView.addArrangedSubview(descriptionLabel)

        addSubview(labelStackView)
        addSubview(subtitleLabel)
        addSubview(chevronImageView)
        addSubview(toggleSwitch)

        snp.makeConstraints { make in
            make.height.equalTo(60)
        }

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

    func refresh() {
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

    @objc private func toggleChanged() {
        onToggleChanged?(toggleSwitch.isOn)
    }

    @objc private func handleTap() {
        tapSubject.accept(())
    }
}
