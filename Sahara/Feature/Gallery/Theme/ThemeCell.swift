//
//  ThemeCell.swift
//  Sahara
//
//  Created by 금가경 on 10/2/25.
//

import UIKit
final class ThemeCell: UITableViewCell, IsIdentifiable {
    private let thumbnailImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.backgroundColor = .systemGray6
        return imageView
    }()

    private let blurEffectView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .extraLight)
        let effectView = UIVisualEffectView(effect: blurEffect)
        effectView.layer.cornerRadius = 8
        effectView.clipsToBounds = true
        effectView.isHidden = true
        return effectView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = FontSystem.galmuriMono(size: 16)
        return label
    }()

    private let countLabel: UILabel = {
        let label = UILabel()
        label.font = FontSystem.galmuriMono(size: 12)
        label.textColor = .secondaryLabel
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureUI() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(thumbnailImageView)
        contentView.addSubview(blurEffectView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(countLabel)

        thumbnailImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(80)
        }

        blurEffectView.snp.makeConstraints { make in
            make.edges.equalTo(thumbnailImageView)
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(thumbnailImageView.snp.trailing).offset(16)
            make.top.equalTo(thumbnailImageView).offset(10)
            make.trailing.equalToSuperview().inset(16)
        }

        countLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.trailing.equalToSuperview().inset(16)
        }
    }

    func configure(with group: ThemeGroup) {
        titleLabel.text = group.category.localizedName
        countLabel.text = String(format: NSLocalizedString("common.photo_count", comment: ""), group.cards.count)

        let sortedPhotos = group.cards.sorted { !$0.isLocked && $1.isLocked }

        if let firstPhoto = sortedPhotos.first,
           let image = UIImage(data: firstPhoto.editedImageData) {
            thumbnailImageView.image = image
            blurEffectView.isHidden = !firstPhoto.isLocked
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        thumbnailImageView.image = nil
        titleLabel.text = nil
        countLabel.text = nil
        blurEffectView.isHidden = true
    }
}
