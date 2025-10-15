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
    private let disposeBag = DisposeBag()
    private let cardsRelay = BehaviorRelay<[Card]>(value: [])
    private let emptyStateRelay = BehaviorRelay<SearchEmptyState>(value: .initial)

    struct Input {
        let searchText: Observable<String>
        let itemSelected: Observable<IndexPath>
    }

    struct Output {
        let cards: Driver<[Card]>
        let emptyState: Driver<SearchEmptyState>
        let navigateToDetail: Driver<ObjectId>
    }

    func transform(input: Input) -> Output {
        input.searchText
            .distinctUntilChanged()
            .withUnretained(self)
            .bind { owner, searchText in
                owner.searchCards(with: searchText)
            }
            .disposed(by: disposeBag)

        let navigateToDetail = input.itemSelected
            .withLatestFrom(cardsRelay.asObservable()) { indexPath, cards in
                cards[indexPath.item].id
            }
            .asDriver(onErrorDriveWith: .empty())

        return Output(
            cards: cardsRelay.asDriver(),
            emptyState: emptyStateRelay.asDriver(),
            navigateToDetail: navigateToDetail
        )
    }

    private func searchCards(with query: String) {
        let realm = try! Realm()

        if query.isEmpty {
            cardsRelay.accept([])
            emptyStateRelay.accept(.initial)
        } else {
            let results = realm.objects(Card.self)
                .filter { card in
                    let memoMatches = card.memo?.localizedCaseInsensitiveContains(query) ?? false
                    let ocrTextMatches = card.ocrText?.localizedCaseInsensitiveContains(query) ?? false
                    return memoMatches || ocrTextMatches
                }
                .sorted(by: { $0.createdDate > $1.createdDate })

            let cards = Array(results)
            cardsRelay.accept(cards)

            if cards.isEmpty {
                emptyStateRelay.accept(.noResults)
            }
        }
    }

    func getCard(at index: Int) -> Card? {
        let cards = cardsRelay.value
        guard index < cards.count else { return nil }
        return cards[index]
    }

    func getCard(by id: ObjectId) -> Card? {
        return cardsRelay.value.first { $0.id == id }
    }
}
