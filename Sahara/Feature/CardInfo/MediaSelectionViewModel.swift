//
//  MediaSelectionViewModel.swift
//  Sahara
//
//  Created by 금가경 on 10/9/25.
//

import AVFoundation
import CoreLocation
import Foundation
import Photos
import PhotosUI
import RxCocoa
import RxSwift
import UIKit

enum MediaSource {
    case camera
    case library
}

final class MediaSelectionViewModel: BaseViewModelProtocol {
    private let disposeBag = DisposeBag()

    struct Input {
        let viewWillAppear: Observable<Void>
        let cameraButtonTapped: Observable<Void>
        let libraryButtonTapped: Observable<Void>
        let photoSelected: Observable<PHAsset>
        let imagePickerResult: Observable<(ImageSourceData, CLLocation?, Date?, MediaSource)>
    }

    struct Output {
        let photos: Driver<[PHAsset]>
        let showActionButtons: Driver<Bool>
        let showCamera: Driver<Void>
        let showPHPicker: Driver<Void>
        let showCameraPermissionAlert: Driver<Void>
        let showPhotoPermissionAlert: Driver<Void>
        let selectedMedia: Driver<(ImageSourceData, CLLocation?, Date?)>
        let requestPhotoPermission: Driver<Void>
        let requestCameraPermission: Driver<Void>
        let showLimitedLibraryPicker: Driver<Void>
    }

    func transform(input: Input) -> Output {
        let photosRelay = BehaviorRelay<[PHAsset]>(value: [])
        let showCameraRelay = PublishRelay<Void>()
        let showPHPickerRelay = PublishRelay<Void>()
        let showCameraPermissionAlertRelay = PublishRelay<Void>()
        let showPhotoPermissionAlertRelay = PublishRelay<Void>()
        let selectedMediaRelay = PublishRelay<(ImageSourceData, CLLocation?, Date?)>()
        let requestPhotoPermissionRelay = PublishRelay<Void>()
        let requestCameraPermissionRelay = PublishRelay<Void>()
        let showLimitedLibraryPickerRelay = PublishRelay<Void>()

        input.viewWillAppear
            .bind(with: self) { owner, _ in
                #if targetEnvironment(macCatalyst)
                let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
                if status == .notDetermined {
                    requestPhotoPermissionRelay.accept(())
                    return
                }
                #endif
                owner.fetchPhotos(relay: photosRelay)
            }
            .disposed(by: disposeBag)

        input.cameraButtonTapped
            .bind(with: self) { owner, _ in
                let status = PermissionManager.shared.checkPermission(for: .camera)

                switch status {
                case .authorized:
                    showCameraRelay.accept(())
                case .denied:
                    showCameraPermissionAlertRelay.accept(())
                case .notDetermined:
                    requestCameraPermissionRelay.accept(())
                case .limited:
                    break
                }
            }
            .disposed(by: disposeBag)

        input.libraryButtonTapped
            .bind(with: self) { owner, _ in
                #if targetEnvironment(macCatalyst)
                let status = PermissionManager.shared.checkPermission(for: .photoLibrary)
                switch status {
                case .authorized:
                    showPHPickerRelay.accept(())
                case .notDetermined:
                    requestPhotoPermissionRelay.accept(())
                case .denied, .limited:
                    showPHPickerRelay.accept(())
                }
                #else
                let status = PermissionManager.shared.checkPermission(for: .photoLibrary)

                switch status {
                case .authorized:
                    showPHPickerRelay.accept(())
                case .limited:
                    showLimitedLibraryPickerRelay.accept(())
                case .denied:
                    showPhotoPermissionAlertRelay.accept(())
                case .notDetermined:
                    requestPhotoPermissionRelay.accept(())
                }
                #endif
            }
            .disposed(by: disposeBag)

        input.photoSelected
            .withUnretained(self)
            .do(onNext: { _ in
                AnalyticsManager.shared.logPhotoSourceSelected(source: "gallery")
            })
            .flatMap { owner, asset -> Observable<(ImageSourceData, CLLocation?, Date?)> in
                return owner.loadImage(from: asset)
            }
            .bind(to: selectedMediaRelay)
            .disposed(by: disposeBag)

        input.imagePickerResult
            .do(onNext: { _, _, _, source in
                let sourceString = source == .camera ? "camera" : "library"
                AnalyticsManager.shared.logPhotoSourceSelected(source: sourceString)
            })
            .map { imageSource, location, date, _ in (imageSource, location, date) }
            .bind(to: selectedMediaRelay)
            .disposed(by: disposeBag)

        let showActionButtons = Observable.just(true)
            .asDriver(onErrorJustReturn: true)

        return Output(
            photos: photosRelay.asDriver(),
            showActionButtons: showActionButtons,
            showCamera: showCameraRelay.asDriver(onErrorJustReturn: ()),
            showPHPicker: showPHPickerRelay.asDriver(onErrorJustReturn: ()),
            showCameraPermissionAlert: showCameraPermissionAlertRelay.asDriver(onErrorJustReturn: ()),
            showPhotoPermissionAlert: showPhotoPermissionAlertRelay.asDriver(onErrorJustReturn: ()),
            selectedMedia: selectedMediaRelay.asDriver(onErrorDriveWith: .empty()),
            requestPhotoPermission: requestPhotoPermissionRelay.asDriver(onErrorJustReturn: ()),
            requestCameraPermission: requestCameraPermissionRelay.asDriver(onErrorJustReturn: ()),
            showLimitedLibraryPicker: showLimitedLibraryPickerRelay.asDriver(onErrorJustReturn: ())
        )
    }

    private func fetchPhotos(relay: BehaviorRelay<[PHAsset]>) {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        guard status == .authorized || status == .limited else {
            relay.accept([])
            return
        }

        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

        let results = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        var photos: [PHAsset] = []
        results.enumerateObjects { asset, _, _ in
            photos.append(asset)
        }

        relay.accept(photos)
    }

    private func loadImage(from asset: PHAsset) -> Observable<(ImageSourceData, CLLocation?, Date?)> {
        return Observable.create { observer in
            let imageManager = PHCachingImageManager()
            let options = PHImageRequestOptions()
            options.isSynchronous = false
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true

            imageManager.requestImageDataAndOrientation(
                for: asset,
                options: options
            ) { data, uti, orientation, _ in
                guard let data = data,
                      let image = UIImage(data: data) else {
                    observer.onCompleted()
                    return
                }

                let format: ImageSourceData.ImageFormat?
                if let uti = uti {
                    format = ImageFormatHelper.detectFromUTI(uti as String)
                } else {
                    format = ImageFormatHelper.detect(from: data)
                }

                let imageSource = ImageSourceData(
                    image: image,
                    originalData: data,
                    format: format
                )

                let location = asset.location
                let date = asset.creationDate
                observer.onNext((imageSource, location, date))
                observer.onCompleted()
            }

            return Disposables.create()
        }
    }
}
