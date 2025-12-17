//
//  ImageSourceData.swift
//  Sahara
//
//  Created by 금가경 on 11/26/25.
//

import UIKit

struct ImageSourceData {
    let image: UIImage
    let originalData: Data?
    let format: ImageFormat?
    let stickers: [StickerDTO]
    let appliedFilterIndex: Int?
    let cropMetadata: CropMetadata?

    enum ImageFormat: String {
        case heic
        case jpeg
        case png
    }

    init(
        image: UIImage,
        originalData: Data? = nil,
        format: ImageFormat? = nil,
        stickers: [StickerDTO] = [],
        appliedFilterIndex: Int? = nil,
        cropMetadata: CropMetadata? = nil
    ) {
        self.image = image
        self.originalData = originalData
        self.format = format
        self.stickers = stickers
        self.appliedFilterIndex = appliedFilterIndex
        self.cropMetadata = cropMetadata
    }
}
