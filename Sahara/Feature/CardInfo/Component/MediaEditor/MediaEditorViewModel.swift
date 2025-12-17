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
    private let networkManager: NetworkManagerProtocol
    private let context = CIContext()
    private let currentPageRelay = BehaviorRelay<Int>(value: 1)
    private let hasNextRelay = BehaviorRelay<Bool>(value: true)
    private let currentQueryRelay = BehaviorRelay<String>(value: "")
    private let wasEditedRelay = BehaviorRelay<Bool>(value: false)
    private let addedStickersRelay = BehaviorRelay<[(sticker: KlipySticker, position: CGPoint, scale: CGFloat)]>(value: [])
    private let selectedFilterIndexRelay = BehaviorRelay<Int?>(value: nil)
    private let cropMetadataRelay = BehaviorRelay<CropMetadata?>(value: nil)

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
        let wasEdited: Driver<Bool>
        let addedStickers: Driver<[(sticker: KlipySticker, position: CGPoint, scale: CGFloat)]>
        let selectedFilterIndex: Driver<Int?>
        let cropMetadata: Driver<CropMetadata?>
    }

    private let originalImageSource: ImageSourceData

    init(imageSource: ImageSourceData, networkManager: NetworkManagerProtocol = NetworkManager.shared) {
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

        input.filterSelected
            .withUnretained(self)
            .bind { owner, data in
                let (index, baseImage) = data
                guard let baseImage = baseImage else { return }

                owner.selectedFilterIndexRelay.accept(index == 0 ? nil : index)

                if index == 0 {
                    owner.imageStateHandler.applyFilter(baseImage)
                    filteredImageRelay.accept(baseImage)
                    owner.wasEditedRelay.accept(true)
                    return
                }

                guard let filter = owner.createFilter(at: index),
                      let filteredImage = owner.applyFilter(filter, to: baseImage) else { return }

                owner.imageStateHandler.applyFilter(filteredImage)
                filteredImageRelay.accept(filteredImage)
                owner.wasEditedRelay.accept(true)
            }
            .disposed(by: disposeBag)

        input.cropApplied
            .withUnretained(self)
            .compactMap { owner, data -> (UIImage, CropMetadata)? in
                let (image, cropRect, displayedRect) = data
                let scaledCropRect = MediaEditorCropHandler.convertCropRectToImageCoordinates(
                    cropRect: cropRect,
                    imageSize: image.size,
                    displayedImageRect: displayedRect
                )

                let normalizedX = scaledCropRect.origin.x / image.size.width
                let normalizedY = scaledCropRect.origin.y / image.size.height
                let normalizedWidth = scaledCropRect.size.width / image.size.width
                let normalizedHeight = scaledCropRect.size.height / image.size.height

                let cropMetadata = CropMetadata(
                    x: normalizedX,
                    y: normalizedY,
                    width: normalizedWidth,
                    height: normalizedHeight
                )

                guard let croppedImage = MediaEditorCropHandler.cropImage(image, to: scaledCropRect) else {
                    return nil
                }

                return (croppedImage, cropMetadata)
            }
            .do(onNext: { result in
                let (_, cropMetadata) = result
                Logger.imageMetadata.info("Cropped image: \(cropMetadata.formattedCoordinates())")
            })
            .bind(with: self) { owner, result in
                let (croppedImage, cropMetadata) = result
                owner.imageStateHandler.applyCrop(croppedImage)
                owner.cropMetadataRelay.accept(cropMetadata)
                owner.wasEditedRelay.accept(true)
            }
            .disposed(by: disposeBag)

        input.stickerAdded
            .withUnretained(self)
            .bind { owner, stickerData in
                var currentStickers = owner.addedStickersRelay.value
                currentStickers.append(stickerData)
                owner.addedStickersRelay.accept(currentStickers)
                owner.wasEditedRelay.accept(true)
            }
            .disposed(by: disposeBag)

        input.drawingChanged
            .withUnretained(self)
            .bind { owner, _ in
                owner.wasEditedRelay.accept(true)
            }
            .disposed(by: disposeBag)

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
            wasEdited: wasEditedRelay.asDriver(),
            addedStickers: addedStickersRelay.asDriver(),
            selectedFilterIndex: selectedFilterIndexRelay.asDriver(),
            cropMetadata: cropMetadataRelay.asDriver()
        )
    }

    private func createFilter(at index: Int) -> CIFilter? {
        let filterNames = [
            nil,
            "CIPhotoEffectNoir",
            "CISepiaTone",
            "CIPhotoEffectInstant",
            "CIPhotoEffectChrome",
            "CIPhotoEffectFade",
            "CIPhotoEffectMono",
            "CIPhotoEffectProcess",
            "CIPhotoEffectTransfer",
            "CIPhotoEffectTonal"
        ]

        guard index < filterNames.count, let filterName = filterNames[index] else {
            return nil
        }

        return CIFilter(name: filterName)
    }

    private func applyFilter(_ filter: CIFilter, to image: UIImage) -> UIImage? {
        guard let ciImage = CIImage(image: image) else { return nil }

        filter.setValue(ciImage, forKey: kCIInputImageKey)

        guard let outputImage = filter.outputImage,
              let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return nil
        }

        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }
}