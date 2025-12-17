//
//  CardInfoViewModel.swift
//  Sahara
//
//  Created by 금가경 on 9/26/25.
//

import CoreLocation
import Foundation
import OSLog
import RealmSwift
import RxCocoa
import RxSwift
import UIKit

enum EditSourceType {
    case dateView
    case locationView
    case themeView
    case searchView
}

final class CardInfoViewModel: BaseViewModelProtocol {
    private let disposeBag = DisposeBag()
    private let realmManager: RealmManagerProtocol
    private let ocrManager: OCRManagerProtocol
    private var editedImage: UIImage?
    private var imageSourceData: ImageSourceData?
    private var wasImageEdited: Bool = false
    private var cardToEditId: ObjectId?
    private var originalDate: Date?
    private var originalLocation: CLLocation?
    private var sourceType: EditSourceType?
    private var imageChanged = false
    private var initialMemo: String?
    private var initialIsLocked: Bool = false
    private var initialCustomFolder: String?
    private var currentFilterIndex: Int?
    private var currentCropMetadata: CropMetadata?
    private var currentRotationAngle: Double = 0.0

    struct Input {
        let selectedImage: Observable<UIImage?>
        let imageSourceData: Observable<ImageSourceData?>
        let wasEdited: Observable<Bool>
        let selectedFilterIndex: Observable<Int?>
        let cropMetadata: Observable<CropMetadata?>
        let rotationAngle: Observable<Double>
        let date: Observable<Date>
        let memo: Observable<String?>
        let customFolder: Observable<String?>
        let location: Observable<CLLocation?>
        let isLocked: Observable<Bool>
        let saveButtonTapped: Observable<Void>
        let cancelButtonTapped: Observable<Void>
        let deleteButtonTapped: Observable<Void>
    }

    struct Output {
        let editedImage: Driver<UIImage?>
        let hasImage: Driver<Bool>
        let location: Driver<CLLocation>
        let saved: Driver<Bool>
        let saveError: Driver<String>
        let dismiss: Driver<Void>
        let isEditMode: Bool
        let initialDate: Date
        let initialMemo: String?
        let initialCustomFolder: String?
        let initialLocation: CLLocation?
        let initialIsLocked: Bool
        let deleted: Driver<Void>
        let shouldPopToList: Driver<Bool>
        let shouldPopToListOnDelete: Driver<Bool>
    }

    init(editedImage: UIImage?, realmManager: RealmManagerProtocol = RealmManager.shared, ocrManager: OCRManagerProtocol = OCRManager.shared) {
        self.realmManager = realmManager
        self.ocrManager = ocrManager
        self.editedImage = editedImage
        self.cardToEditId = nil
        self.sourceType = nil
    }

    init(initialDate: Date, sourceType: EditSourceType, realmManager: RealmManagerProtocol = RealmManager.shared, ocrManager: OCRManagerProtocol = OCRManager.shared) {
        self.realmManager = realmManager
        self.ocrManager = ocrManager
        self.editedImage = nil
        self.cardToEditId = nil
        self.originalDate = initialDate
        self.sourceType = sourceType
    }

    init(cardToEdit cardId: ObjectId, sourceType: EditSourceType, realmManager: RealmManagerProtocol = RealmManager.shared, ocrManager: OCRManagerProtocol = OCRManager.shared) {
        self.realmManager = realmManager
        self.ocrManager = ocrManager
        self.cardToEditId = cardId
        self.sourceType = sourceType

        guard let card = realmManager.fetchObject(Card.self, forPrimaryKey: cardId) else {
            return
        }

        self.editedImage = UIImage(data: card.editedImageData)

        let stickers = Array(card.stickers.map { StickerDTO(from: $0) })
        self.originalDate = card.date
        self.initialMemo = card.memo
        self.initialIsLocked = card.isLocked
        self.initialCustomFolder = card.customFolder
        if let lat = card.latitude, let lon = card.longitude {
            self.originalLocation = CLLocation(latitude: lat, longitude: lon)
        }

        let format: ImageSourceData.ImageFormat? = {
            if let formatString = card.imageFormat {
                return ImageSourceData.ImageFormat(rawValue: formatString)
            }
            return nil
        }()

        if let editedImage = self.editedImage {
            self.imageSourceData = ImageSourceData(
                image: editedImage,
                originalData: card.originalImageData,
                format: format,
                stickers: stickers
            )
        }
    }

