//
//  LocationSearchCell.swift
//  Sahara
//
//  Created by 금가경 on 10/6/25.
//

import UIKit
import MapKit

final class LocationSearchCell: UITableViewCell {
    static let identifier = "LocationSearchCell"

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .typography(.label)
        label.textColor = .token(.textPrimary)
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .typography(.caption)
        label.textColor = .token(.textSecondary)
        return label
    }()

    private let iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "mappin.circle.fill")
        imageView.tintColor = .token(.textSecondary)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.addSubview(iconView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)

        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(28)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(12)
            make.leading.equalTo(iconView.snp.trailing).offset(12)
            make.trailing.equalToSuperview().inset(20)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.equalTo(titleLabel)
            make.trailing.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().inset(12)
        }
    }

    func configure(with completion: MKLocalSearchCompletion) {
        titleLabel.text = completion.title
        subtitleLabel.text = completion.subtitle
    }
}
