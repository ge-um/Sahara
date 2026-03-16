//
//  CloudSyncImageHandler.swift
//  Sahara
//

import CloudKit
import Foundation
import OSLog
import RealmSwift

enum CloudSyncImageHandler {
    private static let logger = Logger.syncImage

    static func createAsset(for card: Card, imageFileService: ImageFileServiceProtocol) -> CKAsset? {
        guard let imagePath = card.imagePath else { return nil }
        let fileURL = imageFileService.imageFileURL(for: imagePath)
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            logger.warning("Image file not found for upload: \(imagePath)")
            return nil
        }
        return CKAsset(fileURL: fileURL)
    }

    static func saveAssetToDisk(
        _ asset: CKAsset,
        cardId: ObjectId,
        format: String?,
        imageFileService: ImageFileServiceProtocol
    ) -> String? {
        guard let fileURL = asset.fileURL,
              let data = try? Data(contentsOf: fileURL) else {
            logger.error("Failed to read CKAsset data for card \(cardId.stringValue)")
            return nil
        }

        let resolvedFormat = format ?? "jpeg"
        do {
            let fileName = try imageFileService.saveImageFile(
                data: data,
                cardId: cardId,
                format: resolvedFormat
            )
            logger.info("Saved cloud image to disk: \(fileName)")
            return fileName
        } catch {
            logger.error("Failed to save cloud image: \(error.localizedDescription)")
            return nil
        }
    }
}
