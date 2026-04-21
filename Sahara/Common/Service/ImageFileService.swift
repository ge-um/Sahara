//
//  ImageFileService.swift
//  Sahara
//
//  Created by 금가경 on 3/6/26.
//

import Foundation
import OSLog
import RealmSwift

protocol ImageFileServiceProtocol {
    func saveImageFile(data: Data, cardId: ObjectId, format: String) throws -> String
    func loadImageFile(at relativePath: String) -> Data?
    func deleteImageFile(at relativePath: String)
    func imageFileURL(for relativePath: String) -> URL
    func cleanOrphanedFiles(referencedPaths: Set<String>)
}

final class ImageFileService: ImageFileServiceProtocol {
    static var shared = ImageFileService()

    private let baseDirectory: URL
    private let fileManager = FileManager.default
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Sahara", category: "ImageFileService")

    init(baseDirectory: URL? = nil) {
        if let baseDirectory = baseDirectory {
            self.baseDirectory = baseDirectory
        } else {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            self.baseDirectory = appSupport.appendingPathComponent("CardImages", isDirectory: true)
        }

        try? fileManager.createDirectory(at: self.baseDirectory, withIntermediateDirectories: true)
    }

    func saveImageFile(data: Data, cardId: ObjectId, format: String) throws -> String {
        let fileName = "\(cardId.stringValue).\(format)"
        let fileURL = baseDirectory.appendingPathComponent(fileName)
        try data.write(to: fileURL, options: .atomic)
        return fileName
    }

    func loadImageFile(at relativePath: String) -> Data? {
        let fileURL = baseDirectory.appendingPathComponent(relativePath)
        return try? Data(contentsOf: fileURL)
    }

    func deleteImageFile(at relativePath: String) {
        let fileURL = baseDirectory.appendingPathComponent(relativePath)
        try? fileManager.removeItem(at: fileURL)
    }

    func imageFileURL(for relativePath: String) -> URL {
        return baseDirectory.appendingPathComponent(relativePath)
    }

    func cleanOrphanedFiles(referencedPaths: Set<String>) {
        guard let files = try? fileManager.contentsOfDirectory(
            at: baseDirectory,
            includingPropertiesForKeys: nil
        ) else { return }

        for fileURL in files {
            let fileName = fileURL.lastPathComponent
            if !referencedPaths.contains(fileName) {
                try? fileManager.removeItem(at: fileURL)
                logger.info("Removed orphaned image: \(fileName)")
            }
        }
    }
}
