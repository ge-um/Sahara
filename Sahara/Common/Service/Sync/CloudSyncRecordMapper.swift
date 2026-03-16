//
//  CloudSyncRecordMapper.swift
//  Sahara
//

import CloudKit
import RealmSwift

enum CloudSyncRecordMapper {
    static let zoneName = "SaharaZone"
    static let recordType: CKRecord.RecordType = "Card"
    static let zoneID = CKRecordZone.ID(zoneName: zoneName)

    enum RecordField {
        static let date = "date"
        static let createdDate = "createdDate"
        static let modifiedDate = "modifiedDate"
        static let memo = "memo"
        static let latitude = "latitude"
        static let longitude = "longitude"
        static let isLocked = "isLocked"
        static let isFavorite = "isFavorite"
        static let locationName = "locationName"
        static let mood = "mood"
        static let weatherCondition = "weatherCondition"
        static let customFolder = "customFolder"
        static let ocrText = "ocrText"
        static let visionTags = "visionTags"
        static let imageFormat = "imageFormat"
        static let drawingData = "drawingData"
        static let imageAsset = "imageAsset"
    }

    static func recordID(for cardId: ObjectId) -> CKRecord.ID {
        CKRecord.ID(recordName: cardId.stringValue, zoneID: zoneID)
    }

    static func cardId(from recordID: CKRecord.ID) -> ObjectId? {
        try? ObjectId(string: recordID.recordName)
    }

    // MARK: - Card → CKRecord

    static func populateRecord(_ record: CKRecord, from card: Card, imageAsset: CKAsset?) {
        record[RecordField.date] = card.date as NSDate
        record[RecordField.createdDate] = card.createdDate as NSDate
        record[RecordField.modifiedDate] = card.modifiedDate as NSDate?
        record[RecordField.memo] = card.memo as NSString?
        record[RecordField.latitude] = card.latitude.map { NSNumber(value: $0) }
        record[RecordField.longitude] = card.longitude.map { NSNumber(value: $0) }
        record[RecordField.isLocked] = NSNumber(value: card.isLocked)
        record[RecordField.isFavorite] = NSNumber(value: card.isFavorite)
        record[RecordField.locationName] = card.locationName as NSString?
        record[RecordField.mood] = card.mood?.rawValue as NSString?
        record[RecordField.weatherCondition] = card.weatherCondition?.rawValue as NSString?
        record[RecordField.customFolder] = card.customFolder as NSString?
        record[RecordField.ocrText] = card.ocrText as NSString?
        record[RecordField.visionTags] = card.visionTags.map(\.rawValue) as NSArray
        record[RecordField.imageFormat] = card.imageFormat as NSString?
        record[RecordField.drawingData] = card.drawingData as NSData?

        if let imageAsset {
            record[RecordField.imageAsset] = imageAsset
        }
    }

    // MARK: - CKRecord → Card

    static func applyRecord(_ record: CKRecord, to card: Card) {
        if let date = record[RecordField.date] as? Date { card.date = date }
        if let createdDate = record[RecordField.createdDate] as? Date { card.createdDate = createdDate }
        card.modifiedDate = record[RecordField.modifiedDate] as? Date
        card.memo = record[RecordField.memo] as? String
        card.latitude = record[RecordField.latitude] as? Double
        card.longitude = record[RecordField.longitude] as? Double
        card.isLocked = (record[RecordField.isLocked] as? NSNumber)?.boolValue ?? false
        card.isFavorite = (record[RecordField.isFavorite] as? NSNumber)?.boolValue ?? false
        card.locationName = record[RecordField.locationName] as? String
        card.customFolder = record[RecordField.customFolder] as? String
        card.ocrText = record[RecordField.ocrText] as? String
        card.imageFormat = record[RecordField.imageFormat] as? String
        card.drawingData = record[RecordField.drawingData] as? Data

        if let raw = record[RecordField.mood] as? String {
            card.mood = Mood(rawValue: raw)
        } else {
            card.mood = nil
        }

        if let raw = record[RecordField.weatherCondition] as? String {
            card.weatherCondition = WeatherCondition(rawValue: raw)
        } else {
            card.weatherCondition = nil
        }

        card.visionTags.removeAll()
        if let rawTags = record[RecordField.visionTags] as? [String] {
            for tag in rawTags {
                if let visionTag = VisionTag(rawValue: tag) {
                    card.visionTags.append(visionTag)
                }
            }
        }
    }
}
