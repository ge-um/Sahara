//
//  ThemeCell.swift
//  Sahara
//
//  Created by 금가경 on 10/2/25.
//

import RealmSwift
import UIKit
final class ThemeCell: UITableViewCell, IsIdentifiable {
    private let thumbnailImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        return imageView
    }()

    private lazy var blurEffectView: UIVisualEffectView = BlurUtility.createBlurView(cornerRadius: 8)

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .typography(.label)
        return label
    }()

    private let countLabel: UILabel = {
        let label = UILabel()
        label.font = DesignToken.Typography.caption.numericFont
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
            make.leading.equalToSuperview()
            make.top.equalToSuperview()
            make.width.height.equalTo(80)
        }

        blurEffectView.snp.makeConstraints { make in
            make.edges.equalTo(thumbnailImageView)
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(thumbnailImageView.snp.trailing).offset(16)
            make.top.equalTo(thumbnailImageView).offset(2)
            make.trailing.equalToSuperview()
        }

        countLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.trailing.equalToSuperview()
        }
    }

    func configure(with group: ThemeGroup) {
        titleLabel.text = group.category.localizedName
        countLabel.text = String(format: NSLocalizedString("common.photo_count", comment: ""), group.cardIds.count)

        let cards = group.cardIds.compactMap { RealmService.shared.fetchObject(Card.self, forPrimaryKey: $0) }
        let sortedPhotos = cards.sorted { !$0.isLocked && $1.isLocked }

        if let firstPhoto = sortedPhotos.first {
            blurEffectView.isHidden = !firstPhoto.isLocked
            let pixelSize = 80 * max(traitCollection.displayScale, 1)
            ThumbnailCache.shared.loadThumbnail(for: firstPhoto.id, maxPixelSize: pixelSize) { [weak self] image in
                self?.thumbnailImageView.image = image
            }
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
