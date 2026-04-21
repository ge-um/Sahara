//
//  SaharaWidget.swift
//  SaharaWidget
//
//  Created by 금가경 on 3/11/26.
//

import SwiftUI
import WidgetKit

struct SaharaWidgetEntry: TimelineEntry {
    let date: Date
    let cardId: String?
    let cardDate: Date?
    let memo: String?
    let thumbnailImage: Image?
    let isOnThisDay: Bool
    let isEmpty: Bool
    let navigableCardCount: Int
}

struct SaharaWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> SaharaWidgetEntry {
        let imageName = context.family == .systemLarge ? "WidgetPreview2" : "WidgetPreview1"
        return SaharaWidgetEntry(
            date: Date(),
            cardId: nil,
            cardDate: nil,
            memo: NSLocalizedString("widget.placeholder_memo", comment: ""),
            thumbnailImage: Image(imageName),
            isOnThisDay: false,
            isEmpty: false,
            navigableCardCount: 0
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (SaharaWidgetEntry) -> Void) {
        let imageName = context.family == .systemLarge ? "WidgetPreview2" : "WidgetPreview1"

        let previewEntry = SaharaWidgetEntry(
            date: Date(),
            cardId: nil,
            cardDate: nil,
            memo: nil,
            thumbnailImage: loadPreviewImage(named: imageName),
            isOnThisDay: false,
            isEmpty: false,
            navigableCardCount: 0
        )
        completion(previewEntry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SaharaWidgetEntry>) -> Void) {
        let entry = loadEntry()
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 4, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadEntry() -> SaharaWidgetEntry {
        let entries = loadCardEntries()
        let navigableCards = entries.filter { $0.thumbnailFileName != nil }
        let navigableCount = navigableCards.count

        guard let pinnedId = AppGroupContainer.pinnedCardId else {
            return SaharaWidgetEntry(
                date: Date(),
                cardId: nil,
                cardDate: nil,
                memo: nil,
                thumbnailImage: nil,
                isOnThisDay: false,
                isEmpty: true,
                navigableCardCount: navigableCount
            )
        }

        let targetEntry: WidgetCardEntry
        if let pinned = entries.first(where: { $0.cardId == pinnedId }) {
            targetEntry = pinned
        } else if let fallback = navigableCards.first {
            AppGroupContainer.pinnedCardId = fallback.cardId
            targetEntry = fallback
        } else {
            return SaharaWidgetEntry(
                date: Date(),
                cardId: nil,
                cardDate: nil,
                memo: nil,
                thumbnailImage: nil,
                isOnThisDay: false,
                isEmpty: true,
                navigableCardCount: navigableCount
            )
        }

        let thumbnail: Image?
        if let fileName = targetEntry.thumbnailFileName,
           let uiImage = loadThumbnail(fileName: fileName) {
            thumbnail = Image(uiImage: uiImage)
        } else {
            thumbnail = nil
        }

        return SaharaWidgetEntry(
            date: Date(),
            cardId: targetEntry.cardId,
            cardDate: targetEntry.date,
            memo: targetEntry.memo,
            thumbnailImage: thumbnail,
            isOnThisDay: false,
            isEmpty: false,
            navigableCardCount: navigableCount
        )
    }

    private func loadCardEntries() -> [WidgetCardEntry] {
        guard let storeURL = AppGroupContainer.cardStoreURL,
              let data = try? Data(contentsOf: storeURL) else {
            return []
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([WidgetCardEntry].self, from: data)) ?? []
    }

    private func loadThumbnail(fileName: String) -> UIImage? {
        guard let thumbsDir = AppGroupContainer.thumbnailsDirectory else { return nil }
        let url = thumbsDir.appendingPathComponent(fileName)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    private func loadPreviewImage(named name: String) -> Image {
        Image(name)
    }
}

struct SaharaWidget: Widget {
    let kind = "SaharaWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SaharaWidgetProvider()) { entry in
            WidgetEntryView(entry: entry)
                .containerBackground(for: .widget) { Color.clear }
        }
        .configurationDisplayName(NSLocalizedString("widget.display_name", comment: ""))
        .description(NSLocalizedString("widget.description", comment: ""))
        .supportedFamilies([.systemSmall, .systemLarge])
        .contentMarginsDisabled()
    }
}
