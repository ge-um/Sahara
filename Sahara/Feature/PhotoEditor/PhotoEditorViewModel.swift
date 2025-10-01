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
        let viewDidLoad: Observable<Void>
        let searchQuery: Observable<String>
        let stickerSelected: Observable<Sticker>
        let doneButtonTapped: Observable<UIView>
        let cancelButtonTapped: Observable<Void>
    }

    struct Output {
        let originalImage: Driver<UIImage>
        let stickers: Driver<[Sticker]>
        let selectedSticker: Driver<Sticker>
        let navigateToMetadata: Driver<UIImage>
        let dismiss: Driver<Void>
    }

    init(originalImage: UIImage) {
        self.originalImage = originalImage
    }

    func transform(input: Input) -> Output {
        let stickersRelay = BehaviorRelay<[Sticker]>(value: [])

        // 초기 트렌딩 스티커 로드
        input.viewDidLoad
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

        // 검색어 변경 시 스티커 검색
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

        // 검색어가 비어있으면 트렌딩 스티커로 복귀
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

        // 완료 버튼 탭 시 최종 이미지 생성하고 메타데이터 화면으로 이동
        let navigateToMetadata = input.doneButtonTapped
            .map { photoImageView -> UIImage? in
                // photoImageView를 UIImage로 렌더링
                return photoImageView.asImage()
            }
            .compactMap { $0 }
            .asDriver(onErrorDriveWith: .empty())

        let dismiss = input.cancelButtonTapped
            .asDriver(onErrorJustReturn: ())

        return Output(
            originalImage: Driver.just(originalImage),
            stickers: stickersRelay.asDriver(),
            selectedSticker: selectedSticker,
            navigateToMetadata: navigateToMetadata,
            dismiss: dismiss
        )
    }
}