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

    init(cardIds: [ObjectId]) {
        self.cardIds = cardIds
        self.folderName = nil
    }

    init(folderName: String) {
        self.cardIds = nil
        self.folderName = folderName
    }

    func transform(input: Input) -> Output {
        observeCards()

        let navigateToDetail = input.itemSelected
            .withLatestFrom(cardsRelay.asObservable()) { indexPath, cards in
                cards[indexPath.item].id
            }
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
        let realm = try! Realm()

        Observable<[CardListItemDTO]>.create { observer in
            let cards: Results<Card>

            if let folderName = self.folderName {
                let defaultFolderName = NSLocalizedString("folder.default", comment: "")
                if folderName == defaultFolderName {
                    cards = realm.objects(Card.self).filter("customFolder == nil OR customFolder == ''")
                } else {
                    cards = realm.objects(Card.self).filter("customFolder == %@", folderName)
                }
            } else if let cardIds = self.cardIds {
                cards = realm.objects(Card.self).filter("id IN %@", cardIds)
            } else {
                cards = realm.objects(Card.self)
            }

            let sortedCards = Array(cards).sorted { $0.date > $1.date }
            observer.onNext(sortedCards.map { CardListItemDTO(from: $0) })

            let token = cards.observe { changes in
                switch changes {
                case .initial(let results):
                    let sorted = Array(results).sorted { $0.date > $1.date }
                    observer.onNext(sorted.map { CardListItemDTO(from: $0) })
                case .update(let results, _, _, _):
                    let sorted = Array(results).sorted { $0.date > $1.date }
                    observer.onNext(sorted.map { CardListItemDTO(from: $0) })
                case .error(let error):
                    observer.onError(error)
                }
            }

            return Disposables.create {
                token.invalidate()
            }
        }
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
