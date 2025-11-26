//
//  CardDTOs.swift
//  Sahara
//
//  Created by 금가경 on 10/15/25.
//

import Foundation
import RealmSwift

struct CardListItemDTO {
    let id: ObjectId
    let editedImageData: Data
    let originalImageData: Data?
    let isLocked: Bool
    let stickers: [StickerDTO]

    init(from card: Card) {
        self.id = card.id
        self.editedImageData = card.editedImageData
        self.originalImageData = card.originalImageData
        self.isLocked = card.isLocked
        self.stickers = card.stickers.map { StickerDTO(from: $0) }
    }

    init(from dto: CardCalendarItemDTO) {
        self.id = dto.id
        self.editedImageData = dto.editedImageData
        self.originalImageData = dto.originalImageData
        self.isLocked = dto.isLocked
        self.stickers = dto.stickers
    }
}

struct CardDetailDTO {
    let id: ObjectId
    let date: Date
    let editedImageData: Data
    let originalImageData: Data?
    let memo: String?
    let latitude: Double?
    let longitude: Double?
    let isLocked: Bool
    let customFolder: String?

    init(from card: Card) {
        self.id = card.id
        self.date = card.date
        self.editedImageData = card.editedImageData
        self.originalImageData = card.originalImageData
        self.memo = card.memo
        self.latitude = card.latitude
        self.longitude = card.longitude
        self.isLocked = card.isLocked
        self.customFolder = card.customFolder
    }
}

struct CardCalendarItemDTO {
    let id: ObjectId
    let date: Date
    let editedImageData: Data
    let originalImageData: Data?
    let isLocked: Bool
    let stickers: [StickerDTO]

    init(from card: Card) {
        self.id = card.id
        self.date = card.date
        self.editedImageData = card.editedImageData
        self.originalImageData = card.originalImageData
        self.isLocked = card.isLocked
        self.stickers = card.stickers.map { StickerDTO(from: $0) }
    }
}

struct StickerDTO {
    let x: Double
    let y: Double
    let scale: Double
    let rotation: Double
    let zIndex: Int
    let sourceType: StickerSourceType
    let resourceUrl: String?
    let localFilePath: String?
    let photoAssetId: String?

    init(from sticker: Sticker) {
        self.x = sticker.x
        self.y = sticker.y
        self.scale = sticker.scale
        self.rotation = sticker.rotation
        self.zIndex = sticker.zIndex
        self.sourceType = sticker.sourceType
        self.resourceUrl = sticker.resourceUrl
        self.localFilePath = sticker.localFilePath
        self.photoAssetId = sticker.photoAssetId
    }
}
