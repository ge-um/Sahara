//
//  WidgetDataService.swift
//  Sahara
//
//  Created by 금가경 on 3/11/26.
//

import Foundation
import OSLog
import UIKit
import WidgetKit

final class WidgetDataService {
    static let shared = WidgetDataService()

    private let realmManager: RealmServiceProtocol
    private let widgetDirectory: URL?
    private let thumbnailsDirectory: URL?
    private let cardStoreURL: URL?
    private let queue = DispatchQueue(label: "com.sahara.widgetData", qos: .utility)

    init(
        realmManager: RealmServiceProtocol = RealmService.shared,
        widgetDirectory: URL? = AppGroupContainer.widgetDirectory,
        thumbnailsDirectory: URL? = AppGroupContainer.thumbnailsDirectory,
        cardStoreURL: URL? = AppGroupContainer.cardStoreURL
    ) {
        self.realmManager = realmManager
        self.widgetDirectory = widgetDirectory
        self.thumbnailsDirectory = thumbnailsDirectory
        self.cardStoreURL = cardStoreURL
    }

    func refreshWidgetData(completion: (() -> Void)? = nil) {
        guard widgetDirectory != nil else {
            completion?()
            return
        }
        queue.async { [weak self] in
            self?.performRefresh()
            completion?()
        }
    }

    private func performRefresh() {
        guard let widgetDir = widgetDirectory,
              let thumbsDir = thumbnailsDirectory,
              let storeURL = cardStoreURL else { return }

        let fm = FileManager.default
        try? fm.createDirectory(at: widgetDir, withIntermediateDirectories: true)
        try? fm.createDirectory(at: thumbsDir, withIntermediateDirectories: true)

        let cards = realmManager.fetch(Card.self, filter: "isLocked == false", sortKey: "date", ascending: false)

        let calendar = Calendar.current
        var allEntries: [WidgetCardEntry] = []
        var cardLookup: [String: Card] = [:]

        for card in cards {
            let cardId = card.id.stringValue
            let components = calendar.dateComponents([.month, .day], from: card.date)
            guard let month = components.month, let day = components.day else { continue }

            allEntries.append(WidgetCardEntry(
                cardId: cardId,
                date: card.date,
                memo: card.memo,
                monthDay: .init(month: month, day: day),
                thumbnailFileName: nil
            ))
            cardLookup[cardId] = card
        }

        var validFileNames: Set<String> = []

        if let pinnedId = AppGroupContainer.pinnedCardId,
           let card = cardLookup[pinnedId],
           let index = allEntries.firstIndex(where: { $0.cardId == pinnedId }) {
            let entry = allEntries[index]
            let fileName: String
            if let cached = existingThumbnailFileName(cardId: pinnedId, directory: thumbsDir) {
                fileName = cached
            } else if let imageData = card.resolvedImageData(),
                      let generated = generateThumbnail(cardId: pinnedId, imageData: imageData, directory: thumbsDir) {
                fileName = generated
            } else {
                fileName = ""
            }

            if !fileName.isEmpty {
                validFileNames.insert(fileName)
                allEntries[index] = WidgetCardEntry(
                    cardId: entry.cardId,
                    date: entry.date,
                    memo: entry.memo,
                    monthDay: entry.monthDay,
                    thumbnailFileName: fileName
                )
            }
        }

        for (index, entry) in allEntries.enumerated() where entry.thumbnailFileName == nil {
            if let cached = existingThumbnailFileName(cardId: entry.cardId, directory: thumbsDir) {
                validFileNames.insert(cached)
                allEntries[index] = WidgetCardEntry(
                    cardId: entry.cardId,
                    date: entry.date,
                    memo: entry.memo,
                    monthDay: entry.monthDay,
                    thumbnailFileName: cached
                )
            }
        }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(allEntries) {
            try? data.write(to: storeURL, options: .atomic)
        }

        cleanupOrphanedThumbnails(in: thumbsDir, validFileNames: validFileNames)

        reloadWidgetTimelines()
    }

    private func existingThumbnailFileName(cardId: String, directory: URL) -> String? {
        for ext in ["jpg", "png"] {
            let name = "\(cardId)_widget.\(ext)"
            let url = directory.appendingPathComponent(name)
            if FileManager.default.fileExists(atPath: url.path) {
                return name
            }
        }
        return nil
    }

    private func generateThumbnail(cardId: String, imageData: Data, directory: URL) -> String? {
        guard let thumbnail = ImageDownsampler.downsample(data: imageData, maxDimension: 800) else {
            return nil
        }

        let hasAlpha = thumbnail.hasAlphaChannel
        let ext = hasAlpha ? "png" : "jpg"
        let fileName = "\(cardId)_widget.\(ext)"
        let fileURL = directory.appendingPathComponent(fileName)

        let thumbnailData: Data?
        if hasAlpha {
            thumbnailData = thumbnail.pngData()
        } else {
            thumbnailData = thumbnail.jpegData(compressionQuality: 0.7)
        }

        guard let data = thumbnailData else { return nil }

        do {
            try data.write(to: fileURL, options: .atomic)
            return fileName
        } catch {
            return nil
        }
    }

    private func reloadWidgetTimelines() {
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func cleanupOrphanedThumbnails(in directory: URL, validFileNames: Set<String>) {
        guard let files = try? FileManager.default.contentsOfDirectory(atPath: directory.path) else { return }
        for file in files where !validFileNames.contains(file) {
            try? FileManager.default.removeItem(at: directory.appendingPathComponent(file))
        }
    }
}