    func transform(input: Input) -> Output {
        let isEditMode = cardToEditId != nil
        let initialLocation: CLLocation? = originalLocation

        let locationRelay = BehaviorRelay<CLLocation?>(value: initialLocation)
        let imageRelay = BehaviorRelay<UIImage?>(value: editedImage)

        input.selectedImage
            .compactMap { $0 }
            .bind(with: self) { owner, image in
                owner.editedImage = image
                imageRelay.accept(image)
                if owner.cardToEditId != nil {
                    owner.imageChanged = true
                }
            }
            .disposed(by: disposeBag)

        input.imageSourceData
            .bind(with: self) { owner, imageSource in
                owner.imageSourceData = imageSource
            }
            .disposed(by: disposeBag)

        input.wasEdited
            .bind(with: self) { owner, wasEdited in
                owner.wasImageEdited = wasEdited
            }
            .disposed(by: disposeBag)

        input.selectedFilterIndex
            .bind(with: self) { owner, index in
                owner.currentFilterIndex = index
            }
            .disposed(by: disposeBag)

        input.cropMetadata
            .bind(with: self) { owner, metadata in
                owner.currentCropMetadata = metadata
            }
            .disposed(by: disposeBag)

        input.rotationAngle
            .bind(with: self) { owner, angle in
                owner.currentRotationAngle = angle
            }
            .disposed(by: disposeBag)

        input.location
            .bind(to: locationRelay)
            .disposed(by: disposeBag)

        let saveErrorRelay = PublishRelay<String>()
        let shouldPopToListRelay = PublishRelay<Bool>()
        let shouldPopToListOnDeleteRelay = PublishRelay<Bool>()

        let saved = input.saveButtonTapped
            .withLatestFrom(
                Observable.combineLatest(
                    input.date,
                    input.memo,
                    input.customFolder,
                    locationRelay.asObservable(),
                    input.isLocked
                )
            )
            .do(onNext: { [weak self] _, memo, _, location, isLocked in
                guard let self = self else { return }
                AnalyticsManager.shared.logCardSave(
                    hasPhoto: self.editedImage != nil,
                    hasMemo: !(memo?.isEmpty ?? true),
                    hasLocation: location != nil,
                    isLocked: isLocked
                )
            })
            .flatMap { [weak self] date, memo, customFolder, location, isLocked -> Observable<Bool> in
                guard let self = self else { return .just(false) }

                if self.editedImage == nil {
                    saveErrorRelay.accept(NSLocalizedString("card_info.image_required", comment: ""))
                    return .just(false)
                }

                if let cardId = self.cardToEditId {
                    let shouldPop = self.shouldPopToList(newDate: date, newLocation: location)
                    shouldPopToListRelay.accept(shouldPop)

                    if shouldPop {
                        return self.replaceCardObservable(cardId: cardId, date: date, memo: memo, customFolder: customFolder, location: location, isLocked: isLocked)
                            .map { true }
                    } else {
                        return self.updateCardObservable(cardId: cardId, date: date, memo: memo, customFolder: customFolder, location: location, isLocked: isLocked)
                            .map { true }
                    }
                } else {
                    shouldPopToListRelay.accept(false)
                    return self.saveToRealmObservable(date: date, memo: memo, customFolder: customFolder, location: location, isLocked: isLocked)
                        .map { true }
                }
            }
            .asDriver(onErrorJustReturn: false)

        let deleted = input.deleteButtonTapped
            .withUnretained(self)
            .do(onNext: { owner, _ in
                AnalyticsManager.shared.logCardDelete()
            })
            .flatMap { owner, _ -> Observable<Void> in
                guard let cardId = owner.cardToEditId else { return .just(()) }

                return owner.realmManager.delete(Card.self, forPrimaryKey: cardId)
                    .do(onNext: { _ in
                        if owner.sourceType != nil {
                            shouldPopToListOnDeleteRelay.accept(true)
                        } else {
                            shouldPopToListOnDeleteRelay.accept(false)
                        }
                    })
            }
            .asDriver(onErrorJustReturn: ())

        let dismiss = input.cancelButtonTapped
            .asDriver(onErrorJustReturn: ())

        let hasImage = imageRelay.map { $0 != nil }.asDriver(onErrorJustReturn: false)

        return Output(
            editedImage: imageRelay.asDriver(),
            hasImage: hasImage,
            location: locationRelay.compactMap { $0 }.asDriver(onErrorDriveWith: .empty()),
            saved: saved,
            saveError: saveErrorRelay.asDriver(onErrorJustReturn: ""),
            dismiss: dismiss,
            isEditMode: isEditMode,
            initialDate: originalDate ?? Date(),
            initialMemo: initialMemo,
            initialCustomFolder: initialCustomFolder,
            initialLocation: initialLocation,
            initialIsLocked: initialIsLocked,
            deleted: deleted,
            shouldPopToList: shouldPopToListRelay.asDriver(onErrorJustReturn: false),
            shouldPopToListOnDelete: shouldPopToListOnDeleteRelay.asDriver(onErrorJustReturn: false)
        )
    }

