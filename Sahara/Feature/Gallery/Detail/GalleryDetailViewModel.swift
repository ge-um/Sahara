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
        let itemSelected: Observable<IndexPath>
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

        input.viewDidLoad
            .withUnretained(self)
            .map { owner, _ -> [Memo] in
                let startOfDay = Calendar.current.startOfDay(for: owner.date)
                guard let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) else {
                    return []
                }

                let results = owner.realm.objects(Memo.self)
                    .filter("createdDate >= %@ AND createdDate < %@", startOfDay, endOfDay)
                    .sorted(byKeyPath: "createdDate", ascending: true)

                return Array(results)
            }
            .bind(to: memosRelay)
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
