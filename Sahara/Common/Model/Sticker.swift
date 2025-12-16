//
//  Sticker.swift
//  Sahara
//
//  Created by 금가경 on 12/16/25.
//

import RealmSwift

enum StickerSourceType: String, PersistableEnum {
    case kilpy
    case photo
}

final class Sticker: Object {
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted var x: Double
    @Persisted var y: Double
    @Persisted var scale: Double
    @Persisted var rotation: Double
    @Persisted var zIndex: Int
    @Persisted var sourceType: StickerSourceType
    @Persisted var resourceUrl: String?
    @Persisted var localFilePath: String?
    @Persisted var photoAssetId: String?
    @Persisted var isAnimated: Bool = false

    convenience init(
        x: Double,
        y: Double,
        scale: Double,
        rotation: Double,
        zIndex: Int,
        sourceType: StickerSourceType,
        resourceUrl: String? = nil,
        localFilePath: String? = nil,
        photoAssetId: String? = nil,
        isAnimated: Bool = false
    ) {
        self.init()
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
