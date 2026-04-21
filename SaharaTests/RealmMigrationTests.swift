import XCTest
import RealmSwift
@testable import Sahara

// v1.6.1 시점의 Card 스키마(schemaVersion 2)를 재현하는 legacy 모델.
// editedImageData가 non-optional Data — v2.0.0에서 Data?로 변경되었음.
// @objc 명시는 RealmSwift가 private/nested 클래스의 Obj-C name mangling을 거부하기 때문에 필요.
@objc(LegacyCardV2)
private final class LegacyCardV2: Object {
    override class func _realmObjectName() -> String? { "Card" }

    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted(indexed: true) var date: Date
    @Persisted var createdDate: Date
    @Persisted var editedImageData: Data = Data()
    @Persisted var isLocked: Bool = false
    @Persisted var isFavorite: Bool = false
}

final class RealmMigrationTests: XCTestCase {

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

        RealmService.migrateRealmFileIfNeeded(
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

        RealmService.migrateRealmFileIfNeeded(
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

        RealmService.migrateRealmFileIfNeeded(
            documentsDir: fakeDocuments,
            appSupportDir: fakeAppSupport
        )

        XCTAssertFalse(fm.fileExists(atPath: oldRealmURL.path), "Old file should be removed")
        XCTAssertTrue(fm.fileExists(atPath: newRealmURL.path), "New file should be preserved")

        let preservedData = try Data(contentsOf: newRealmURL)
        XCTAssertEqual(preservedData, newData, "New location file should keep its original content")
    }

    // MARK: - Schema v2 → v3 Migration Tests

    private func makeTempRealmURL(tag: String) -> URL {
        return FileManager.default.temporaryDirectory
            .appendingPathComponent("realm-\(tag)-\(UUID().uuidString).realm")
    }

    // Realm Swift는 스키마 캐시를 fileURL 기준으로 유지하므로,
    // 같은 프로세스에서 v2로 연 URL을 v3로 다시 열면 첫 번째 objectTypes에 고정됨.
    // 따라서 v2 파일을 별도 URL로 복사하여 v3 Realm이 신선한 스키마 캐시로 열리도록 한다.
    private func runMigrationScenario(editedImageData: Data, cardId: ObjectId) throws -> Card? {
        let v2URL = makeTempRealmURL(tag: "v2")
        let v3URL = makeTempRealmURL(tag: "v3")
        addTeardownBlock {
            try? FileManager.default.removeItem(at: v2URL)
            try? FileManager.default.removeItem(at: v3URL)
        }

        try autoreleasepool {
            var v2Config = Realm.Configuration()
            v2Config.fileURL = v2URL
            v2Config.schemaVersion = 2
            v2Config.objectTypes = [LegacyCardV2.self]

            let realm = try Realm(configuration: v2Config)
            try realm.write {
                let card = LegacyCardV2()
                card.id = cardId
                card.date = Date()
                card.createdDate = Date()
                card.editedImageData = editedImageData
                realm.add(card)
            }
        }

        try FileManager.default.copyItem(at: v2URL, to: v3URL)

        var v3Config = Realm.Configuration()
        v3Config.fileURL = v3URL
        v3Config.schemaVersion = 3
        v3Config.migrationBlock = RealmService.defaultMigrationBlock
        v3Config.objectTypes = [Card.self, Sticker.self]

        let migratedRealm = try Realm(configuration: v3Config)
        return migratedRealm.object(ofType: Card.self, forPrimaryKey: cardId)
    }

    func test_schemaV2ToV3_preservesEditedImageData() throws {
        let originalData = Data("test-image-bytes-for-migration".utf8)
        let cardId = ObjectId.generate()

        let card = try runMigrationScenario(editedImageData: originalData, cardId: cardId)

        guard let card = card else {
            XCTFail("Card should exist after v2→v3 migration")
            return
        }

        XCTAssertNotNil(card.editedImageData, "editedImageData should be preserved (not nil) after nullability change")
        XCTAssertEqual(card.editedImageData, originalData, "editedImageData content must match the v2 original")
        XCTAssertNil(card.imagePath, "New imagePath field should default to nil")
    }

    func test_schemaV2ToV3_preservesLargeEditedImageData() throws {
        // 5MB — 실 사용자 고해상도 HEIC/JPEG 크기에 가까운 데이터.
        let largeData = Data(repeating: 0xAB, count: 5 * 1024 * 1024)
        let cardId = ObjectId.generate()

        let card = try runMigrationScenario(editedImageData: largeData, cardId: cardId)

        guard let card = card else {
            XCTFail("Card should exist after v2→v3 migration (large data case)")
            return
        }

        XCTAssertEqual(card.editedImageData?.count, largeData.count, "Large editedImageData byte count should be preserved")
        XCTAssertEqual(card.editedImageData, largeData, "Large editedImageData content should match byte-for-byte")
    }
}