    private func shouldPopToList(newDate: Date, newLocation: CLLocation?) -> Bool {
        guard let sourceType = sourceType else { return false }

        switch sourceType {
        case .dateView:
            guard let originalDate = originalDate else { return false }
            let calendar = Calendar.current
            let originalDateComponents = calendar.dateComponents([.year, .month, .day], from: originalDate)
            let newDateComponents = calendar.dateComponents([.year, .month, .day], from: newDate)
            return originalDateComponents != newDateComponents

        case .locationView:
            if let originalLocation = originalLocation, let newLocation = newLocation {
                return originalLocation.distance(from: newLocation) > 100
            } else if originalLocation == nil && newLocation != nil {
                return true
            } else if originalLocation != nil && newLocation == nil {
                return true
            } else {
                return false
            }

        case .themeView:
            return imageChanged

        case .searchView:
            return false
        }
    }

    private func saveToRealmObservable(date: Date, memo: String?, customFolder: String?, location: CLLocation?, isLocked: Bool = false) -> Observable<Void> {
        guard let editedImage = editedImage else { return .empty() }

        let stickers = imageSourceData?.stickers ?? []
        let memoText: String? = {
            guard let memo = memo, !memo.isEmpty else { return nil }
            return memo
        }()
        let folderText: String? = {
            guard let customFolder = customFolder, !customFolder.isEmpty else { return nil }
            return customFolder
        }()
        let isFirstCard = realmManager.isEmpty(Card.self)
        let allCards = realmManager.fetch(Card.self)
        let hadLocationBefore = allCards.contains { $0.latitude != nil && $0.longitude != nil }

        if !stickers.isEmpty, wasImageEdited, let imageSource = imageSourceData {
            return Observable.create { [weak self] observer in
                guard let self = self else {
                    observer.onCompleted()
                    return Disposables.create()
                }

                let resizedImage = editedImage.resized()
                MediaEditorImageHandler.compositeStickersOnImage(resizedImage, stickers: stickers) { compositedImage, isAnimatedFlags in
                    let conversionResult = ImageFormatHelper.convertImages(
                        editedImage: compositedImage,
                        originalImage: resizedImage,
                        sourceFormat: imageSource.format
                    )
                    let editedImageData = conversionResult.editedImageData
                    let originalImageData: Data? = conversionResult.originalImageData
                    let imageFormat: String? = conversionResult.imageFormat

                    self.ocrManager.recognizeText(from: editedImage)
                        .subscribe(
                            onNext: { ocrText in
                                let card = Card(
                                    date: date,
                                    createdDate: Date(),
                                    editedImageData: editedImageData,
                                    memo: memoText,
                                    latitude: location?.coordinate.latitude,
                                    longitude: location?.coordinate.longitude,
                                    isLocked: isLocked
                                )
                                card.customFolder = folderText
                                card.ocrText = ocrText
                                card.originalImageData = originalImageData
                                card.imageFormat = imageFormat
                                card.wasEdited = self.wasImageEdited

                                Logger.database.notice("Saved card metadata: filter=\(self.currentFilterIndex.orNil), crop=\(self.currentCropMetadata.presenceLog)")

                                card.appliedFilterIndex = self.currentFilterIndex
                                card.cropMetadata = self.currentCropMetadata
                                card.rotationAngle = self.currentRotationAngle

                                for (index, stickerDTO) in stickers.enumerated() {
                                    let isAnimated = index < isAnimatedFlags.count ? isAnimatedFlags[index] : false
                                    let stickerObject = Sticker(
                                        x: stickerDTO.x,
                                        y: stickerDTO.y,
                                        scale: stickerDTO.scale,
                                        rotation: stickerDTO.rotation,
                                        zIndex: stickerDTO.zIndex,
                                        sourceType: stickerDTO.sourceType,
                                        resourceUrl: stickerDTO.resourceUrl,
                                        localFilePath: stickerDTO.localFilePath,
                                        photoAssetId: stickerDTO.photoAssetId,
                                        isAnimated: isAnimated
                                    )
                                    card.stickers.append(stickerObject)
                                }

                                self.realmManager.add(card)
                                    .subscribe(
                                        onNext: {
                                            if isFirstCard {
                                                AnalyticsManager.shared.logFirstCardCreated()
                                            }
                                            if !hadLocationBefore && location != nil {
                                                AnalyticsManager.shared.logFirstLocationAdded()
                                            }
                                            observer.onNext(())
                                            observer.onCompleted()
                                        },
                                        onError: { error in
                                            observer.onError(error)
                                        }
                                    )
                                    .disposed(by: self.disposeBag)
                            },
                            onError: { error in
                                observer.onError(error)
                            }
                        )
                        .disposed(by: self.disposeBag)
                }

                return Disposables.create()
            }
        } else {
            let editedImageData: Data
            var originalImageData: Data?
            var imageFormat: String?

            if wasImageEdited {
                let resizedImage = editedImage.resized()

                if let imageSource = imageSourceData, let format = imageSource.format {
                    switch format {
                    case .heic:
                        editedImageData = resizedImage.heicData(compressionQuality: 1.0) ?? resizedImage.jpegData(compressionQuality: 1.0)!
                        imageFormat = "heic"
                    case .png:
                        editedImageData = resizedImage.pngData()!
                        imageFormat = "png"
                    case .jpeg:
                        editedImageData = resizedImage.jpegData(compressionQuality: 1.0)!
                        imageFormat = "jpeg"
                    }
                } else {
                    let hasAlpha: Bool
                    if let alphaInfo = resizedImage.cgImage?.alphaInfo {
                        hasAlpha = !(alphaInfo == .none || alphaInfo == .noneSkipFirst || alphaInfo == .noneSkipLast)
                    } else {
                        hasAlpha = false
                    }

                    if hasAlpha {
                        editedImageData = resizedImage.pngData()!
                        imageFormat = "png"
                    } else {
                        editedImageData = resizedImage.jpegData(compressionQuality: 1.0)!
                        imageFormat = "jpeg"
                    }
                }
                originalImageData = nil
            } else {
                if let imageSource = imageSourceData,
                   let original = imageSource.originalData,
                   let format = imageSource.format {
                    editedImageData = original
                    originalImageData = original
                    imageFormat = format.rawValue
                } else {
                    let resizedImage = editedImage.resized()

                    let hasAlpha: Bool
                    if let alphaInfo = resizedImage.cgImage?.alphaInfo {
                        hasAlpha = !(alphaInfo == .none || alphaInfo == .noneSkipFirst || alphaInfo == .noneSkipLast)
                    } else {
                        hasAlpha = false
                    }

                    if hasAlpha {
                        editedImageData = resizedImage.pngData()!
                        imageFormat = "png"
                    } else {
                        editedImageData = resizedImage.jpegData(compressionQuality: 1.0)!
                        imageFormat = "jpeg"
                    }
                }
            }

            return ocrManager.recognizeText(from: editedImage)
                .flatMap { [weak self] ocrText -> Observable<Void> in
                    guard let self = self else { return .empty() }

                    let card = Card(
                        date: date,
                        createdDate: Date(),
                        editedImageData: editedImageData,
                        memo: memoText,
                        latitude: location?.coordinate.latitude,
                        longitude: location?.coordinate.longitude,
                        isLocked: isLocked
                    )
                    card.customFolder = folderText
                    card.ocrText = ocrText
                    card.originalImageData = originalImageData
                    card.imageFormat = imageFormat
                    card.wasEdited = self.wasImageEdited

                    Logger.database.notice("Saved card metadata: filter=\(self.currentFilterIndex.orNil), crop=\(self.currentCropMetadata.presenceLog)")

                    card.appliedFilterIndex = self.currentFilterIndex
                    card.cropMetadata = self.currentCropMetadata
                    card.rotationAngle = self.currentRotationAngle

                    for stickerDTO in stickers {
                        let stickerObject = Sticker(
                            x: stickerDTO.x,
                            y: stickerDTO.y,
                            scale: stickerDTO.scale,
                            rotation: stickerDTO.rotation,
                            zIndex: stickerDTO.zIndex,
                            sourceType: stickerDTO.sourceType,
                            resourceUrl: stickerDTO.resourceUrl,
                            localFilePath: stickerDTO.localFilePath,
                            photoAssetId: stickerDTO.photoAssetId,
                            isAnimated: stickerDTO.isAnimated
                        )
                        card.stickers.append(stickerObject)
                    }

                    return self.realmManager.add(card)
                        .observe(on: MainScheduler.instance)
                        .do(onNext: {
                            if isFirstCard {
                                AnalyticsManager.shared.logFirstCardCreated()
                            }
                            if !hadLocationBefore && location != nil {
                                AnalyticsManager.shared.logFirstLocationAdded()
                            }
                        })
                }
        }
    }

