//
//  MapPhotoGalleryViewModel.swift
//  Sahara
//
//  Created by 금가경 on 10/2/25.
//

import Foundation
import RealmSwift
import RxCocoa
import RxSwift

final class MapPhotoGalleryViewModel: BaseViewModelProtocol {
    private let photoMemos: [Card]
    private let disposeBag = DisposeBag()

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
        self.photoMemos = photoMemos
    }

    func transform(input: Input) -> Output {
        let photoMemosDriver = input.viewDidLoad
            .map { [weak self] _ in self?.photoMemos ?? [] }
            .asDriver(onErrorJustReturn: [])

        let navigateToDetail = input.itemSelected
            .withUnretained(self)
            .map { owner, indexPath in
                owner.photoMemos[indexPath.item].id
            }
            .asDriver(onErrorDriveWith: .empty())

        let dismiss = input.closeButtonTapped
            .asDriver(onErrorJustReturn: ())

        return Output(
            photoMemos: photoMemosDriver,
            navigateToDetail: navigateToDetail,
            dismiss: dismiss
        )
    }

    func getCard(at index: Int) -> Card? {
        guard index < photoMemos.count else { return nil }
        return photoMemos[index]
    }
}
