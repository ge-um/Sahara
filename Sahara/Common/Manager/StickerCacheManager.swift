//
//  StickerCacheManager.swift
//  Sahara
//
//  Created by 금가경 on 11/26/25.
//

import Foundation
import RealmSwift

struct StickerCacheManager {
    static let stickerDirectory: URL = {
        let appSupportDir = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0]
        let stickerDir = appSupportDir.appendingPathComponent("Stickers")
        try? FileManager.default.createDirectory(
            at: stickerDir,
            withIntermediateDirectories: true
        )
        return stickerDir
    }()

    static func save(imageData: Data, format: String) -> String? {
        let filename = "\(UUID().uuidString).\(format)"
        let filePath = stickerDirectory.appendingPathComponent(filename)

        do {
            try imageData.write(to: filePath)
            return filePath.path
        } catch {
            return nil
        }
    }

    static func load(from path: String) -> Data? {
        return try? Data(contentsOf: URL(fileURLWithPath: path))
    }

    static func totalCacheSize() -> Int64 {
        let files = try? FileManager.default.contentsOfDirectory(
            at: stickerDirectory,
            includingPropertiesForKeys: [.fileSizeKey]
        )

        return files?.reduce(0) { size, fileURL in
            let fileSize = (try? fileURL.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
            return size + Int64(fileSize)
        } ?? 0
    }

    static func cleanUnusedStickers() {
        let realm = try! Realm()
        let allCards = realm.objects(Card.self)

        var activePaths = Set<String>()
        for card in allCards {
            for sticker in card.stickers {
                if let path = sticker.localFilePath {
                    activePaths.insert(path)
                }
            }
        }

        let allFiles = try? FileManager.default.contentsOfDirectory(
            at: stickerDirectory,
            includingPropertiesForKeys: nil
        )
        allFiles?.forEach { fileURL in
            if !activePaths.contains(fileURL.path) {
                try? FileManager.default.removeItem(at: fileURL)
            }
        }
    }
}
