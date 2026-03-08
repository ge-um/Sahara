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

    // MARK: - Realm File Migration Tests

    private func makeTempDir() throws -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("realm-migration-test-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    func test_migrateRealmFile_movesFromDocumentsToAppSupport() throws {
        let fm = FileManager.default
        let fakeDocuments = try makeTempDir()
        let fakeAppSupport = try makeTempDir()

        defer {
            try? fm.removeItem(at: fakeDocuments)
            try? fm.removeItem(at: fakeAppSupport)
        }

        let oldRealmURL = fakeDocuments.appendingPathComponent("default.realm")
        let oldLockURL = fakeDocuments.appendingPathComponent("default.lock")
        let oldManagementURL = fakeDocuments.appendingPathComponent("default.management")
        let testData = Data("test-realm-data".utf8)

        try testData.write(to: oldRealmURL)
        try Data().write(to: oldLockURL)
        try Data().write(to: oldManagementURL)

        RealmManager.migrateRealmFileIfNeeded(
            documentsDir: fakeDocuments,
            appSupportDir: fakeAppSupport
        )

        let newRealmURL = fakeAppSupport.appendingPathComponent("default.realm")
        XCTAssertTrue(fm.fileExists(atPath: newRealmURL.path), "Realm file should exist at new location")
        XCTAssertFalse(fm.fileExists(atPath: oldRealmURL.path), "Realm file should not exist at old location")
        XCTAssertFalse(fm.fileExists(atPath: oldLockURL.path), "Lock file should be cleaned up")
        XCTAssertFalse(fm.fileExists(atPath: oldManagementURL.path), "Management file should be cleaned up")

        let migratedData = try Data(contentsOf: newRealmURL)
        XCTAssertEqual(migratedData, testData, "Migrated file content should match original")
    }

    func test_migrateRealmFile_noFileInDocuments_doesNothing() throws {
        let fm = FileManager.default
        let fakeDocuments = try makeTempDir()
        let fakeAppSupport = try makeTempDir()

        defer {
            try? fm.removeItem(at: fakeDocuments)
            try? fm.removeItem(at: fakeAppSupport)
        }

        RealmManager.migrateRealmFileIfNeeded(
            documentsDir: fakeDocuments,
            appSupportDir: fakeAppSupport
        )

        let newRealmURL = fakeAppSupport.appendingPathComponent("default.realm")
        XCTAssertFalse(fm.fileExists(atPath: newRealmURL.path), "No file should be created when source doesn't exist")
    }

    func test_migrateRealmFile_fileAlreadyAtNewLocation_removesOldFile() throws {
        let fm = FileManager.default
        let fakeDocuments = try makeTempDir()
        let fakeAppSupport = try makeTempDir()

        defer {
            try? fm.removeItem(at: fakeDocuments)
            try? fm.removeItem(at: fakeAppSupport)
        }

        let oldRealmURL = fakeDocuments.appendingPathComponent("default.realm")
        let newRealmURL = fakeAppSupport.appendingPathComponent("default.realm")
        let oldData = Data("old-data".utf8)
        let newData = Data("new-data".utf8)

        try oldData.write(to: oldRealmURL)
        try newData.write(to: newRealmURL)

        RealmManager.migrateRealmFileIfNeeded(
            documentsDir: fakeDocuments,
            appSupportDir: fakeAppSupport
        )

        XCTAssertFalse(fm.fileExists(atPath: oldRealmURL.path), "Old file should be removed")
        XCTAssertTrue(fm.fileExists(atPath: newRealmURL.path), "New file should be preserved")

        let preservedData = try Data(contentsOf: newRealmURL)
        XCTAssertEqual(preservedData, newData, "New location file should keep its original content")
    }
}
