//
//  ImageSourceData.swift
//  Sahara
//
//  Created by 금가경 on 11/26/25.
//

import UIKit

struct ImageSourceData {
    let image: UIImage
    let format: ImageFormat?
    let stickers: [StickerDTO]

    enum ImageFormat: String {
        case heic
        case jpeg
        case png
    }

    init(
        image: UIImage,
        format: ImageFormat? = nil,
        stickers: [StickerDTO] = []
    ) {
        self.image = image
        self.format = format
        self.stickers = stickers
    }
}
