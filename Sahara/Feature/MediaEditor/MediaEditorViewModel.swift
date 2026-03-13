//
//  MediaEditorViewModel.swift
//  Sahara
//
//  Created by 금가경 on 9/26/25.
//

import Alamofire
import Foundation
import OSLog
import RxCocoa
import RxSwift
import UIKit

final class MediaEditorViewModel: BaseViewModelProtocol {
    private let disposeBag = DisposeBag()
    private let imageStateHandler: MediaEditorImageStateHandler
    private let networkManager: NetworkServiceProtocol
    private let filterHandler = MediaEditorFilterHandler()
    private let currentPageRelay = BehaviorRelay<Int>(value: 1)
    private let hasNextRelay = BehaviorRelay<Bool>(value: true)
    private let currentQueryRelay = BehaviorRelay<String>(value: "")
    private let addedStickersRelay = BehaviorRelay<[(sticker: KlipySticker, position: CGPoint, scale: CGFloat)]>(value: [])

    struct Input {
        let viewWillAppear: Observable<Void>
        let stickerButtonTapped: Observable<Void>
        let searchQuery: Observable<String>
        let loadMoreTrigger: Observable<Void>
        let stickerSelected: Observable<KlipySticker>
        let stickerAdded: Observable<(sticker: KlipySticker, position: CGPoint, scale: CGFloat)>
        let filterSelected: Observable<(Int, UIImage?)>
        let cropApplied: Observable<(UIImage, CGRect, CGRect)>
        let drawingChanged: Observable<Void>
        let photoSelected: Observable<UIImage>
        let doneButtonTapped: Observable<UIImage>
        let cancelButtonTapped: Observable<Void>
    }

    struct Output {
        let originalImage: Driver<UIImage>
        let currentEditingImage: Driver<UIImage>
        let croppedImage: Driver<UIImage?>
        let uncroppedOriginalImage: Driver<UIImage>
        let filteredImage: Driver<UIImage?>
        let stickers: Driver<[KlipySticker]>
        let isLoadingMore: Driver<Bool>
        let selectedSticker: Driver<KlipySticker>
        let selectedPhoto: Driver<UIImage>
        let navigateToMetadata: Driver<UIImage>
        let dismiss: Driver<Void>
        let errorMessage: Driver<String>
        let networkErrorMessage: Driver<String>
        let shouldShowStickerModal: Driver<Void>
        let addedStickers: Driver<[(sticker: KlipySticker, position: CGPoint, scale: CGFloat)]>
        let initialStickers: [StickerDTO]
        let initialFilterIndex: Int?
        let initialUncroppedImage: UIImage?
        let initialCropRect: CGRect?
        let initialDrawingData: Data?
        let initialImageFormat: ImageSourceData.ImageFormat?
        let initialOriginalData: Data?
    }

    private let originalImageSource: ImageSourceData

    init(imageSource: ImageSourceData, networkManager: NetworkServiceProtocol = NetworkService.shared) {
        self.originalImageSource = imageSource
        self.imageStateHandler = MediaEditorImageStateHandler(originalImage: imageSource.image)
        self.networkManager = networkManager
    }

    func transform(input: Input) -> Output {
        let stickersRelay = BehaviorRelay<[KlipySticker]>(value: [])
        let filteredImageRelay = BehaviorRelay<UIImage?>(value: nil)
        let isLoadingMoreRelay = BehaviorRelay<Bool>(value: false)
        let errorRelay = PublishRelay<String>()
        let networkErrorRelay = PublishRelay<String>()
        let shouldShowStickerModalRelay = PublishRelay<Void>()

        bindStickerSearch(
            input: input,
            stickersRelay: stickersRelay,
            isLoadingMoreRelay: isLoadingMoreRelay,
            errorRelay: errorRelay,
            networkErrorRelay: networkErrorRelay,
            shouldShowStickerModalRelay: shouldShowStickerModalRelay
        )

        bindImageEditing(input: input, filteredImageRelay: filteredImageRelay)

        return buildOutput(
            input: input,
            stickersRelay: stickersRelay,
            filteredImageRelay: filteredImageRelay,
            isLoadingMoreRelay: isLoadingMoreRelay,
            errorRelay: errorRelay,
            networkErrorRelay: networkErrorRelay,
            shouldShowStickerModalRelay: shouldShowStickerModalRelay
        )
    }

