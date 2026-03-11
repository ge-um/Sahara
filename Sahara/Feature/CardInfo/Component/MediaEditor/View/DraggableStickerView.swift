//
//  DraggableStickerView.swift
//  Sahara
//
//  Created by 금가경 on 9/26/25.
//

import Kingfisher
import UIKit

final class DraggableStickerView: BaseGestureView {
    private let imageView: AnimatedImageView = {
        let imageView = AnimatedImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let kingfisherOptions: KingfisherOptionsInfo = [
        .scaleFactor(UIScreen.main.scale),
        .memoryCacheExpiration(.seconds(600)),
        .diskCacheExpiration(.days(7)),
        .cacheOriginalImage,
        .onlyLoadFirstFrame
    ]

    var stickerURL: URL?

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

    func configure(with sticker: KlipySticker) {
        guard let url = sticker.resolveImageURL(quality: .highFirst) else { return }
        self.stickerURL = url
        imageView.kf.setImage(with: url, options: kingfisherOptions)
    }

    func configure(with stickerDTO: StickerDTO) {
        if let urlString = stickerDTO.resourceUrl, let url = URL(string: urlString) {
            self.stickerURL = url
            imageView.kf.setImage(with: url, options: kingfisherOptions)
        } else if let localPath = stickerDTO.localFilePath {
            let fileURL = URL(fileURLWithPath: localPath)
            if let data = try? Data(contentsOf: fileURL), let image = UIImage(data: data) {
                imageView.image = image
            }
        } else if let _ = stickerDTO.photoAssetId {

        }
    }
}