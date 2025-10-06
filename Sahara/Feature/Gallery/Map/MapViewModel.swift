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
    private let photoMemoIds: [ObjectId]
    private let disposeBag = DisposeBag()
    private let photoMemosRelay = BehaviorRelay<[Card]>(value: [])

    struct Input {
        let viewDidLoad: Observable<Void>
        let itemSelected: Observable<IndexPath>
        let closeButtonTapped: Observable<Void>
    }

    struct Output {
        let photoMemos: Driver<[Card]>
        let navigateToDetail: Driver<ObjectId>
        let dismiss: Driver<Void>
    }

    init(photoMemos: [Card]) {
        self.photoMemoIds = photoMemos.map { $0.id }
    }

    func transform(input: Input) -> Output {
        input.viewDidLoad
            .withUnretained(self)
            .bind { owner, _ in
                owner.observePhotoMemos()
            }
            .disposed(by: disposeBag)

        let navigateToDetail = input.itemSelected
            .withLatestFrom(photoMemosRelay.asObservable()) { indexPath, photoMemos in
                photoMemos[indexPath.item].id
            }
            .asDriver(onErrorDriveWith: .empty())

        let dismiss = input.closeButtonTapped
            .asDriver(onErrorJustReturn: ())

        return Output(
            photoMemos: photoMemosRelay.asDriver(),
            navigateToDetail: navigateToDetail,
            dismiss: dismiss
        )
    }

    private func observePhotoMemos() {
        let realm = try! Realm()

        Observable<[Card]>.create { observer in
            let cards = realm.objects(Card.self).filter("id IN %@", self.photoMemoIds)

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
        .bind(to: photoMemosRelay)
        .disposed(by: disposeBag)
    }

    func getCard(at index: Int) -> Card? {
        let photoMemos = photoMemosRelay.value
        guard index < photoMemos.count else { return nil }
        return photoMemos[index]
    }

    func getCard(by id: ObjectId) -> Card? {
        return photoMemosRelay.value.first { $0.id == id }
    }
}
