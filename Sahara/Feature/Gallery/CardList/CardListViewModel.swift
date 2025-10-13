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
        self.folderName = nil
    }

    init(folderName: String) {
        self.cardIds = nil
        self.folderName = folderName
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

            observer.onNext(Array(cards).sorted { $0.createdDate > $1.createdDate })

            let token = cards.observe { changes in
                switch changes {
                case .initial(let results):
                    observer.onNext(Array(results).sorted { $0.createdDate > $1.createdDate })
                case .update(let results, _, _, _):
                    observer.onNext(Array(results).sorted { $0.createdDate > $1.createdDate })
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
