import XCTest
import RealmSwift
import ZIPFoundation
@testable import Sahara

final class BackupServiceTests: XCTestCase {
    var tempDir: URL!
    var testRealmURL: URL!
    var testImagesDir: URL!
    var backupManager: BackupService!

    override func setUpWithError() throws {
        try super.setUpWithError()

        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("backup-test-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        testRealmURL = tempDir.appendingPathComponent("default.realm")
        testImagesDir = tempDir.appendingPathComponent("CardImages")
        try FileManager.default.createDirectory(at: testImagesDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        backupManager = nil
        if let tempDir = tempDir {
            try? FileManager.default.removeItem(at: tempDir)
        }
        tempDir = nil
        testRealmURL = nil
        testImagesDir = nil
        try super.tearDownWithError()
    }

    // MARK: - Validate Tests

    /// 올바른 구조의 백업 ZIP에서 metadata를 정상 파싱하는지 검증.
    /// schemaVersion, cardCount 등이 저장한 값과 일치해야 한다.
    func test_validateBackup_validFile_returnsMetadata() throws {
        let archiveURL = try createTestBackupArchive(
            schemaVersion: RealmService.currentSchemaVersion,
            cardCount: 5
        )

        let metadata = try BackupService.shared.validateBackup(at: archiveURL)

        XCTAssertEqual(metadata.schemaVersion, RealmService.currentSchemaVersion)
        XCTAssertEqual(metadata.cardCount, 5)
        XCTAssertFalse(metadata.appVersion.isEmpty)
    }

    /// metadata.json이 없는 일반 ZIP 파일을 .sahara로 변경했을 때 거부하는지 검증.
    /// 사용자가 임의의 ZIP을 .sahara로 변경한 경우를 대비.
    func test_validateBackup_missingMetadata_throwsError() throws {
        let archiveURL = tempDir.appendingPathComponent("invalid.sahara")
        let archive = try Archive(url: archiveURL, accessMode: .create)

        let dummyData = Data("dummy".utf8)
        try archive.addEntry(with: "some_file.txt", type: .file, uncompressedSize: Int64(dummyData.count)) { position, size in
            dummyData.subdata(in: Int(position)..<Int(position)+size)
        }

        XCTAssertThrowsError(try BackupService.shared.validateBackup(at: archiveURL)) { error in
            guard let backupError = error as? BackupError else {
                XCTFail("Expected BackupError, got \(error)")
                return
            }
            if case .missingMetadata = backupError {
                // Expected
            } else {
                XCTFail("Expected missingMetadata, got \(backupError)")
            }
        }
    }

    /// 앱 다운그레이드 후 이전(상위 스키마) 백업을 복원하려 할 때 거부하는지 검증.
    /// Realm은 역마이그레이션을 지원하지 않으므로 상위 스키마 백업은 열 수 없다.
    func test_validateBackup_futureSchemaVersion_throwsError() throws {
        let futureVersion = RealmService.currentSchemaVersion + 10
        let archiveURL = try createTestBackupArchive(
            schemaVersion: futureVersion,
            cardCount: 1
        )

        XCTAssertThrowsError(try BackupService.shared.validateBackup(at: archiveURL)) { error in
            guard let backupError = error as? BackupError else {
                XCTFail("Expected BackupError, got \(error)")
                return
            }
            if case .incompatibleSchemaVersion(let backup, let current) = backupError {
                XCTAssertEqual(backup, futureVersion)
                XCTAssertEqual(current, RealmService.currentSchemaVersion)
            } else {
                XCTFail("Expected incompatibleSchemaVersion, got \(backupError)")
            }
        }
    }

    /// metadata.json은 있지만 default.realm이 없는 ZIP을 거부하는지 검증.
    /// 손상되거나 불완전한 백업 파일 대비.
    func test_validateBackup_missingRealm_throwsError() throws {
        let archiveURL = tempDir.appendingPathComponent("no-realm.sahara")
        let archive = try Archive(url: archiveURL, accessMode: .create)

        let metadata = BackupMetadata(
            appVersion: "1.0.0",
            schemaVersion: RealmService.currentSchemaVersion,
            cardCount: 0,
            createdAt: Date(),
            deviceModel: "test"
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let metadataData = try encoder.encode(metadata)

        try archive.addEntry(with: "metadata.json", type: .file, uncompressedSize: Int64(metadataData.count)) { position, size in
            metadataData.subdata(in: Int(position)..<Int(position)+size)
        }

        XCTAssertThrowsError(try BackupService.shared.validateBackup(at: archiveURL)) { error in
            guard let backupError = error as? BackupError else {
                XCTFail("Expected BackupError, got \(error)")
                return
            }
            if case .missingRealmFile = backupError {
                // Expected
            } else {
                XCTFail("Expected missingRealmFile, got \(backupError)")
            }
        }
    }

    /// BackupMetadata.create()가 현재 앱 정보를 올바르게 캡처하는지 검증.
    /// 앱 버전, 스키마 버전, 디바이스 모델이 비어있지 않아야 한다.
    func test_backupMetadata_create_capturesCurrentInfo() {
        let metadata = BackupMetadata.create(cardCount: 42)

        XCTAssertEqual(metadata.schemaVersion, RealmService.currentSchemaVersion)
        XCTAssertEqual(metadata.cardCount, 42)
        XCTAssertFalse(metadata.deviceModel.isEmpty)
    }

    // MARK: - Helpers

    private func createTestBackupArchive(schemaVersion: UInt64, cardCount: Int) throws -> URL {
        let archiveURL = tempDir.appendingPathComponent("test-backup-\(UUID().uuidString).sahara")
        let archive = try Archive(url: archiveURL, accessMode: .create)

        let metadata = BackupMetadata(
            appVersion: "2.0.0",
            schemaVersion: schemaVersion,
            cardCount: cardCount,
            createdAt: Date(),
            deviceModel: "TestDevice"
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let metadataData = try encoder.encode(metadata)

        try archive.addEntry(with: "metadata.json", type: .file, uncompressedSize: Int64(metadataData.count)) { position, size in
            metadataData.subdata(in: Int(position)..<Int(position)+size)
        }

        let realmData = Data("fake-realm-data".utf8)
        try archive.addEntry(with: "default.realm", type: .file, uncompressedSize: Int64(realmData.count)) { position, size in
            realmData.subdata(in: Int(position)..<Int(position)+size)
        }

        return archiveURL
    }
}
