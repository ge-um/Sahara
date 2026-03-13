import XCTest
@testable import Sahara

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
}
