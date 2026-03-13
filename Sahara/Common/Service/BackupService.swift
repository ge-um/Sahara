//
//  BackupService.swift
//  Sahara
//
//  Created by 금가경 on 3/8/26.
//

import Foundation
import OSLog
import RealmSwift
import ZIPFoundation

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Sahara", category: "Backup")

enum BackupError: LocalizedError {
    case invalidBackupFile
    case missingMetadata
    case missingRealmFile
    case incompatibleSchemaVersion(backup: UInt64, current: UInt64)
    case exportFailed(Error)
    case importFailed(Error)

    var errorDescription: String? {
        switch self {
        case .invalidBackupFile:
            return NSLocalizedString("backup.invalid_file", comment: "")
        case .missingMetadata:
            return NSLocalizedString("backup.invalid_file", comment: "")
        case .missingRealmFile:
            return NSLocalizedString("backup.invalid_file", comment: "")
        case .incompatibleSchemaVersion:
            return NSLocalizedString("backup.version_mismatch", comment: "")
        case .exportFailed(let error):
            return "\(NSLocalizedString("backup.export_failed", comment: "")): \(error.localizedDescription)"
        case .importFailed(let error):
            return "\(NSLocalizedString("backup.import_failed", comment: "")): \(error.localizedDescription)"
        }
    }
}

protocol BackupServiceProtocol {
    func exportPhotosOnly(progress: @escaping (Double) -> Void) throws -> URL
    func exportBackup(progress: @escaping (Double) -> Void) throws -> URL
    func validateBackup(at url: URL) throws -> BackupMetadata
    func importBackup(from url: URL, progress: @escaping (Double) -> Void) throws
}

final class BackupService: BackupServiceProtocol {
    static let shared = BackupService()

    static let backupFileExtension = "sahara"

    private let fileManager = FileManager.default
    private let realmManager: RealmServiceProtocol
    private let imageFileManager: ImageFileService

    init(
        realmManager: RealmServiceProtocol = RealmService.shared,
        imageFileManager: ImageFileService = .shared
    ) {
        self.realmManager = realmManager
        self.imageFileManager = imageFileManager
    }

