//
//  CalendarDetailViewModel.swift
//  Sahara
//
//  Created by 금가경 on 10/2/25.
//

import Foundation
import RealmSwift
import RxCocoa
import RxSwift

final class CalendarDetailViewModel: BaseViewModelProtocol {
    private let date: Date
    private let realmManager: RealmManagerProtocol
    private let disposeBag = DisposeBag()
    private let cardsRelay = BehaviorRelay<[CardListItemDTO]>(value: [])

    struct Input {
        let itemSelected: Observable<IndexPath>
        let itemDeleted: Observable<IndexPath>
    }

    struct Output {
        let cardIds: Driver<[ObjectId]>
        let navigateToDetail: Driver<ObjectId>
        let shouldPopIfEmpty: Driver<Bool>
    }

    init(date: Date, realmManager: RealmManagerProtocol = RealmManager.shared) {
        self.date = date
        self.realmManager = realmManager
    }

    func getCard(by id: ObjectId) -> CardListItemDTO? {
        return cardsRelay.value.first { $0.id == id }
    }

    func transform(input: Input) -> Output {
        let cards = realmManager.observeCards(for: .day(date))
            .do(onNext: { _ in MemoryTracker.measure("CalendarDetail.before") })
            .map { $0.map { CardListItemDTO(from: $0) } }
            .do(onNext: { _ in
                MemoryTracker.measure("CalendarDetail.after")
                MemoryTracker.compare("CalendarDetail.before", "CalendarDetail.after")
            })
            .share(replay: 1, scope: .whileConnected)

        cards
            .bind(to: cardsRelay)
            .disposed(by: disposeBag)

        let deleteCompleted = input.itemDeleted
            .withLatestFrom(cardsRelay) { indexPath, cards in
                (indexPath.row, cards)
            }
            .withUnretained(self)
            .flatMap { owner, data -> Observable<Void> in
                let (index, cards) = data
                guard index < cards.count else { return .empty() }
                let cardId = cards[index].id
                return owner.realmManager.deleteCard(forPrimaryKey: cardId)
            }
            .share()

        deleteCompleted
            .subscribe()
            .disposed(by: disposeBag)

        let navigateToDetail = input.itemSelected
            .withLatestFrom(cardsRelay) { indexPath, cards in
                cards[indexPath.row].id
            }
            .asDriver(onErrorDriveWith: .empty())

        let shouldPopIfEmpty = deleteCompleted
            .withLatestFrom(cardsRelay)
            .map { $0.isEmpty }
            .filter { $0 }
            .map { _ in true }
            .asDriver(onErrorJustReturn: false)

        let cardIds = cardsRelay
            .map { cards in cards.map { $0.id } }
            .asDriver(onErrorJustReturn: [])

        return Output(
            cardIds: cardIds,
            navigateToDetail: navigateToDetail,
            shouldPopIfEmpty: shouldPopIfEmpty
        )
    }
}