    private func bindStickerSearch(
        input: Input,
        stickersRelay: BehaviorRelay<[KlipySticker]>,
        isLoadingMoreRelay: BehaviorRelay<Bool>,
        errorRelay: PublishRelay<String>,
        networkErrorRelay: PublishRelay<String>,
        shouldShowStickerModalRelay: PublishRelay<Void>
    ) {
        input.stickerButtonTapped
            .withUnretained(self)
            .bind { owner, _ in
                let isConnected = NetworkReachabilityManager()?.isReachable ?? false
                if isConnected {
                    shouldShowStickerModalRelay.accept(())
                } else {
                    networkErrorRelay.accept(NSLocalizedString("media_editor.network_error", comment: ""))
                }
            }
            .disposed(by: disposeBag)

        input.searchQuery
            .withUnretained(self)
            .bind { owner, query in
                owner.currentQueryRelay.accept(query)
                owner.currentPageRelay.accept(1)
                owner.hasNextRelay.accept(true)
            }
            .disposed(by: disposeBag)

        input.viewWillAppear
            .withUnretained(self)
            .do(onNext: { owner, _ in
                owner.currentPageRelay.accept(1)
                owner.hasNextRelay.accept(true)
            })
            .flatMapLatest { owner, _ in
                owner.networkManager.callRequest(
                    api: .trendingStickers(
                        page: 1,
                        perPage: 20,
                        customerId: UIDevice.current.identifierForVendor?.uuidString ?? "unknown",
                        locale: Locale.current.language.languageCode?.identifier ?? "US"
                    ),
                    type: StickerResponse.self
                )
                .catch { error in
                    if let networkError = error as? NetworkError {
                        errorRelay.accept(networkError.errorDescription)
                    } else {
                        errorRelay.accept(error.localizedDescription)
                    }
                    return Observable.empty()
                }
            }
            .withUnretained(self)
            .do(onNext: { owner, response in
                owner.hasNextRelay.accept(response.data.hasNext ?? false)
            })
            .map { $0.1.data.data }
            .bind(to: stickersRelay)
            .disposed(by: disposeBag)

        input.searchQuery
            .skip(1)
            .distinctUntilChanged()
            .withUnretained(self)
            .flatMapLatest { owner, query -> Observable<StickerResponse> in
                let request: Observable<StickerResponse>
                if query.isEmpty {
                    request = owner.networkManager.callRequest(
                        api: .trendingStickers(
                            page: 1,
                            perPage: 20,
                            customerId: UIDevice.current.identifierForVendor?.uuidString ?? "unknown",
                            locale: Locale.current.language.languageCode?.identifier ?? "US"
                        ),
                        type: StickerResponse.self
                    )
                } else {
                    request = owner.networkManager.callRequest(
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
                return request.catch { error in
                    if let networkError = error as? NetworkError {
                        errorRelay.accept(networkError.errorDescription)
                    } else {
                        errorRelay.accept(error.localizedDescription)
                    }
                    return Observable.empty()
                }
            }
            .withUnretained(self)
            .do(onNext: { owner, response in
                owner.hasNextRelay.accept(response.data.hasNext ?? false)
            })
            .map { $0.1.data.data }
            .bind(to: stickersRelay)
            .disposed(by: disposeBag)

        input.loadMoreTrigger
            .withUnretained(self)
            .filter { owner, _ in owner.hasNextRelay.value && !isLoadingMoreRelay.value }
            .do(onNext: { owner, _ in
                isLoadingMoreRelay.accept(true)
                owner.currentPageRelay.accept(owner.currentPageRelay.value + 1)
            })
            .flatMapLatest { owner, _ -> Observable<StickerResponse> in
                let query = owner.currentQueryRelay.value
                let page = owner.currentPageRelay.value

                let request: Observable<StickerResponse>
                if query.isEmpty {
                    request = owner.networkManager.callRequest(
                        api: .trendingStickers(
                            page: page,
                            perPage: 20,
                            customerId: UIDevice.current.identifierForVendor?.uuidString ?? "unknown",
                            locale: Locale.current.language.languageCode?.identifier ?? "US"
                        ),
                        type: StickerResponse.self
                    )
                } else {
                    request = owner.networkManager.callRequest(
                        api: .searchStickers(
                            query: query,
                            page: page,
                            perPage: 20,
                            customerId: UIDevice.current.identifierForVendor?.uuidString ?? "unknown",
                            locale: Locale.current.language.languageCode?.identifier ?? "US"
                        ),
                        type: StickerResponse.self
                    )
                }
                return request.catch { error in
                    isLoadingMoreRelay.accept(false)
                    if let networkError = error as? NetworkError {
                        errorRelay.accept(networkError.errorDescription)
                    } else {
                        errorRelay.accept(error.localizedDescription)
                    }
                    return Observable.empty()
                }
            }
            .withUnretained(self)
            .do(onNext: { owner, response in
                owner.hasNextRelay.accept(response.data.hasNext ?? false)
                isLoadingMoreRelay.accept(false)
            })
            .map { $0.1.data.data }
            .withUnretained(self)
            .bind { owner, newStickers in
                let currentStickers = stickersRelay.value
                stickersRelay.accept(currentStickers + newStickers)
            }
            .disposed(by: disposeBag)
    }

    private func bindImageEditing(input: Input, filteredImageRelay: BehaviorRelay<UIImage?>) {
        input.filterSelected
            .withUnretained(self)
            .bind { owner, data in
                let (index, baseImage) = data
                guard let baseImage = baseImage else { return }

                guard let filteredImage = owner.filterHandler.applyFilter(at: index, to: baseImage) else { return }

                owner.imageStateHandler.applyFilter(filteredImage)
                filteredImageRelay.accept(filteredImage)
            }
            .disposed(by: disposeBag)

        input.cropApplied
            .withUnretained(self)
            .compactMap { owner, data -> UIImage? in
                let (image, cropRect, displayedRect) = data
                let scaledCropRect = MediaEditorCropHandler.convertCropRectToImageCoordinates(
                    cropRect: cropRect,
                    imageSize: image.size,
                    displayedImageRect: displayedRect
                )

                return MediaEditorCropHandler.cropImage(image, to: scaledCropRect)
            }
            .bind(with: self) { owner, croppedImage in
                owner.imageStateHandler.applyCrop(croppedImage)
            }
            .disposed(by: disposeBag)

        input.stickerAdded
            .withUnretained(self)
            .bind { owner, stickerData in
                var currentStickers = owner.addedStickersRelay.value
                currentStickers.append(stickerData)
                owner.addedStickersRelay.accept(currentStickers)
            }
            .disposed(by: disposeBag)
    }

    private func buildOutput(
        input: Input,
        stickersRelay: BehaviorRelay<[KlipySticker]>,
        filteredImageRelay: BehaviorRelay<UIImage?>,
        isLoadingMoreRelay: BehaviorRelay<Bool>,
        errorRelay: PublishRelay<String>,
        networkErrorRelay: PublishRelay<String>,
        shouldShowStickerModalRelay: PublishRelay<Void>
    ) -> Output {
        let selectedSticker = input.stickerSelected
            .asDriver(onErrorDriveWith: .empty())

        let selectedPhoto = input.photoSelected
            .asDriver(onErrorDriveWith: .empty())

        let navigateToMetadata = input.doneButtonTapped
            .asDriver(onErrorDriveWith: .empty())

        let dismiss = input.cancelButtonTapped
            .asDriver(onErrorJustReturn: ())

        return Output(
            originalImage: imageStateHandler.originalImage,
            currentEditingImage: imageStateHandler.currentEditingImage,
            croppedImage: imageStateHandler.croppedImage,
            uncroppedOriginalImage: imageStateHandler.uncroppedOriginalImage,
            filteredImage: filteredImageRelay.asDriver(),
            stickers: stickersRelay.asDriver(),
            isLoadingMore: isLoadingMoreRelay.asDriver(),
            selectedSticker: selectedSticker,
            selectedPhoto: selectedPhoto,
            navigateToMetadata: navigateToMetadata,
            dismiss: dismiss,
            errorMessage: errorRelay.asDriver(onErrorJustReturn: ""),
            networkErrorMessage: networkErrorRelay.asDriver(onErrorJustReturn: ""),
            shouldShowStickerModal: shouldShowStickerModalRelay.asDriver(onErrorDriveWith: .empty()),
            addedStickers: addedStickersRelay.asDriver(),
            initialStickers: originalImageSource.stickers,
            initialFilterIndex: originalImageSource.filterIndex,
            initialUncroppedImage: originalImageSource.uncroppedImage,
            initialCropRect: originalImageSource.cropRect,
            initialDrawingData: originalImageSource.drawingData,
            initialImageFormat: originalImageSource.format,
            initialOriginalData: originalImageSource.originalData
        )
    }

}
