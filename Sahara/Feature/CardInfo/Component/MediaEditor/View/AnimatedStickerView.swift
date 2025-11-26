//
//  AnimatedStickerView.swift
//  Sahara
//
//  Created by 금가경 on 11/26/25.
//

import Kingfisher
import UIKit

final class AnimatedStickerView: UIView {
    private let imageView: AnimatedImageView = {
        let imageView = AnimatedImageView()
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
        addSubview(imageView)
        imageView.frame = bounds
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }

    func configure(with sticker: StickerDTO, containerSize: CGSize) {
        guard let resourceUrl = sticker.resourceUrl, let url = URL(string: resourceUrl) else {
            configureLocalSticker(sticker)
            return
        }

        let options: KingfisherOptionsInfo = [
            .scaleFactor(UIScreen.main.scale),
            .memoryCacheExpiration(.seconds(600)),
            .diskCacheExpiration(.days(7)),
            .cacheOriginalImage
        ]

        imageView.kf.setImage(with: url, options: options)

        frame = CGRect(
            x: sticker.x * containerSize.width,
            y: sticker.y * containerSize.height,
            width: 100 * sticker.scale,
            height: 100 * sticker.scale
        )
        transform = CGAffineTransform(rotationAngle: sticker.rotation)
    }

    private func configureLocalSticker(_ sticker: StickerDTO) {
        if let localPath = sticker.localFilePath {
            let fileURL = URL(fileURLWithPath: localPath)
            imageView.kf.setImage(with: fileURL)
        }
    }
}
