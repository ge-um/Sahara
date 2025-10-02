//
//  GalleryDetailViewModel.swift
//  Sahara
//
//  Created by 금가경 on 10/2/25.
//

import Foundation
import RealmSwift
import RxCocoa
import RxSwift

final class GalleryDetailViewModel: BaseViewModelProtocol {
    private let date: Date
    private let realm = try! Realm()
    private let disposeBag = DisposeBag()

    struct Input {
        let viewDidLoad: Observable<Void>
        let viewWillAppear: Observable<Void>
        let itemSelected: Observable<IndexPath>
        let itemDeleted: Observable<IndexPath>
    }

    struct Output {
        let memos: Driver<[Memo]>
        let navigateToDetail: Driver<ObjectId>
    }

    init(date: Date) {
        self.date = date
    }

    func transform(input: Input) -> Output {
        let memosRelay = BehaviorRelay<[Memo]>(value: [])

        let loadMemos: () -> Void = { [weak self] in
            guard let self = self else { return }
            let startOfDay = Calendar.current.startOfDay(for: self.date)
            guard let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) else {
                return
            }

            let results = self.realm.objects(Memo.self)
                .filter("createdDate >= %@ AND createdDate < %@", startOfDay, endOfDay)
                .sorted(byKeyPath: "createdDate", ascending: true)

            memosRelay.accept(Array(results))
        }

        input.viewDidLoad
            .bind(with: self) { _, _ in
                loadMemos()
            }
            .disposed(by: disposeBag)

        input.viewWillAppear
            .bind(with: self) { _, _ in
                loadMemos()
            }
            .disposed(by: disposeBag)

        input.itemDeleted
            .withLatestFrom(memosRelay) { indexPath, memos in
                memos[indexPath.row]
            }
            .withUnretained(self)
            .bind { owner, memo in
                try? owner.realm.write {
                    owner.realm.delete(memo)
                }
                loadMemos()
            }
            .disposed(by: disposeBag)

        let navigateToDetail = input.itemSelected
            .withLatestFrom(memosRelay) { indexPath, memos in
                memos[indexPath.row].id
            }
            .asDriver(onErrorDriveWith: .empty())

        return Output(
            memos: memosRelay.asDriver(),
            navigateToDetail: navigateToDetail
        )
    }
}
