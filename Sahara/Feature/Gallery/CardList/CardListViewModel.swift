//
//  CardListViewModel.swift
//  Sahara
//
//  Created by 금가경 on 10/2/25.
//

import Foundation
import RealmSwift
import RxCocoa
import RxSwift

final class CardListViewModel: BaseViewModelProtocol {
    private let cardIds: [ObjectId]?
    private let folderName: String?
    private let realmManager: RealmServiceProtocol
    private let disposeBag = DisposeBag()
    private let cardsRelay = BehaviorRelay<[CardListItemDTO]>(value: [])

    struct Input {
        let itemSelected: Observable<IndexPath>
        let closeButtonTapped: Observable<Void>
    }

    struct Output {
        let cards: Driver<[CardListItemDTO]>
        let navigateToDetail: Driver<ObjectId>
        let dismiss: Driver<Void>
    }

    init(cardIds: [ObjectId], realmManager: RealmServiceProtocol = RealmService.shared) {
        self.cardIds = cardIds
        self.folderName = nil
        self.realmManager = realmManager
    }

    init(folderName: String, realmManager: RealmServiceProtocol = RealmService.shared) {
        self.cardIds = nil
        self.folderName = folderName
        self.realmManager = realmManager
    }

    func transform(input: Input) -> Output {
        observeCards()

        let navigateToDetail = input.itemSelected
            .withLatestFrom(cardsRelay.asObservable()) { indexPath, cards -> ObjectId? in
                guard cards.indices.contains(indexPath.item) else { return nil }
                return cards[indexPath.item].id
            }
            .compactMap { $0 }
            .asDriver(onErrorDriveWith: .empty())

        let dismiss = input.closeButtonTapped
            .asDriver(onErrorJustReturn: ())

        return Output(
            cards: cardsRelay.asDriver(),
            navigateToDetail: navigateToDetail,
            dismiss: dismiss
        )
    }

    private func observeCards() {
        let observable: Observable<[CardListItemDTO]>

        if let folderName = folderName {
            observable = realmManager.observeCards(inFolder: folderName)
        } else if let cardIds = cardIds {
            observable = realmManager.observeCards(withIds: cardIds)
        } else {
            observable = realmManager.observeCards(inFolder: nil)
        }

        observable
            .bind(to: cardsRelay)
            .disposed(by: disposeBag)
    }

    func getCard(at index: Int) -> CardListItemDTO? {
        let cards = cardsRelay.value
        guard index < cards.count else { return nil }
        return cards[index]
    }

    func getCard(by id: ObjectId) -> CardListItemDTO? {
        return cardsRelay.value.first { $0.id == id }
    }
}
