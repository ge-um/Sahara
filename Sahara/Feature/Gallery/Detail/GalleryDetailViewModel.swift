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
        let shouldPopIfEmpty: Driver<Bool>
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

        // viewDidLoad와 viewWillAppear를 merge하되, distinctUntilChanged로 중복 호출 방지
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
            .withLatestFrom(memosRelay) { indexPath, memos -> (Int, [Memo]) in
                (indexPath.row, memos)
            }
            .withUnretained(self)
            .do(onNext: { owner, data in
                let (index, memos) = data
                guard index < memos.count else { return }
                let memo = memos[index]

                try? owner.realm.write {
                    owner.realm.delete(memo)
                }

                // 배열에서 해당 항목 제거하여 즉시 UI 업데이트
                var updatedMemos = memos
                updatedMemos.remove(at: index)
                memosRelay.accept(updatedMemos)

                NotificationCenter.default.post(name: NSNotification.Name("PhotoDeleted"), object: nil)
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

        return Output(
            memos: memosRelay.asDriver(),
            navigateToDetail: navigateToDetail,
            shouldPopIfEmpty: shouldPopIfEmpty
        )
    }
}