    private func updateCardObservable(cardId: ObjectId, date: Date, memo: String?, customFolder: String?, location: CLLocation?, isLocked: Bool = false) -> Observable<Void> {
        guard let editedImage = editedImage else { return .empty() }

        let stickers = imageSourceData?.stickers ?? []
        let memoText: String? = {
            guard let memo = memo, !memo.isEmpty else { return nil }
            return memo
        }()
        let folderText: String? = {
            guard let customFolder = customFolder, !customFolder.isEmpty else { return nil }
            return customFolder
        }()

        guard let card = realmManager.fetchObject(Card.self, forPrimaryKey: cardId) else { return .empty() }

        let oldOcrText = card.ocrText
        let oldLatitude = card.latitude
        let oldLongitude = card.longitude
        let allCards = realmManager.fetch(Card.self)
        let hadLocationBefore = allCards.contains { $0.latitude != nil && $0.longitude != nil }

        var editTypes: [String] = []
        if imageChanged {
            editTypes.append("photo")
        }
        if initialMemo != memoText {
            editTypes.append("memo")
        }
        if initialCustomFolder != folderText {
            editTypes.append("folder")
        }
        let oldLocation = (oldLatitude != nil && oldLongitude != nil) ? CLLocation(latitude: oldLatitude!, longitude: oldLongitude!) : nil
        if (oldLocation == nil && location != nil) || (oldLocation != nil && location == nil) || (oldLocation != nil && location != nil && oldLocation!.distance(from: location!) > 1) {
            editTypes.append("location")
        }
        if initialIsLocked != isLocked {
            editTypes.append("lock")
        }

        let ocrObservable = imageChanged ? ocrManager.recognizeText(from: editedImage) : Observable.just(oldOcrText)

        if !stickers.isEmpty, wasImageEdited, let imageSource = imageSourceData {
            return Observable.create { [weak self] observer in
                guard let self = self else {
                    observer.onCompleted()
                    return Disposables.create()
                }

                let resizedImage = editedImage.resized()
                MediaEditorImageHandler.compositeStickersOnImage(resizedImage, stickers: stickers) { compositedImage, isAnimatedFlags in
                    let conversionResult = ImageFormatHelper.convertImages(
                        editedImage: compositedImage,
                        originalImage: resizedImage,
                        sourceFormat: imageSource.format
                    )
                    let editedImageData = conversionResult.editedImageData
                    let originalImageData: Data? = conversionResult.originalImageData
                    let imageFormat: String? = conversionResult.imageFormat

                    ocrObservable
                        .subscribe(
                            onNext: { ocrText in
                                self.realmManager.update { realm in
                                    guard let card = realm.object(ofType: Card.self, forPrimaryKey: cardId) else { return }
                                    card.date = date
                                    card.editedImageData = editedImageData
                                    card.originalImageData = originalImageData
                                    card.imageFormat = imageFormat
                                    card.wasEdited = self.wasImageEdited

                                    Logger.database.notice("Updated card metadata: filter=\(self.currentFilterIndex.orNil), crop=\(self.currentCropMetadata.presenceLog)")

                                    card.appliedFilterIndex = self.currentFilterIndex
                                    card.cropMetadata = self.currentCropMetadata
                                    card.rotationAngle = self.currentRotationAngle

                                    card.memo = memoText
                                    card.customFolder = folderText
                                    card.isLocked = isLocked
                                    card.latitude = location?.coordinate.latitude
                                    card.longitude = location?.coordinate.longitude
                                    card.ocrText = ocrText

                                    card.stickers.removeAll()
                                    for (index, stickerDTO) in stickers.enumerated() {
                                        let isAnimated = index < isAnimatedFlags.count ? isAnimatedFlags[index] : false
                                        let stickerObject = Sticker(
                                            x: stickerDTO.x,
                                            y: stickerDTO.y,
                                            scale: stickerDTO.scale,
                                            rotation: stickerDTO.rotation,
                                            zIndex: stickerDTO.zIndex,
                                            sourceType: stickerDTO.sourceType,
                                            resourceUrl: stickerDTO.resourceUrl,
                                            localFilePath: stickerDTO.localFilePath,
                                            photoAssetId: stickerDTO.photoAssetId,
                                            isAnimated: isAnimated
                                        )
                                        card.stickers.append(stickerObject)
                                    }
                                }
                                .subscribe(
                                    onNext: {
                                        if !editTypes.isEmpty {
                                            AnalyticsManager.shared.logCardEdit(editType: editTypes.joined(separator: ","))
                                        }
                                        if !hadLocationBefore && location != nil {
                                            AnalyticsManager.shared.logFirstLocationAdded()
                                        }
                                        observer.onNext(())
                                        observer.onCompleted()
                                    },
                                    onError: { error in
                                        observer.onError(error)
                                    }
                                )
                                .disposed(by: self.disposeBag)
                            },
                            onError: { error in
                                observer.onError(error)
                            }
                        )
                        .disposed(by: self.disposeBag)
                }

                return Disposables.create()
            }
        } else {
            let editedImageData: Data
            var originalImageData: Data?
            var imageFormat: String?

            if wasImageEdited {
                let resizedImage = editedImage.resized()

                if let imageSource = imageSourceData, let format = imageSource.format {
                    switch format {
                    case .heic:
                        editedImageData = resizedImage.heicData(compressionQuality: 1.0) ?? resizedImage.jpegData(compressionQuality: 1.0)!
                        imageFormat = "heic"
                    case .png:
                        editedImageData = resizedImage.pngData()!
                        imageFormat = "png"
                    case .jpeg:
                        editedImageData = resizedImage.jpegData(compressionQuality: 1.0)!
                        imageFormat = "jpeg"
                    }
                } else {
                    let hasAlpha: Bool
                    if let alphaInfo = resizedImage.cgImage?.alphaInfo {
                        hasAlpha = !(alphaInfo == .none || alphaInfo == .noneSkipFirst || alphaInfo == .noneSkipLast)
                    } else {
                        hasAlpha = false
                    }

                    if hasAlpha {
                        editedImageData = resizedImage.pngData()!
                        imageFormat = "png"
                    } else {
                        editedImageData = resizedImage.jpegData(compressionQuality: 1.0)!
                        imageFormat = "jpeg"
                    }
                }
                originalImageData = nil
            } else {
                if let imageSource = imageSourceData,
                   let original = imageSource.originalData,
                   let format = imageSource.format {
                    editedImageData = original
                    originalImageData = original
                    imageFormat = format.rawValue
                } else {
                    let resizedImage = editedImage.resized()

                    let hasAlpha: Bool
                    if let alphaInfo = resizedImage.cgImage?.alphaInfo {
                        hasAlpha = !(alphaInfo == .none || alphaInfo == .noneSkipFirst || alphaInfo == .noneSkipLast)
                    } else {
                        hasAlpha = false
                    }

                    if hasAlpha {
                        editedImageData = resizedImage.pngData()!
                        imageFormat = "png"
                    } else {
                        editedImageData = resizedImage.jpegData(compressionQuality: 1.0)!
                        imageFormat = "jpeg"
                    }
                }
            }

            return ocrObservable
                .flatMap { [weak self] ocrText -> Observable<Void> in
                    guard let self = self else { return .empty() }

                    return self.realmManager.update { realm in
                        guard let card = realm.object(ofType: Card.self, forPrimaryKey: cardId) else { return }
                        card.date = date
                        card.editedImageData = editedImageData
                        card.originalImageData = originalImageData
                        card.imageFormat = imageFormat
                        card.wasEdited = self.wasImageEdited

                        Logger.database.notice("Replaced card metadata: filter=\(self.currentFilterIndex.orNil), crop=\(self.currentCropMetadata.presenceLog)")

                        card.appliedFilterIndex = self.currentFilterIndex
                        card.cropMetadata = self.currentCropMetadata
                        card.rotationAngle = self.currentRotationAngle

                        card.memo = memoText
                        card.customFolder = folderText
                        card.isLocked = isLocked
                        card.latitude = location?.coordinate.latitude
                        card.longitude = location?.coordinate.longitude
                        card.ocrText = ocrText
                    }
                    .observe(on: MainScheduler.instance)
                    .do(onNext: {
                        if !editTypes.isEmpty {
                            AnalyticsManager.shared.logCardEdit(editType: editTypes.joined(separator: ","))
                        }
                        if !hadLocationBefore && location != nil {
                            AnalyticsManager.shared.logFirstLocationAdded()
                        }
                    })
                }
        }
    }

