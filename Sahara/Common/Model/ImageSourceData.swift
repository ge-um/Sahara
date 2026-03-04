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
    let editorViewSize: CGSize?
    let format: ImageFormat?
    let stickers: [StickerDTO]
    let filterIndex: Int?
    let uncroppedImage: UIImage?
    let cropRect: CGRect?
    let drawingData: Data?

    enum ImageFormat: String {
        case heic
        case jpeg
        case png
    }

    init(
        image: UIImage,
        originalData: Data? = nil,
        editorViewSize: CGSize? = nil,
        format: ImageFormat? = nil,
        stickers: [StickerDTO] = [],
        filterIndex: Int? = nil,
        uncroppedImage: UIImage? = nil,
        cropRect: CGRect? = nil,
        drawingData: Data? = nil
    ) {
        self.image = image
        self.originalData = originalData
        self.editorViewSize = editorViewSize
        self.format = format
        self.stickers = stickers
        self.filterIndex = filterIndex
        self.uncroppedImage = uncroppedImage
        self.cropRect = cropRect
        self.drawingData = drawingData
    }

    var hasEdits: Bool {
        if let filterIndex = filterIndex, filterIndex > 0 { return true }
        if !stickers.isEmpty { return true }
        if cropRect != nil { return true }
        if drawingData != nil { return true }
        return false
    }
}
