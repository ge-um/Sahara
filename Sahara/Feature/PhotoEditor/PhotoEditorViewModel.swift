//
//  PhotoEditorViewModel.swift
//  Sahara
//
//  Created by 금가경 on 9/26/25.
//

import Foundation
import RxCocoa
import RxSwift
import UIKit

final class PhotoEditorViewModel: BaseViewModelProtocol {
    private let disposeBag = DisposeBag()
    private let originalImage: UIImage

    struct Input {
        let viewWillAppear: Observable<Void>
        let searchQuery: Observable<String>
        let stickerSelected: Observable<Sticker>
        let filterSelected: Observable<Int>
        let drawingChanged: Observable<Void>
        let photoSelected: Observable<UIImage>
        let doneButtonTapped: Observable<UIImage>
        let cancelButtonTapped: Observable<Void>
    }

    struct Output {
        let originalImage: Driver<UIImage>
        let stickers: Driver<[Sticker]>
        let selectedSticker: Driver<Sticker>
        let selectedFilter: Driver<Int>
        let selectedPhoto: Driver<UIImage>
        let navigateToMetadata: Driver<UIImage>
        let dismiss: Driver<Void>
    }

    init(originalImage: UIImage) {
        self.originalImage = originalImage
    }

    func transform(input: Input) -> Output {
        let stickersRelay = BehaviorRelay<[Sticker]>(value: [])

        input.viewWillAppear
            .flatMapLatest { _ in
                NetworkManager.shared.callRequest(
                    api: .trendingStickers(
                        page: 1,
                        perPage: 20,
                        customerId: UIDevice.current.identifierForVendor?.uuidString ?? "unknown",
                        locale: Locale.current.language.languageCode?.identifier ?? "US"
                    ),
                    type: StickerResponse.self
                )
            }
            .map { $0.data.data }
            .bind(to: stickersRelay)
            .disposed(by: disposeBag)

        input.searchQuery
            .filter { !$0.isEmpty }
            .flatMapLatest { query in
                NetworkManager.shared.callRequest(
                    api: .searchStickers(
                        query: query,
                        page: 1,
                        perPage: 20,
                        customerId: UIDevice.current.identifierForVendor?.uuidString ?? "unknown",
                        locale: Locale.current.language.languageCode?.identifier ?? "US"
                    ),
                    type: StickerResponse.self
                )
            }
            .map { $0.data.data }
            .bind(to: stickersRelay)
            .disposed(by: disposeBag)

        input.searchQuery
            .filter { $0.isEmpty }
            .flatMapLatest { _ in
                NetworkManager.shared.callRequest(
                    api: .trendingStickers(
                        page: 1,
                        perPage: 20,
                        customerId: UIDevice.current.identifierForVendor?.uuidString ?? "unknown",
                        locale: Locale.current.language.languageCode?.identifier ?? "US"
                    ),
                    type: StickerResponse.self
                )
            }
            .map { $0.data.data }
            .bind(to: stickersRelay)
            .disposed(by: disposeBag)

        let selectedSticker = input.stickerSelected
            .asDriver(onErrorDriveWith: .empty())

        let selectedFilter = input.filterSelected
            .asDriver(onErrorJustReturn: 0)

        let selectedPhoto = input.photoSelected
            .asDriver(onErrorDriveWith: .empty())

        let navigateToMetadata = input.doneButtonTapped
            .asDriver(onErrorDriveWith: .empty())

        let dismiss = input.cancelButtonTapped
            .asDriver(onErrorJustReturn: ())

        return Output(
            originalImage: Driver.just(originalImage),
            stickers: stickersRelay.asDriver(),
            selectedSticker: selectedSticker,
            selectedFilter: selectedFilter,
            selectedPhoto: selectedPhoto,
            navigateToMetadata: navigateToMetadata,
            dismiss: dismiss
        )
    }
}