//
//  MockImageFileService.swift
//  SaharaTests
//

import Foundation
import RealmSwift
@testable import Sahara

final class MockImageFileService: ImageFileServiceProtocol {
    private var storage: [String: Data] = [:]

    var shouldFailSave = false
    var lastSavedFormat: String?
    var lastSavedCardId: ObjectId?
    var saveCalled = false

    func saveImageFile(data: Data, cardId: ObjectId, format: String) throws -> String {
        saveCalled = true
        lastSavedCardId = cardId
        lastSavedFormat = format

        if shouldFailSave {
            throw NSError(domain: "MockError", code: -1)
        }

        let fileName = "\(cardId.stringValue).\(format)"
        storage[fileName] = data
        return fileName
    }

    func loadImageFile(at relativePath: String) -> Data? {
        storage[relativePath]
    }

    func deleteImageFile(at relativePath: String) {
        storage.removeValue(forKey: relativePath)
    }

    func imageFileURL(for relativePath: String) -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent(relativePath)
    }

    func cleanOrphanedFiles(referencedPaths: Set<String>) {}

    func reset() {
        storage = [:]
        shouldFailSave = false
        lastSavedFormat = nil
        lastSavedCardId = nil
        saveCalled = false
    }
}
