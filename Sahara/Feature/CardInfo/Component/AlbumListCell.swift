//
//  AlbumListCell.swift
//  Sahara
//
//  Created by 금가경 on 3/27/26.
//

import Photos
import SnapKit
import UIKit

final class AlbumListCell: UITableViewCell {
    static let identifier = "AlbumListCell"

    private let thumbnailImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 6
        iv.backgroundColor = .secondarySystemBackground
        return iv
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .typography(.label)
        label.textColor = .label
        return label
    }()

    private let countLabel: UILabel = {
        let label = UILabel()
        label.font = DesignToken.Typography.caption.numericFont
        label.textColor = .secondaryLabel
        return label
    }()

    private let checkmarkLabel: UILabel = {
        let label = UILabel()
        label.font = .typography(.title)
        label.textColor = .token(.accent)
        label.text = "✓"
        label.isHidden = true
        return label
    }()

    private var imageRequestID: PHImageRequestID?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        thumbnailImageView.image = nil
        checkmarkLabel.isHidden = true
        if let requestID = imageRequestID {
            PHCachingImageManager.default().cancelImageRequest(requestID)
            imageRequestID = nil
        }
    }

    private func setupUI() {
        let textStack = UIStackView(arrangedSubviews: [titleLabel, countLabel])
        textStack.axis = .vertical
        textStack.spacing = 2

        contentView.addSubview(thumbnailImageView)
        contentView.addSubview(textStack)
        contentView.addSubview(checkmarkLabel)

        thumbnailImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(48)
        }

        textStack.snp.makeConstraints { make in
            make.leading.equalTo(thumbnailImageView.snp.trailing).offset(12)
            make.centerY.equalTo(thumbnailImageView)
            make.trailing.equalTo(checkmarkLabel.snp.leading).offset(-8)
        }

        checkmarkLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().inset(16)
        }
    }

    func configure(with album: Album, isSelected: Bool, imageManager: PHCachingImageManager) {
        titleLabel.text = album.title
        countLabel.text = String(format: NSLocalizedString("media_selection.photo_count", comment: ""), album.count)
        checkmarkLabel.isHidden = !isSelected

        guard let asset = album.thumbnailAsset else { return }
        let targetSize = CGSize(width: 96, height: 96)
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.isNetworkAccessAllowed = true

        imageRequestID = imageManager.requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: options
        ) { [weak self] image, _ in
            self?.thumbnailImageView.image = image
        }
    }
}
