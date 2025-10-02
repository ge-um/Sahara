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
    private let context = CIContext()

    struct Input {
        let viewWillAppear: Observable<Void>
        let searchQuery: Observable<String>
        let stickerSelected: Observable<KlipySticker>
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
        let filteredImage: Driver<UIImage?>
        let stickers: Driver<[KlipySticker]>
        let selectedSticker: Driver<KlipySticker>
        let selectedPhoto: Driver<UIImage>
        let navigateToMetadata: Driver<UIImage>
        let dismiss: Driver<Void>
    }

    init(originalImage: UIImage) {
        self.originalImage = originalImage
    }

    func transform(input: Input) -> Output {
        let stickersRelay = BehaviorRelay<[KlipySticker]>(value: [])
        let currentEditingImageRelay = BehaviorRelay<UIImage>(value: originalImage)
        let croppedImageRelay = BehaviorRelay<UIImage?>(value: nil)
        let filteredImageRelay = BehaviorRelay<UIImage?>(value: nil)

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

        // 필터 적용 로직
        input.filterSelected
            .withUnretained(self)
            .compactMap { owner, data -> UIImage? in
                let (index, baseImage) = data
                guard let baseImage = baseImage else { return nil }

                if index == 0 {
                    return baseImage
                }

                guard let filter = owner.createFilter(at: index) else { return nil }
                return owner.applyFilter(filter, to: baseImage)
            }
            .bind { image in
                currentEditingImageRelay.accept(image)
                filteredImageRelay.accept(image)
            }
            .disposed(by: disposeBag)

        // 자르기 적용 로직
        input.cropApplied
            .compactMap { image, cropRect, displayedRect -> UIImage? in
                let scaledCropRect = PhotoEditorCropHandler.convertCropRectToImageCoordinates(
                    cropRect: cropRect,
                    imageSize: image.size,
                    displayedImageRect: displayedRect
                )
                return PhotoEditorCropHandler.cropImage(image, to: scaledCropRect)
            }
            .bind { croppedImage in
                croppedImageRelay.accept(croppedImage)
                currentEditingImageRelay.accept(croppedImage)
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
            originalImage: Driver.just(originalImage),
            currentEditingImage: currentEditingImageRelay.asDriver(),
            croppedImage: croppedImageRelay.asDriver(),
            filteredImage: filteredImageRelay.asDriver(),
            stickers: stickersRelay.asDriver(),
            selectedSticker: selectedSticker,
            selectedPhoto: selectedPhoto,
            navigateToMetadata: navigateToMetadata,
            dismiss: dismiss
        )
    }

    // MARK: - Private Methods
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