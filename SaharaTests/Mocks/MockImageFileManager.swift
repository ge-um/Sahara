//
//  MockImageFileManager.swift
//  SaharaTests
//
//  Created by 금가경 on 3/6/26.
//

import Foundation
import RealmSwift
@testable import Sahara

final class MockImageFileManager: ImageFileManagerProtocol {
    var savedFiles: [String: Data] = [:]
    var deletedPaths: [String] = []
    var shouldThrowOnSave = false

    func saveImageFile(data: Data, cardId: ObjectId, format: String) throws -> String {
        if shouldThrowOnSave {
            throw NSError(domain: "MockError", code: -1)
        }
        let fileName = "\(cardId.stringValue).\(format)"
        savedFiles[fileName] = data
        return fileName
    }

    func loadImageFile(at relativePath: String) -> Data? {
        return savedFiles[relativePath]
    }

    func deleteImageFile(at relativePath: String) {
        savedFiles[relativePath] = nil
        deletedPaths.append(relativePath)
    }

    func imageFileURL(for relativePath: String) -> URL {
        return URL(fileURLWithPath: "/tmp/mock/\(relativePath)")
    }
}
