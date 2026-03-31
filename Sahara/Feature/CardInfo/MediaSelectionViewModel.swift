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
    case filePicker
}

struct Album {
    let collection: PHAssetCollection?
    let title: String
    let count: Int
    let thumbnailAsset: PHAsset?
}

final class MediaSelectionViewModel: BaseViewModelProtocol {
    private let disposeBag = DisposeBag()

    struct Input {
        let viewWillAppear: Observable<Void>
        let cameraButtonTapped: Observable<Void>
        let libraryButtonTapped: Observable<Void>
        let filePickerButtonTapped: Observable<Void>
        let photoSelected: Observable<PHAsset>
        let imagePickerResult: Observable<(ImageSourceData, CLLocation?, Date?, MediaSource)>
        let albumSelected: Observable<Int>
    }

    struct Output {
        let photos: Driver<[PHAsset]>
        let showActionButtons: Driver<Bool>
        let showCamera: Driver<Void>
        let showPHPicker: Driver<Void>
        let showFilePicker: Driver<Void>
        let showCameraPermissionAlert: Driver<Void>
        let showPhotoPermissionAlert: Driver<Void>
        let selectedMedia: Driver<(ImageSourceData, CLLocation?, Date?)>
        let requestPhotoPermission: Driver<Void>
        let requestCameraPermission: Driver<Void>
        let showLimitedLibraryPicker: Driver<Void>
        let albums: Driver<[Album]>
        let currentAlbumTitle: Driver<String>
        let currentAlbumCount: Driver<Int>
        let permissionStatus: Driver<PHAuthorizationStatus>
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
        let showFilePickerRelay = PublishRelay<Void>()
        let albumsRelay = BehaviorRelay<[Album]>(value: [])
        let selectedAlbumIndexRelay = BehaviorRelay<Int>(value: 0)
        let permissionStatusRelay = BehaviorRelay<PHAuthorizationStatus>(
            value: PHPhotoLibrary.authorizationStatus(for: .readWrite)
        )

        input.viewWillAppear
            .bind(with: self) { owner, _ in
                let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
                permissionStatusRelay.accept(status)

                owner.handleInitialPhotoLoad(
                    photosRelay: photosRelay,
                    albumsRelay: albumsRelay,
                    selectedAlbumIndexRelay: selectedAlbumIndexRelay,
                    requestPhotoPermissionRelay: requestPhotoPermissionRelay
                )
            }
            .disposed(by: disposeBag)

        input.albumSelected
            .bind(with: self) { owner, index in
                selectedAlbumIndexRelay.accept(index)
                owner.fetchPhotosForAlbum(
                    at: index,
                    albumsRelay: albumsRelay,
                    photosRelay: photosRelay
                )
            }
            .disposed(by: disposeBag)

        input.cameraButtonTapped
            .bind(with: self) { owner, _ in
                let status = PermissionService.shared.checkPermission(for: .camera)

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
                owner.handleLibraryButtonTapped(
                    showPHPickerRelay: showPHPickerRelay,
                    showPhotoPermissionAlertRelay: showPhotoPermissionAlertRelay,
                    requestPhotoPermissionRelay: requestPhotoPermissionRelay,
                    showLimitedLibraryPickerRelay: showLimitedLibraryPickerRelay
                )
            }
            .disposed(by: disposeBag)

        input.filePickerButtonTapped
            .do(onNext: { _ in
                AnalyticsService.shared.logPhotoSourceSelected(source: "file_picker")
            })
            .bind(to: showFilePickerRelay)
            .disposed(by: disposeBag)

        input.photoSelected
            .withUnretained(self)
            .do(onNext: { _ in
                AnalyticsService.shared.logPhotoSourceSelected(source: "gallery")
            })
            .flatMap { owner, asset -> Observable<(ImageSourceData, CLLocation?, Date?)> in
                return owner.loadImage(from: asset)
            }
            .bind(to: selectedMediaRelay)
            .disposed(by: disposeBag)

        input.imagePickerResult
            .do(onNext: { _, _, _, source in
                let sourceString: String
                switch source {
                case .camera: sourceString = "camera"
                case .library: sourceString = "library"
                case .filePicker: sourceString = "file_picker"
                }
                AnalyticsService.shared.logPhotoSourceSelected(source: sourceString)
            })
            .map { imageSource, location, date, _ in (imageSource, location, date) }
            .bind(to: selectedMediaRelay)
            .disposed(by: disposeBag)

        let showActionButtons = Observable.just(true)
            .asDriver(onErrorJustReturn: true)

        let currentAlbumTitle = Observable
            .combineLatest(albumsRelay, selectedAlbumIndexRelay)
            .map { albums, index -> String in
                guard index < albums.count else {
                    return NSLocalizedString("media_selection.all_photos", comment: "")
                }
                return albums[index].title
            }
            .asDriver(onErrorJustReturn: NSLocalizedString("media_selection.all_photos", comment: ""))

        let currentAlbumCount = Observable
            .combineLatest(albumsRelay, selectedAlbumIndexRelay)
            .map { albums, index -> Int in
                guard index < albums.count else { return 0 }
                return albums[index].count
            }
            .asDriver(onErrorJustReturn: 0)

