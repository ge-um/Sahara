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
    let thumbnailImage: UIImage?
    let isOnThisDay: Bool
    let isEmpty: Bool
}

struct SaharaWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> SaharaWidgetEntry {
        SaharaWidgetEntry(
            date: Date(),
            cardId: nil,
            cardDate: nil,
            memo: NSLocalizedString("widget.placeholder_memo", comment: ""),
            thumbnailImage: nil,
            isOnThisDay: false,
            isEmpty: false
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (SaharaWidgetEntry) -> Void) {
        let entry = loadEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SaharaWidgetEntry>) -> Void) {
        let entry = loadEntry()
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 4, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadEntry() -> SaharaWidgetEntry {
        let entries = loadCardEntries()

        guard let selected = OnThisDaySelector.select(from: entries) else {
            return SaharaWidgetEntry(
                date: Date(),
                cardId: nil,
                cardDate: nil,
                memo: nil,
                thumbnailImage: nil,
                isOnThisDay: false,
                isEmpty: true
            )
        }

        if let fileName = selected.entry.thumbnailFileName,
           let thumbnail = loadThumbnail(fileName: fileName) {
            return SaharaWidgetEntry(
                date: Date(),
                cardId: selected.entry.cardId,
                cardDate: selected.entry.date,
                memo: selected.entry.memo,
                thumbnailImage: thumbnail,
                isOnThisDay: selected.isOnThisDay,
                isEmpty: false
            )
        }

        let entriesWithThumbnails = entries.filter { $0.thumbnailFileName != nil }
        if let fallback = OnThisDaySelector.select(from: entriesWithThumbnails),
           let fileName = fallback.entry.thumbnailFileName,
           let thumbnail = loadThumbnail(fileName: fileName) {
            return SaharaWidgetEntry(
                date: Date(),
                cardId: fallback.entry.cardId,
                cardDate: fallback.entry.date,
                memo: fallback.entry.memo,
                thumbnailImage: thumbnail,
                isOnThisDay: fallback.isOnThisDay,
                isEmpty: false
            )
        }

        return SaharaWidgetEntry(
            date: Date(),
            cardId: selected.entry.cardId,
            cardDate: selected.entry.date,
            memo: selected.entry.memo,
            thumbnailImage: nil,
            isOnThisDay: selected.isOnThisDay,
            isEmpty: false
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
