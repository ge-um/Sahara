//
//  CardDTOs.swift
//  Sahara
//
//  Created by 금가경 on 10/15/25.
//

import Foundation
import RealmSwift
import UIKit

struct CardListItemDTO {
    let id: ObjectId
    let isLocked: Bool

    init(from card: Card) {
        self.id = card.id
        self.isLocked = card.isLocked
    }

    init(from dto: CardCalendarItemDTO) {
        self.id = dto.id
        self.isLocked = dto.isLocked
    }
}

struct CardDetailDTO {
    let id: ObjectId
    let date: Date
    let editedImageData: Data
    let memo: String?
    let latitude: Double?
    let longitude: Double?
    let isLocked: Bool
    let customFolder: String?

    init(from card: Card) {
        self.id = card.id
        self.date = card.date
        self.editedImageData = card.editedImageData
        self.memo = card.memo
        self.latitude = card.latitude
        self.longitude = card.longitude
        self.isLocked = card.isLocked
        self.customFolder = card.customFolder
    }
}

struct SearchCardDTO {
    let id: ObjectId
    let isLocked: Bool
    let imageSize: CGSize

    init(from card: Card) {
        self.id = card.id
        self.isLocked = card.isLocked
        self.imageSize = ImageDownsampler.imageSize(from: card.editedImageData) ?? CGSize(width: 1, height: 1)
    }
}

struct CardCalendarItemDTO {
    let id: ObjectId
    let date: Date
    let isLocked: Bool

    init(from card: Card) {
        self.id = card.id
        self.date = card.date
        self.isLocked = card.isLocked
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
    let isAnimated: Bool

    init(
        x: Double,
        y: Double,
        scale: Double,
        rotation: Double,
        zIndex: Int,
        sourceType: StickerSourceType,
        resourceUrl: String?,
        localFilePath: String?,
        photoAssetId: String?,
        isAnimated: Bool = false
    ) {
        self.x = x
        self.y = y
        self.scale = scale
        self.rotation = rotation
        self.zIndex = zIndex
        self.sourceType = sourceType
        self.resourceUrl = resourceUrl
        self.localFilePath = localFilePath
        self.photoAssetId = photoAssetId
        self.isAnimated = isAnimated
    }
}
