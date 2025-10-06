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
    private let realmManager = RealmManager.shared
    private let disposeBag = DisposeBag()

    struct Input {
        let viewDidLoad: Observable<Void>
        let viewWillAppear: Observable<Void>
        let itemSelected: Observable<IndexPath>
        let itemDeleted: Observable<IndexPath>
    }

    struct Output {
        let cardIds: Driver<[ObjectId]>
        let navigateToDetail: Driver<ObjectId>
        let shouldPopIfEmpty: Driver<Bool>
    }

    init(date: Date) {
        self.date = date
    }

    func getCard(by id: ObjectId) -> Card? {
        return realmManager.realm.object(ofType: Card.self, forPrimaryKey: id)
    }

    func transform(input: Input) -> Output {
        let memosRelay = BehaviorRelay<[Card]>(value: [])

        let loadMemos: () -> Void = { [weak self] in
            guard let self = self else { return }
            let memos = self.realmManager.fetcCards(on: self.date)
            memosRelay.accept(memos)
        }

        Observable.merge(
            input.viewDidLoad,
            input.viewWillAppear
        )
        .throttle(.milliseconds(100), scheduler: MainScheduler.instance)
        .bind(with: self) { _, _ in
            loadMemos()
        }
        .disposed(by: disposeBag)

        let deleteCompleted = input.itemDeleted
            .withLatestFrom(memosRelay) { indexPath, memos -> (Int, [Card]) in
                (indexPath.row, memos)
            }
            .withUnretained(self)
            .do(onNext: { owner, data in
                let (index, memos) = data
                guard index < memos.count else { return }
                let memo = memos[index]

                owner.realmManager.delete(memo)

                var updatedMemos = memos
                updatedMemos.remove(at: index)
                memosRelay.accept(updatedMemos)

                NotificationCenter.default.post(name: AppNotification.photoDeleted.name, object: nil)
            })
            .map { _ in () }

        deleteCompleted
            .subscribe()
            .disposed(by: disposeBag)

        let navigateToDetail = input.itemSelected
            .withLatestFrom(memosRelay) { indexPath, memos in
                memos[indexPath.row].id
            }
            .asDriver(onErrorDriveWith: .empty())

        let shouldPopIfEmpty = deleteCompleted
            .withLatestFrom(memosRelay)
            .map { $0.isEmpty }
            .filter { $0 }
            .map { _ in true }
            .asDriver(onErrorJustReturn: false)

        let cardIds = memosRelay
            .map { memos in memos.map { $0.id } }
            .asDriver(onErrorJustReturn: [])

        return Output(
            cardIds: cardIds,
            navigateToDetail: navigateToDetail,
            shouldPopIfEmpty: shouldPopIfEmpty
        )
    }
}
