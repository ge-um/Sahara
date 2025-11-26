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

    func configure(with sticker: StickerDTO, containerSize: CGSize, imageOrigin: CGPoint = .zero) {
        guard let resourceUrl = sticker.resourceUrl, let url = URL(string: resourceUrl) else {
            configureLocalSticker(sticker, containerSize: containerSize, imageOrigin: imageOrigin)
            return
        }

        let options: KingfisherOptionsInfo = [
            .scaleFactor(UIScreen.main.scale),
            .memoryCacheExpiration(.seconds(600)),
            .diskCacheExpiration(.days(7)),
            .cacheOriginalImage
        ]

        imageView.kf.setImage(with: url, options: options)

        applyTransform(sticker: sticker, containerSize: containerSize, imageOrigin: imageOrigin)
    }

    private func configureLocalSticker(_ sticker: StickerDTO, containerSize: CGSize, imageOrigin: CGPoint) {
        if let localPath = sticker.localFilePath {
            let fileURL = URL(fileURLWithPath: localPath)
            imageView.kf.setImage(with: fileURL)
        }

        applyTransform(sticker: sticker, containerSize: containerSize, imageOrigin: imageOrigin)
    }

    private func applyTransform(sticker: StickerDTO, containerSize: CGSize, imageOrigin: CGPoint) {
        let width = 100 * sticker.scale
        let height = 100 * sticker.scale
        let centerX = imageOrigin.x + (sticker.x * containerSize.width)
        let centerY = imageOrigin.y + (sticker.y * containerSize.height)

        frame = CGRect(
            x: centerX - width / 2,
            y: centerY - height / 2,
            width: width,
            height: height
        )
        transform = CGAffineTransform(rotationAngle: sticker.rotation)
    }
}