    private var cardImagesDirectory: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return appSupport.appendingPathComponent("CardImages", isDirectory: true)
    }

    // MARK: - Export Photos Only

    func exportPhotosOnly(progress: @escaping (Double) -> Void) throws -> URL {
        try migrateAllLegacyImages()
        progress(0.2)

        let tempDir = fileManager.temporaryDirectory.appendingPathComponent("sahara-photos-\(UUID().uuidString)")
        try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: tempDir) }

        let archiveURL = fileManager.temporaryDirectory.appendingPathComponent("Sahara_Photos_\(Self.fileDateFormatter.string(from: Date())).zip")
        try? fileManager.removeItem(at: archiveURL)

        let archive = try Archive(url: archiveURL, accessMode: .create)

        let imageFiles = try imageFilesInDirectory()
        let totalFiles = Double(max(imageFiles.count, 1))

        for (index, fileURL) in imageFiles.enumerated() {
            try archive.addEntry(
                with: "CardImages/\(fileURL.lastPathComponent)",
                fileURL: fileURL
            )
            progress(0.2 + 0.8 * Double(index + 1) / totalFiles)
        }

        logger.notice("Photos exported: \(imageFiles.count) files")
        return archiveURL
    }

    // MARK: - Export Backup

    func exportBackup(progress: @escaping (Double) -> Void) throws -> URL {
        try migrateAllLegacyImages()
        progress(0.1)

        let tempDir = fileManager.temporaryDirectory.appendingPathComponent("sahara-backup-\(UUID().uuidString)")
        try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: tempDir) }

        let realmCopyURL = tempDir.appendingPathComponent("default.realm")
        let realm = try Realm(configuration: realmManager.createConfiguration())
        try realm.writeCopy(toFile: realmCopyURL)
        progress(0.3)

        let cardCount = realm.objects(Card.self).count

        let metadata = BackupMetadata.create(cardCount: cardCount)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        let metadataData = try encoder.encode(metadata)
        let metadataURL = tempDir.appendingPathComponent("metadata.json")
        try metadataData.write(to: metadataURL)
        progress(0.4)

        let archiveURL = fileManager.temporaryDirectory.appendingPathComponent("Sahara_\(Self.fileDateFormatter.string(from: Date())).\(Self.backupFileExtension)")
        try? fileManager.removeItem(at: archiveURL)

        let archive = try Archive(url: archiveURL, accessMode: .create)

        try archive.addEntry(with: "metadata.json", fileURL: metadataURL)
        try archive.addEntry(with: "default.realm", fileURL: realmCopyURL)

        let imageFiles = try imageFilesInDirectory()
        let totalSteps = Double(max(imageFiles.count, 1))
        for (index, imageFile) in imageFiles.enumerated() {
            try archive.addEntry(
                with: "CardImages/\(imageFile.lastPathComponent)",
                fileURL: imageFile
            )
            progress(0.4 + 0.6 * Double(index + 1) / totalSteps)
        }

        progress(1.0)
        logger.notice("Backup exported: \(cardCount) cards")
        return archiveURL
    }

    // MARK: - Validate

    func validateBackup(at url: URL) throws -> BackupMetadata {
        let archive: Archive
        do {
            archive = try Archive(url: url, accessMode: .read)
        } catch {
            throw BackupError.invalidBackupFile
        }

        guard let metadataEntry = archive["metadata.json"] else {
            throw BackupError.missingMetadata
        }

        var metadataData = Data()
        _ = try archive.extract(metadataEntry) { data in
            metadataData.append(data)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let metadata = try decoder.decode(BackupMetadata.self, from: metadataData)

        if metadata.schemaVersion > RealmService.currentSchemaVersion {
            throw BackupError.incompatibleSchemaVersion(
                backup: metadata.schemaVersion,
                current: RealmService.currentSchemaVersion
            )
        }

        guard archive["default.realm"] != nil else {
            throw BackupError.missingRealmFile
        }

        return metadata
    }

    // MARK: - Import

    func importBackup(from url: URL, progress: @escaping (Double) -> Void) throws {
        progress(0.1)

        let tempDir = fileManager.temporaryDirectory.appendingPathComponent("sahara-import-\(UUID().uuidString)")
        try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: tempDir) }

        try fileManager.unzipItem(at: url, to: tempDir)
        progress(0.3)

        let extractedRealmURL = tempDir.appendingPathComponent("default.realm")
        let extractedImagesDir = tempDir.appendingPathComponent("CardImages")

        guard fileManager.fileExists(atPath: extractedRealmURL.path) else {
            throw BackupError.missingRealmFile
        }

        var backupConfig = realmManager.createConfiguration()
        backupConfig.fileURL = extractedRealmURL
        backupConfig.readOnly = true

        let backupRealm = try Realm(configuration: backupConfig)
        let backupCards = backupRealm.objects(Card.self)
        progress(0.4)

        let currentImagesURL = cardImagesDirectory
        let imagesBackupURL = currentImagesURL.appendingPathExtension("bak")

        try? fileManager.removeItem(at: imagesBackupURL)
        if fileManager.fileExists(atPath: currentImagesURL.path) {
            try fileManager.moveItem(at: currentImagesURL, to: imagesBackupURL)
        }

        do {
            if fileManager.fileExists(atPath: extractedImagesDir.path) {
                try fileManager.moveItem(at: extractedImagesDir, to: currentImagesURL)
            } else {
                try fileManager.createDirectory(at: currentImagesURL, withIntermediateDirectories: true)
            }
            progress(0.5)

            ThumbnailCache.shared.clearAll()

            let currentRealm = try Realm(configuration: realmManager.createConfiguration())
            try currentRealm.write {
                currentRealm.deleteAll()
                for backupCard in backupCards {
                    currentRealm.create(Card.self, value: backupCard, update: .all)
                }
            }
            progress(0.8)

            try? fileManager.removeItem(at: imagesBackupURL)
            progress(1.0)

            logger.notice("Backup imported: \(backupCards.count) cards")
        } catch {
            logger.error("Import failed, restoring images: \(error.localizedDescription)")

            try? fileManager.removeItem(at: currentImagesURL)
            if fileManager.fileExists(atPath: imagesBackupURL.path) {
                try? fileManager.moveItem(at: imagesBackupURL, to: currentImagesURL)
            }

            throw BackupError.importFailed(error)
        }
    }

    // MARK: - Import Preparation

    func prepareForImport(from url: URL) throws -> (tempURL: URL, metadata: BackupMetadata) {
        let shouldAccess = url.startAccessingSecurityScopedResource()
        defer { if shouldAccess { url.stopAccessingSecurityScopedResource() } }

        let tempURL = fileManager.temporaryDirectory.appendingPathComponent(url.lastPathComponent)
        try? fileManager.removeItem(at: tempURL)
        try fileManager.copyItem(at: url, to: tempURL)
        let metadata = try validateBackup(at: tempURL)
        return (tempURL, metadata)
    }

    // MARK: - Private Helpers

    private static let fileDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return formatter
    }()

    private func migrateAllLegacyImages() throws {
        let realm = try Realm(configuration: realmManager.createConfiguration())
        let legacyCards = realm.objects(Card.self).filter("imagePath == nil AND editedImageData != nil")

        guard !legacyCards.isEmpty else { return }

        logger.notice("Migrating \(legacyCards.count) legacy images to disk")

        for card in legacyCards {
            autoreleasepool {
                guard let imageData = card.editedImageData else { return }
                let format = card.imageFormat ?? "jpeg"
                do {
                    let fileName = try ImageFileService.shared.saveImageFile(data: imageData, cardId: card.id, format: format)
                    try realm.write {
                        card.imagePath = fileName
                        card.editedImageData = nil
                    }
                } catch {
                    logger.error("Legacy migration failed for card \(card.id): \(error.localizedDescription)")
                }
            }
        }
    }

    private func imageFilesInDirectory() throws -> [URL] {
        guard fileManager.fileExists(atPath: cardImagesDirectory.path) else { return [] }
        return try fileManager.contentsOfDirectory(at: cardImagesDirectory, includingPropertiesForKeys: nil)
    }

}
