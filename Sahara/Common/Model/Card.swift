//
//  Card.swift
//  Sahara
//
//  Created by 금가경 on 9/27/25.
//

import RealmSwift
import UIKit

enum ContentType: String, PersistableEnum {
    case photo
    case video
}

enum StickerSourceType: String, PersistableEnum {
    case kilpy
    case photo
}

enum VisionTag: String, PersistableEnum {
    case person
    case cat
    case dog
    case bird

    case food
    case drink

    case nature
    case sky
    case sunset
    case flower
    case tree
    case ocean
    case mountain

    case building
    case landmark
    case indoor
    case outdoor

    case car
    case bicycle

    case text
    case screenshot
}

enum Mood: String, PersistableEnum {
    case happy
    case excited
    case loved
    case peaceful
    case grateful
    case sad
    case angry
    case anxious
    case tired
    case nostalgic
}

enum WeatherCondition: String, PersistableEnum {
    case clear
    case partlyCloudy
    case cloudy
    case rain
    case snow
    case thunderstorm
    case fog
    case unknown

    var icon: String {
        switch self {
        case .clear:
            return "sun.max.fill"
        case .partlyCloudy:
            return "cloud.sun.fill"
        case .cloudy:
            return "cloud.fill"
        case .rain:
            return "cloud.rain.fill"
        case .snow:
            return "cloud.snow.fill"
        case .thunderstorm:
            return "cloud.bolt.fill"
        case .fog:
            return "cloud.fog.fill"
        case .unknown:
            return "questionmark.circle.fill"
        }
    }
}

final class Card: Object {
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted(indexed: true) var date: Date
    @Persisted var createdDate: Date
    @Persisted var modifiedDate: Date?
    
    @Persisted var editedImageData: Data
    @Persisted var memo: String?
    @Persisted var latitude: Double?
    @Persisted var longitude: Double?
    @Persisted var isLocked: Bool = false

    @Persisted var type: ContentType = .photo
    @Persisted var isFavorite: Bool = false
    @Persisted var visionTags: List<VisionTag>
    @Persisted var locationName: String?
    @Persisted var mood: Mood?
    @Persisted var stickers: List<Sticker>
    @Persisted var customFolder: String?
    @Persisted var ocrText: String?
    @Persisted var weatherCondition: WeatherCondition?

    convenience init(
        date: Date,
        createdDate: Date,
        editedImageData: Data,
        memo: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        isLocked: Bool = false
    ) {
        self.init()
        self.date = date
        self.createdDate = createdDate
        self.editedImageData = editedImageData
        self.memo = memo
        self.latitude = latitude
        self.longitude = longitude
        self.isLocked = isLocked
    }
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
    @Persisted var photoAssetId: String?

    convenience init(
        x: Double,
        y: Double,
        scale: Double,
        rotation: Double,
        zIndex: Int,
        sourceType: StickerSourceType,
        resourceUrl: String? = nil,
        photoAssetId: String? = nil
    ) {
        self.init()
        self.x = x
        self.y = y
        self.scale = scale
        self.rotation = rotation
        self.zIndex = zIndex
        self.sourceType = sourceType
        self.resourceUrl = resourceUrl
        self.photoAssetId = photoAssetId
    }
}
