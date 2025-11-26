//
//  CardListCell.swift
//  Sahara
//
//  Created by 금가경 on 10/13/25.
//

import UIKit

final class CardListCell: UICollectionViewCell, IsIdentifiable {

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .systemGray6
        return imageView
    }()

    private var stickerViews: [AnimatedStickerView] = []

    private lazy var blurEffectView: UIVisualEffectView = BlurUtility.createBlurView(cornerRadius: 8)

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureUI() {
        contentView.addSubview(imageView)
        contentView.addSubview(blurEffectView)
        contentView.layer.cornerRadius = 8
        contentView.clipsToBounds = true

        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        blurEffectView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func configure(with item: CardListItemDTO) {
        let imageData = item.originalImageData ?? item.editedImageData
        if let image = UIImage(data: imageData) {
            imageView.image = image
        }
        blurEffectView.isHidden = !item.isLocked

        renderStickers(item.stickers)
    }

    private func renderStickers(_ stickers: [StickerDTO]) {
        stickerViews.forEach { $0.removeFromSuperview() }
        stickerViews.removeAll()

        guard let image = imageView.image else { return }

        let imageRect = MediaEditorCropHandler.calculateDisplayedImageRect(
            imageSize: image.size,
            in: contentView.bounds.size
        )

        let sortedStickers = stickers.sorted { $0.zIndex < $1.zIndex }

        for sticker in sortedStickers {
            let stickerView = AnimatedStickerView()
            stickerView.configure(with: sticker, containerSize: imageRect.size, imageOrigin: imageRect.origin)
            contentView.addSubview(stickerView)
            stickerViews.append(stickerView)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        blurEffectView.isHidden = true
        stickerViews.forEach { $0.removeFromSuperview() }
        stickerViews.removeAll()
    }
}
