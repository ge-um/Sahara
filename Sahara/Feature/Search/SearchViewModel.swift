//
//  SearchViewModel.swift
//  Sahara
//
//  Created by 금가경 on 10/8/25.
//

import Foundation
import RealmSwift
import RxCocoa
import RxSwift

enum SearchEmptyState {
    case initial
    case noResults
}

final class SearchViewModel: BaseViewModelProtocol {
    private let realmManager: RealmManagerProtocol
    private let disposeBag = DisposeBag()
    private let cardsRelay = BehaviorRelay<[SearchCardDTO]>(value: [])
    private let emptyStateRelay = BehaviorRelay<SearchEmptyState>(value: .initial)

    init(realmManager: RealmManagerProtocol = RealmManager.shared) {
        self.realmManager = realmManager
    }

    struct Input {
        let searchText: Observable<String>
        let itemSelected: Observable<IndexPath>
    }

    struct Output {
        let cards: Driver<[SearchCardDTO]>
        let emptyState: Driver<SearchEmptyState>
        let navigateToDetail: Driver<ObjectId>
    }

    func transform(input: Input) -> Output {
        input.searchText
            .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .withUnretained(self)
            .bind { owner, searchText in
                owner.searchCards(with: searchText)
            }
            .disposed(by: disposeBag)

        let navigateToDetail = input.itemSelected
            .withLatestFrom(cardsRelay.asObservable()) { indexPath, cards -> ObjectId? in
                guard cards.indices.contains(indexPath.item) else { return nil }
                return cards[indexPath.item].id
            }
            .compactMap { $0 }
            .asDriver(onErrorDriveWith: .empty())

        return Output(
            cards: cardsRelay.asDriver(),
            emptyState: emptyStateRelay.asDriver(),
            navigateToDetail: navigateToDetail
        )
    }

    private func searchCards(with query: String) {
        if query.isEmpty {
            cardsRelay.accept([])
            emptyStateRelay.accept(.initial)
        } else {
            let allCards = realmManager.fetch(Card.self)
            let results = allCards
                .filter { card in
                    let memoMatches = card.memo?.localizedCaseInsensitiveContains(query) ?? false
                    let ocrTextMatches = card.ocrText?.localizedCaseInsensitiveContains(query) ?? false
                    return memoMatches || ocrTextMatches
                }
                .sorted { $0.date > $1.date }
                .map { SearchCardDTO(from: $0) }

            cardsRelay.accept(results)

            if results.isEmpty {
                emptyStateRelay.accept(.noResults)
            }
        }
    }

    func getCard(at index: Int) -> SearchCardDTO? {
        let cards = cardsRelay.value
        guard cards.indices.contains(index) else { return nil }
        return cards[index]
    }

    func getCard(by id: ObjectId) -> SearchCardDTO? {
        return cardsRelay.value.first { $0.id == id }
    }
}
