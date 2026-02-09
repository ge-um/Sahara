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
    let filterIndex: Int?
    let uncroppedImage: UIImage?
    let cropRect: CGRect?
    let drawingData: Data?
    let previewImage: UIImage?

    enum ImageFormat: String {
        case heic
        case jpeg
        case png
    }

    init(
        image: UIImage,
        format: ImageFormat? = nil,
        stickers: [StickerDTO] = [],
        filterIndex: Int? = nil,
        uncroppedImage: UIImage? = nil,
        cropRect: CGRect? = nil,
        drawingData: Data? = nil,
        previewImage: UIImage? = nil
    ) {
        self.image = image
        self.format = format
        self.stickers = stickers
        self.filterIndex = filterIndex
        self.uncroppedImage = uncroppedImage
        self.cropRect = cropRect
        self.drawingData = drawingData
        self.previewImage = previewImage
    }
}
