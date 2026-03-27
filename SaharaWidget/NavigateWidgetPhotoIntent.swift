//
//  NavigateWidgetPhotoIntent.swift
//  SaharaWidget
//
//  Created by 금가경 on 3/27/26.
//

import AppIntents
import WidgetKit

enum NavigationDirection: String, AppEnum {
    case previous
    case next

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Navigation Direction"
    }

    static var caseDisplayRepresentations: [NavigationDirection: DisplayRepresentation] {
        [
            .previous: "Previous",
            .next: "Next"
        ]
    }
}

struct NavigateWidgetPhotoIntent: AppIntent {
    static var title: LocalizedStringResource = "Navigate Widget Photo"
    static var description: IntentDescription = "Navigate to the previous or next photo in the widget"

    @Parameter(title: "Direction")
    var direction: NavigationDirection

    init() {
        self.direction = .next
    }

    init(direction: NavigationDirection) {
        self.direction = direction
    }

    func perform() async throws -> some IntentResult {
        let navigableCards = loadNavigableCards()
        guard navigableCards.count > 1 else { return .result() }

        let currentId = AppGroupContainer.pinnedCardId
        let currentIndex = navigableCards.firstIndex(where: { $0.cardId == currentId }) ?? 0

        let newIndex: Int
        switch direction {
        case .next:
            newIndex = (currentIndex + 1) % navigableCards.count
        case .previous:
            newIndex = (currentIndex - 1 + navigableCards.count) % navigableCards.count
        }

        AppGroupContainer.pinnedCardId = navigableCards[newIndex].cardId
        WidgetCenter.shared.reloadAllTimelines()

        return .result()
    }

    private func loadNavigableCards() -> [WidgetCardEntry] {
        guard let storeURL = AppGroupContainer.cardStoreURL,
              let data = try? Data(contentsOf: storeURL) else {
            return []
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let entries = (try? decoder.decode([WidgetCardEntry].self, from: data)) ?? []
        return entries.filter { $0.thumbnailFileName != nil }
    }
}