        return Output(
            photos: photosRelay.asDriver(),
            showActionButtons: showActionButtons,
            showCamera: showCameraRelay.asDriver(onErrorJustReturn: ()),
            showPHPicker: showPHPickerRelay.asDriver(onErrorJustReturn: ()),
            showFilePicker: showFilePickerRelay.asDriver(onErrorJustReturn: ()),
            showCameraPermissionAlert: showCameraPermissionAlertRelay.asDriver(onErrorJustReturn: ()),
            showPhotoPermissionAlert: showPhotoPermissionAlertRelay.asDriver(onErrorJustReturn: ()),
            selectedMedia: selectedMediaRelay.asDriver(onErrorDriveWith: .empty()),
            requestPhotoPermission: requestPhotoPermissionRelay.asDriver(onErrorJustReturn: ()),
            requestCameraPermission: requestCameraPermissionRelay.asDriver(onErrorJustReturn: ()),
            showLimitedLibraryPicker: showLimitedLibraryPickerRelay.asDriver(onErrorJustReturn: ()),
            albums: albumsRelay.asDriver(),
            currentAlbumTitle: currentAlbumTitle,
            currentAlbumCount: currentAlbumCount,
            permissionStatus: permissionStatusRelay.asDriver()
        )
    }

    private func handleInitialPhotoLoad(
        photosRelay: BehaviorRelay<[PHAsset]>,
        albumsRelay: BehaviorRelay<[Album]>,
        selectedAlbumIndexRelay: BehaviorRelay<Int>,
        requestPhotoPermissionRelay: PublishRelay<Void>
    ) {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        if status == .notDetermined {
            requestPhotoPermissionRelay.accept(())
            return
        }
        fetchAlbums(albumsRelay: albumsRelay)
        selectedAlbumIndexRelay.accept(0)
        fetchPhotosForAlbum(at: 0, albumsRelay: albumsRelay, photosRelay: photosRelay)
    }

    private func handleLibraryButtonTapped(
        showPHPickerRelay: PublishRelay<Void>,
        showPhotoPermissionAlertRelay: PublishRelay<Void>,
        requestPhotoPermissionRelay: PublishRelay<Void>,
        showLimitedLibraryPickerRelay: PublishRelay<Void>
    ) {
        let status = PermissionService.shared.checkPermission(for: .photoLibrary)
        #if targetEnvironment(macCatalyst)
        switch status {
        case .authorized:
            showPHPickerRelay.accept(())
        case .notDetermined:
            requestPhotoPermissionRelay.accept(())
        case .denied, .limited:
            showPHPickerRelay.accept(())
        }
        #else
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

    private func fetchAlbums(albumsRelay: BehaviorRelay<[Album]>) {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        guard status == .authorized || status == .limited else {
            albumsRelay.accept([])
            return
        }

        let isLimited = status == .limited
        var albums: [Album] = []

        let allPhotosOptions = PHFetchOptions()
        allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let allPhotosResult = PHAsset.fetchAssets(with: .image, options: allPhotosOptions)
        let allPhotosTitle = isLimited
            ? NSLocalizedString("media_selection.allowed_photos", comment: "")
            : NSLocalizedString("media_selection.all_photos", comment: "")

        albums.append(Album(
            collection: nil,
            title: allPhotosTitle,
            count: allPhotosResult.count,
            thumbnailAsset: allPhotosResult.firstObject
        ))

        let smartAlbumSubtypes: [PHAssetCollectionSubtype] = [
            .smartAlbumRecentlyAdded,
            .smartAlbumFavorites,
            .smartAlbumSelfPortraits,
            .smartAlbumScreenshots,
            .smartAlbumLivePhotos,
            .smartAlbumPanoramas
        ]

        for subtype in smartAlbumSubtypes {
            let result = PHAssetCollection.fetchAssetCollections(
                with: .smartAlbum, subtype: subtype, options: nil
            )
            result.enumerateObjects { collection, _, _ in
                let fetchOptions = PHFetchOptions()
                fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
                let assets = PHAsset.fetchAssets(in: collection, options: fetchOptions)
                guard assets.count > 0 else { return }

                albums.append(Album(
                    collection: collection,
                    title: collection.localizedTitle ?? "",
                    count: assets.count,
                    thumbnailAsset: assets.firstObject
                ))
            }
        }

        let userAlbums = PHAssetCollection.fetchAssetCollections(
            with: .album, subtype: .any, options: nil
        )
        userAlbums.enumerateObjects { collection, _, _ in
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
            let assets = PHAsset.fetchAssets(in: collection, options: fetchOptions)
            guard assets.count > 0 else { return }

            albums.append(Album(
                collection: collection,
                title: collection.localizedTitle ?? "",
                count: assets.count,
                thumbnailAsset: assets.firstObject
            ))
        }

        albumsRelay.accept(albums)
    }

    private func fetchPhotosForAlbum(
        at index: Int,
        albumsRelay: BehaviorRelay<[Album]>,
        photosRelay: BehaviorRelay<[PHAsset]>
    ) {
        let albums = albumsRelay.value
        guard index < albums.count else {
            photosRelay.accept([])
            return
        }

        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        guard status == .authorized || status == .limited else {
            photosRelay.accept([])
            return
        }

        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

        let results: PHFetchResult<PHAsset>
        if let collection = albums[index].collection {
            fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
            results = PHAsset.fetchAssets(in: collection, options: fetchOptions)
        } else {
            results = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        }

        var photos: [PHAsset] = []
        results.enumerateObjects { asset, _, _ in
            photos.append(asset)
        }
        photosRelay.accept(photos)
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
                    format = ImageFormatConverter.detectFromUTI(uti as String)
                } else {
                    format = ImageFormatConverter.detect(from: data)
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
