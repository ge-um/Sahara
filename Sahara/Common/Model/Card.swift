//
//  Card.swift
//  Sahara
//
//  Created by 금가경 on 9/27/25.
//

import RealmSwift
import UIKit

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

final class Card: Object {
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted(indexed: true) var date: Date
    @Persisted var createdDate: Date
    @Persisted var modifiedDate: Date?
    
    @Persisted var editedImageData: Data?
    @Persisted var imagePath: String?
    @Persisted var imageFormat: String?
    @Persisted var drawingData: Data?
    @Persisted var memo: String?
    @Persisted var latitude: Double?
    @Persisted var longitude: Double?
    @Persisted var isLocked: Bool = false

    @Persisted var type: ContentType = .photo
    @Persisted var isFavorite: Bool = false
    @Persisted var visionTags: List<VisionTag>
    @Persisted var locationName: String?
    @Persisted var mood: Mood?
    @Persisted var customFolder: String?
    @Persisted var ocrText: String?
    @Persisted var weatherCondition: WeatherCondition?

    convenience init(
        date: Date,
        createdDate: Date,
        editedImageData: Data? = nil,
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

// MARK: - Image Loading

extension Card {
    func resolvedImageData() -> Data? {
        if let imagePath = imagePath,
           let diskData = ImageFileManager.shared.loadImageFile(at: imagePath) {
            return diskData
        }
        guard let data = editedImageData, !data.isEmpty else { return nil }
        return data
    }
}

// MARK: - 현재 사용하지 않지만, 차후 업데이트를 위해 남겨둔 프로퍼티들
enum ContentType: String, PersistableEnum {
    case photo
    case video
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