    private func replaceCardObservable(cardId: ObjectId, date: Date, memo: String?, customFolder: String?, location: CLLocation?, isLocked: Bool = false) -> Observable<Void> {
        guard let editedImage = editedImage else { return .empty() }

        let stickers = imageSourceData?.stickers ?? []
        let memoText: String? = {
            guard let memo = memo, !memo.isEmpty else { return nil }
            return memo
        }()
        let folderText: String? = {
            guard let customFolder = customFolder, !customFolder.isEmpty else { return nil }
            return customFolder
        }()

        guard let cardToDelete = realmManager.fetchObject(Card.self, forPrimaryKey: cardId) else { return .empty() }

        let oldOcrText = cardToDelete.ocrText
        let oldLatitude = cardToDelete.latitude
        let oldLongitude = cardToDelete.longitude
        let allCards = realmManager.fetch(Card.self)
        let hadLocationBefore = allCards.contains { $0.latitude != nil && $0.longitude != nil }

        var editTypes: [String] = []
        if imageChanged {
            editTypes.append("photo")
        }
        if initialMemo != memoText {
            editTypes.append("memo")
        }
        if initialCustomFolder != folderText {
            editTypes.append("folder")
        }
        let oldLocation = (oldLatitude != nil && oldLongitude != nil) ? CLLocation(latitude: oldLatitude!, longitude: oldLongitude!) : nil
        if (oldLocation == nil && location != nil) || (oldLocation != nil && location == nil) || (oldLocation != nil && location != nil && oldLocation!.distance(from: location!) > 1) {
            editTypes.append("location")
        }
        if initialIsLocked != isLocked {
            editTypes.append("lock")
        }

        let ocrObservable = imageChanged ? ocrManager.recognizeText(from: editedImage) : Observable.just(oldOcrText)

        if !stickers.isEmpty, wasImageEdited, let imageSource = imageSourceData {
            return Observable.create { [weak self] observer in
                guard let self = self else {
                    observer.onCompleted()
                    return Disposables.create()
                }

                let resizedImage = editedImage.resized()
                MediaEditorImageHandler.compositeStickersOnImage(resizedImage, stickers: stickers) { compositedImage, isAnimatedFlags in
                    let conversionResult = ImageFormatHelper.convertImages(
                        editedImage: compositedImage,
                        originalImage: resizedImage,
                        sourceFormat: imageSource.format
                    )
                    let editedImageData = conversionResult.editedImageData
                    let originalImageData: Data? = conversionResult.originalImageData
                    let imageFormat: String? = conversionResult.imageFormat

                    ocrObservable
                        .subscribe(
                            onNext: { ocrText in
                                let newCard = Card(
                                    date: date,
                                    createdDate: Date(),
                                    editedImageData: editedImageData,
                                    memo: memoText,
                                    latitude: location?.coordinate.latitude,
                                    longitude: location?.coordinate.longitude,
                                    isLocked: isLocked
                                )
                                newCard.customFolder = folderText
                                newCard.ocrText = ocrText
                                newCard.originalImageData = originalImageData
                                newCard.imageFormat = imageFormat
                                newCard.wasEdited = self.wasImageEdited

                                for (index, stickerDTO) in stickers.enumerated() {
                                    let isAnimated = index < isAnimatedFlags.count ? isAnimatedFlags[index] : false
                                    let stickerObject = Sticker(
                                        x: stickerDTO.x,
                                        y: stickerDTO.y,
                                        scale: stickerDTO.scale,
                                        rotation: stickerDTO.rotation,
                                        zIndex: stickerDTO.zIndex,
                                        sourceType: stickerDTO.sourceType,
                                        resourceUrl: stickerDTO.resourceUrl,
                                        localFilePath: stickerDTO.localFilePath,
                                        photoAssetId: stickerDTO.photoAssetId,
                                        isAnimated: isAnimated
                                    )
                                    newCard.stickers.append(stickerObject)
                                }

                                self.realmManager.update { realm in
                                    realm.add(newCard)
                                    if let cardToDelete = realm.object(ofType: Card.self, forPrimaryKey: cardId) {
                                        realm.delete(cardToDelete)
                                    }
                                }
                                .subscribe(
                                    onNext: {
                                        if !editTypes.isEmpty {
                                            AnalyticsManager.shared.logCardEdit(editType: editTypes.joined(separator: ","))
                                        }
                                        if !hadLocationBefore && location != nil {
                                            AnalyticsManager.shared.logFirstLocationAdded()
                                        }
                                        observer.onNext(())
                                        observer.onCompleted()
                                    },
                                    onError: { error in
                                        observer.onError(error)
                                    }
                                )
                                .disposed(by: self.disposeBag)
                            },
                            onError: { error in
                                observer.onError(error)
                            }
                        )
                        .disposed(by: self.disposeBag)
                }

                return Disposables.create()
            }
        } else {
            let editedImageData: Data
            var originalImageData: Data?
            var imageFormat: String?

            if wasImageEdited {
                let resizedImage = editedImage.resized()

                if let imageSource = imageSourceData, let format = imageSource.format {
                    switch format {
                    case .heic:
                        editedImageData = resizedImage.heicData(compressionQuality: 1.0) ?? resizedImage.jpegData(compressionQuality: 1.0)!
                        imageFormat = "heic"
                    case .png:
                        editedImageData = resizedImage.pngData()!
                        imageFormat = "png"
                    case .jpeg:
                        editedImageData = resizedImage.jpegData(compressionQuality: 1.0)!
                        imageFormat = "jpeg"
                    }
                } else {
                    let hasAlpha: Bool
                    if let alphaInfo = resizedImage.cgImage?.alphaInfo {
                        hasAlpha = !(alphaInfo == .none || alphaInfo == .noneSkipFirst || alphaInfo == .noneSkipLast)
                    } else {
                        hasAlpha = false
                    }

                    if hasAlpha {
                        editedImageData = resizedImage.pngData()!
                        imageFormat = "png"
                    } else {
                        editedImageData = resizedImage.jpegData(compressionQuality: 1.0)!
                        imageFormat = "jpeg"
                    }
                }
                originalImageData = nil
            } else {
                if let imageSource = imageSourceData,
                   let original = imageSource.originalData,
                   let format = imageSource.format {
                    editedImageData = original
                    originalImageData = original
                    imageFormat = format.rawValue
                } else {
                    let resizedImage = editedImage.resized()

                    let hasAlpha: Bool
                    if let alphaInfo = resizedImage.cgImage?.alphaInfo {
                        hasAlpha = !(alphaInfo == .none || alphaInfo == .noneSkipFirst || alphaInfo == .noneSkipLast)
                    } else {
                        hasAlpha = false
                    }

                    if hasAlpha {
                        editedImageData = resizedImage.pngData()!
                        imageFormat = "png"
                    } else {
                        editedImageData = resizedImage.jpegData(compressionQuality: 1.0)!
                        imageFormat = "jpeg"
                    }
                }
            }

            return ocrObservable
                .flatMap { [weak self] ocrText -> Observable<Void> in
                    guard let self = self else { return .empty() }

                    let newCard = Card(
                        date: date,
                        createdDate: Date(),
                        editedImageData: editedImageData,
                        memo: memoText,
                        latitude: location?.coordinate.latitude,
                        longitude: location?.coordinate.longitude,
                        isLocked: isLocked
                    )
                    newCard.customFolder = folderText
                    newCard.ocrText = ocrText
                    newCard.originalImageData = originalImageData
                    newCard.imageFormat = imageFormat
                    newCard.wasEdited = self.wasImageEdited

                    for stickerDTO in stickers {
                        let stickerObject = Sticker(
                            x: stickerDTO.x,
                            y: stickerDTO.y,
                            scale: stickerDTO.scale,
                            rotation: stickerDTO.rotation,
                            zIndex: stickerDTO.zIndex,
                            sourceType: stickerDTO.sourceType,
                            resourceUrl: stickerDTO.resourceUrl,
                            localFilePath: stickerDTO.localFilePath,
                            photoAssetId: stickerDTO.photoAssetId,
                            isAnimated: stickerDTO.isAnimated
                        )
                        newCard.stickers.append(stickerObject)
                    }

                    return self.realmManager.update { realm in
                        realm.add(newCard)
                        if let cardToDelete = realm.object(ofType: Card.self, forPrimaryKey: cardId) {
                            realm.delete(cardToDelete)
                        }
                    }
                    .observe(on: MainScheduler.instance)
                    .do(onNext: {
                        if !editTypes.isEmpty {
                            AnalyticsManager.shared.logCardEdit(editType: editTypes.joined(separator: ","))
                        }
                        if !hadLocationBefore && location != nil {
                            AnalyticsManager.shared.logFirstLocationAdded()
                        }
                    })
                }
        }
    }
}
