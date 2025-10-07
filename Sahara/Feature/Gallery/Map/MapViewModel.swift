//
//  MapViewModel.swift
//  Sahara
//
//  Created by 금가경 on 10/2/25.
//

import Foundation
import RealmSwift
import RxCocoa
import RxSwift

final class MapViewModel: BaseViewModelProtocol {
    private let cardIds: [ObjectId]
    private let disposeBag = DisposeBag()
    private let cardsRelay = BehaviorRelay<[Card]>(value: [])

    struct Input {
        let viewDidLoad: Observable<Void>
        let itemSelected: Observable<IndexPath>
        let closeButtonTapped: Observable<Void>
    }

    struct Output {
        let cards: Driver<[Card]>
        let navigateToDetail: Driver<ObjectId>
        let dismiss: Driver<Void>
    }

    init(cards: [Card]) {
        self.cardIds = cards.map { $0.id }
    }

    func transform(input: Input) -> Output {
        input.viewDidLoad
            .withUnretained(self)
            .bind { owner, _ in
                owner.observeCards()
            }
            .disposed(by: disposeBag)

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

        Observable<[Card]>.create { observer in
            let cards = realm.objects(Card.self).filter("id IN %@", self.cardIds)

            observer.onNext(Array(cards))

            let token = cards.observe { changes in
                switch changes {
                case .initial(let results):
                    observer.onNext(Array(results))
                case .update(let results, _, _, _):
                    observer.onNext(Array(results))
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

    func getCard(at index: Int) -> Card? {
        let cards = cardsRelay.value
        guard index < cards.count else { return nil }
        return cards[index]
    }

    func getCard(by id: ObjectId) -> Card? {
        return cardsRelay.value.first { $0.id == id }
    }
}
