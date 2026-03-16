//
//  CloudSyncRecordMapperTests.swift
//  SaharaTests
//

import CloudKit
import RealmSwift
import XCTest
@testable import Sahara

final class CloudSyncRecordMapperTests: XCTestCase {

    private func makeRecord(for cardId: ObjectId) -> CKRecord {
        let recordID = CloudSyncRecordMapper.recordID(for: cardId)
        return CKRecord(recordType: CloudSyncRecordMapper.recordType, recordID: recordID)
    }

    // MARK: - 데이터 변환 정확성

    func test_populateAndApply_roundtrip_preservesAllFields() {
        let card = Card()
        card.date = Date(timeIntervalSince1970: 1_000_000)
        card.createdDate = Date(timeIntervalSince1970: 2_000_000)
        card.modifiedDate = Date(timeIntervalSince1970: 3_000_000)
        card.memo = "Test memo"
        card.latitude = 37.5665
        card.longitude = 126.9780
        card.isLocked = true
        card.isFavorite = true
        card.locationName = "Seoul"
        card.mood = .happy
        card.weatherCondition = .clear
        card.customFolder = "Travel"
        card.ocrText = "Sample OCR"
        card.imageFormat = "heic"
        card.drawingData = Data([0x01, 0x02])
        card.visionTags.append(objectsIn: [.person, .nature, .sky])

        let record = makeRecord(for: card.id)
        CloudSyncRecordMapper.populateRecord(record, from: card, imageAsset: nil)

        let restored = Card()
        CloudSyncRecordMapper.applyRecord(record, to: restored)

        XCTAssertEqual(restored.date, card.date)
        XCTAssertEqual(restored.createdDate, card.createdDate)
        XCTAssertEqual(restored.modifiedDate, card.modifiedDate)
        XCTAssertEqual(restored.memo, card.memo)
        XCTAssertEqual(restored.latitude, card.latitude)
        XCTAssertEqual(restored.longitude, card.longitude)
        XCTAssertEqual(restored.isLocked, card.isLocked)
        XCTAssertEqual(restored.isFavorite, card.isFavorite)
        XCTAssertEqual(restored.locationName, card.locationName)
        XCTAssertEqual(restored.mood, card.mood)
        XCTAssertEqual(restored.weatherCondition, card.weatherCondition)
        XCTAssertEqual(restored.customFolder, card.customFolder)
        XCTAssertEqual(restored.ocrText, card.ocrText)
        XCTAssertEqual(restored.imageFormat, card.imageFormat)
        XCTAssertEqual(restored.drawingData, card.drawingData)
        XCTAssertEqual(Array(restored.visionTags), Array(card.visionTags))
    }

    func test_populateRecord_optionalFieldsNil_recordStoresNil() {
        let card = Card()
        card.date = Date()
        card.createdDate = Date()
        // All optional fields left as nil

        let record = makeRecord(for: card.id)
        CloudSyncRecordMapper.populateRecord(record, from: card, imageAsset: nil)

        XCTAssertNil(record[CloudSyncRecordMapper.RecordField.modifiedDate])
        XCTAssertNil(record[CloudSyncRecordMapper.RecordField.memo])
        XCTAssertNil(record[CloudSyncRecordMapper.RecordField.latitude])
        XCTAssertNil(record[CloudSyncRecordMapper.RecordField.longitude])
        XCTAssertNil(record[CloudSyncRecordMapper.RecordField.locationName])
        XCTAssertNil(record[CloudSyncRecordMapper.RecordField.mood])
        XCTAssertNil(record[CloudSyncRecordMapper.RecordField.weatherCondition])
        XCTAssertNil(record[CloudSyncRecordMapper.RecordField.customFolder])
        XCTAssertNil(record[CloudSyncRecordMapper.RecordField.ocrText])
        XCTAssertNil(record[CloudSyncRecordMapper.RecordField.imageFormat])
        XCTAssertNil(record[CloudSyncRecordMapper.RecordField.drawingData])
    }

    func test_applyRecord_dateFieldsNil_preservesExistingDates() {
        let existingDate = Date(timeIntervalSince1970: 1_000_000)
        let existingCreated = Date(timeIntervalSince1970: 2_000_000)

        let card = Card()
        card.date = existingDate
        card.createdDate = existingCreated

        // Record without date/createdDate fields
        let record = makeRecord(for: card.id)

        CloudSyncRecordMapper.applyRecord(record, to: card)

        // applyRecord uses `if let` for date/createdDate → preserves existing values
        XCTAssertEqual(card.date, existingDate)
        XCTAssertEqual(card.createdDate, existingCreated)
    }

    func test_applyRecord_invalidMoodRawValue_setsNil() {
        let card = Card()
        card.mood = .happy

        let record = makeRecord(for: card.id)
        record[CloudSyncRecordMapper.RecordField.mood] = "deletedMood" as NSString

        CloudSyncRecordMapper.applyRecord(record, to: card)

        XCTAssertNil(card.mood)
    }

    func test_applyRecord_invalidWeatherRawValue_setsNil() {
        let card = Card()
        card.weatherCondition = .clear

        let record = makeRecord(for: card.id)
        record[CloudSyncRecordMapper.RecordField.weatherCondition] = "hurricane" as NSString

        CloudSyncRecordMapper.applyRecord(record, to: card)

        XCTAssertNil(card.weatherCondition)
    }

    func test_applyRecord_visionTagsWithUnknownValues_skipsInvalid() {
        let card = Card()

        let record = makeRecord(for: card.id)
        record[CloudSyncRecordMapper.RecordField.visionTags] = ["person", "alien", "sky", "robot"] as NSArray

        CloudSyncRecordMapper.applyRecord(record, to: card)

        XCTAssertEqual(Array(card.visionTags), [.person, .sky])
    }

    func test_applyRecord_emptyVisionTags_clearsExisting() {
        let card = Card()
        card.visionTags.append(objectsIn: [.person, .cat, .dog])

        let record = makeRecord(for: card.id)
        record[CloudSyncRecordMapper.RecordField.visionTags] = [] as NSArray

        CloudSyncRecordMapper.applyRecord(record, to: card)

        XCTAssertTrue(card.visionTags.isEmpty)
    }

    func test_applyRecord_boolFieldsMissing_defaultsToFalse() {
        let card = Card()
        card.isLocked = true
        card.isFavorite = true

        // Record without isLocked/isFavorite fields
        let record = makeRecord(for: card.id)

        CloudSyncRecordMapper.applyRecord(record, to: card)

        XCTAssertFalse(card.isLocked)
        XCTAssertFalse(card.isFavorite)
    }
}
