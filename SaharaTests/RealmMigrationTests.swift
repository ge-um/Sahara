import XCTest
import RealmSwift
@testable import Sahara

final class RealmMigrationTests: XCTestCase {
    var testRealmURL: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        testRealmURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test-\(UUID().uuidString).realm")
    }

    override func tearDownWithError() throws {
        if let url = testRealmURL {
            let realmFiles = [
                url,
                url.deletingPathExtension().appendingPathExtension("lock"),
                url.deletingPathExtension().appendingPathExtension("note"),
                url.deletingPathExtension().appendingPathExtension("management")
            ]

            for file in realmFiles {
                try? FileManager.default.removeItem(at: file)
            }
        }

        testRealmURL = nil
        try super.tearDownWithError()
    }

    func testCurrentSchemaVersion() throws {
        let currentVersion = RealmManager.currentSchemaVersion
        XCTAssertEqual(currentVersion, 3)
    }

    func testCreateAndReadCardV2() throws {
        let config = Realm.Configuration(
            fileURL: testRealmURL,
            schemaVersion: 1,
            objectTypes: [Card.self, Sticker.self]
        )

        try autoreleasepool {
            let realm = try Realm(configuration: config)

            let testDate = Date()
            let testImageData = Data([0x01, 0x02, 0x03])

            try realm.write {
                let card = Card(
                    date: testDate,
                    createdDate: testDate,
                    editedImageData: testImageData,
                    memo: "Test memo"
                )
                card.customFolder = "TestFolder"
                card.ocrText = "Test OCR"
                card.weatherCondition = .clear
                realm.add(card)
            }

            let cards = realm.objects(Card.self)
            XCTAssertEqual(cards.count, 1)

            let card = cards.first!
            XCTAssertEqual(card.date.timeIntervalSince1970, testDate.timeIntervalSince1970, accuracy: 1.0)
            XCTAssertEqual(card.createdDate.timeIntervalSince1970, testDate.timeIntervalSince1970, accuracy: 1.0)
            XCTAssertEqual(card.editedImageData, testImageData)
            XCTAssertEqual(card.memo, "Test memo")
            XCTAssertEqual(card.customFolder, "TestFolder")
            XCTAssertEqual(card.ocrText, "Test OCR")
            XCTAssertEqual(card.weatherCondition, .clear)
        }
    }

    func testInMemoryRealm() throws {
        let config = Realm.Configuration(
            inMemoryIdentifier: UUID().uuidString,
            schemaVersion: 1,
            objectTypes: [Card.self, Sticker.self]
        )

        try autoreleasepool {
            let realm = try Realm(configuration: config)

            let testDate = Date()
            let testImageData = Data([0x01, 0x02, 0x03])

            try realm.write {
                let card = Card(
                    date: testDate,
                    createdDate: testDate,
                    editedImageData: testImageData
                )
                realm.add(card)
            }

            let cards = realm.objects(Card.self)
            XCTAssertEqual(cards.count, 1)
        }
    }

    func testRealmManagerConfiguration() throws {
        let config = RealmManager.createConfiguration(schemaVersion: 1)

        XCTAssertEqual(config.schemaVersion, 1)
        XCTAssertNotNil(config.migrationBlock)
    }
}
