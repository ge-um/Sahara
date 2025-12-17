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

    struct Input {
        let selectedImage: Observable<UIImage?>
        let imageSourceData: Observable<ImageSourceData?>
        let wasEdited: Observable<Bool>
        let selectedFilterIndex: Observable<Int?>
        let cropMetadata: Observable<CropMetadata?>
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

    private struct PreparedImageData {
        let editedImageData: Data
        let originalImageData: Data?
        let imageFormat: String
    }

    private func prepareImageData(
        editedImage: UIImage,
        stickers: [StickerDTO],
        trueOriginalData: Data?,
        sourceFormat: ImageSourceData.ImageFormat?,
        hasEdits: Bool
    ) -> Observable<(PreparedImageData, [Bool])> {
        if !stickers.isEmpty {
            return Observable.create { observer in
                let resizedImage = editedImage.resized()
                MediaEditorImageHandler.compositeStickersOnImage(resizedImage, stickers: stickers) { compositedImage, isAnimatedFlags in
                    let conversionResult = ImageFormatHelper.convertToFormat(
                        editedImage: compositedImage,
                        originalData: trueOriginalData,
                        targetFormat: sourceFormat
                    )
                    let preparedData = PreparedImageData(
                        editedImageData: conversionResult.editedImageData,
                        originalImageData: trueOriginalData,
                        imageFormat: conversionResult.imageFormat
                    )
                    observer.onNext((preparedData, isAnimatedFlags))
                    observer.onCompleted()
                }
                return Disposables.create()
            }
        } else {
            let editedImageData: Data
            let imageFormat: String

            if hasEdits {
                let resizedImage = editedImage.resized()
                let conversionResult = ImageFormatHelper.convertToFormat(
                    editedImage: resizedImage,
                    originalData: trueOriginalData,
                    targetFormat: sourceFormat
                )
                editedImageData = conversionResult.editedImageData
                imageFormat = conversionResult.imageFormat
            } else {
                editedImageData = trueOriginalData ?? {
                    let conversionResult = ImageFormatHelper.convertToFormat(
                        editedImage: editedImage,
                        originalData: nil,
                        targetFormat: sourceFormat
                    )
                    return conversionResult.editedImageData
                }()
                imageFormat = sourceFormat?.rawValue ?? "heic"
            }

            let preparedData = PreparedImageData(
                editedImageData: editedImageData,
                originalImageData: trueOriginalData,
                imageFormat: imageFormat
            )
            return Observable.just((preparedData, []))
        }
    }

    private func createCard(
        date: Date,
        imageData: PreparedImageData,
        ocrText: String?,
        memo: String?,
        customFolder: String?,
        location: CLLocation?,
        isLocked: Bool,
        hasEdits: Bool
    ) -> Card {
        let card = Card(
            date: date,
            createdDate: Date(),
            editedImageData: imageData.editedImageData,
            memo: memo,
            latitude: location?.coordinate.latitude,
            longitude: location?.coordinate.longitude,
            isLocked: isLocked
        )
        card.customFolder = customFolder
        card.ocrText = ocrText
        card.originalImageData = imageData.originalImageData
        card.imageFormat = imageData.imageFormat
        card.wasEdited = hasEdits
        card.appliedFilterIndex = currentFilterIndex
        card.cropMetadata = currentCropMetadata
        return card
    }

    private func addStickers(to card: Card, stickers: [StickerDTO], isAnimatedFlags: [Bool]) {
        for (index, stickerDTO) in stickers.enumerated() {
            let isAnimated = index < isAnimatedFlags.count ? isAnimatedFlags[index] : stickerDTO.isAnimated
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

    private func logSaveAnalytics(isFirstCard: Bool, hadLocationBefore: Bool, location: CLLocation?) {
        if isFirstCard {
            AnalyticsManager.shared.logFirstCardCreated()
        }
        if !hadLocationBefore && location != nil {
            AnalyticsManager.shared.logFirstLocationAdded()
        }
    }

    private func saveToRealmObservable(date: Date, memo: String?, customFolder: String?, location: CLLocation?, isLocked: Bool = false) -> Observable<Void> {
        guard let editedImage = editedImage else { return .empty() }

        let stickers = imageSourceData?.stickers ?? []
        let trueOriginalData = imageSourceData?.originalData
        let sourceFormat = imageSourceData?.format
        let hasEdits = wasImageEdited || !stickers.isEmpty

        Logger.database.info("Save: hasEdits=\(hasEdits), hasOriginal=\(trueOriginalData != nil), format=\(sourceFormat?.rawValue ?? "nil"), stickers=\(stickers.count)")

        let memoText = memo?.isEmpty == false ? memo : nil
        let folderText = customFolder?.isEmpty == false ? customFolder : nil
        let isFirstCard = realmManager.isEmpty(Card.self)
        let allCards = realmManager.fetch(Card.self)
        let hadLocationBefore = allCards.contains { $0.latitude != nil && $0.longitude != nil }

        let imageDataObservable = prepareImageData(
            editedImage: editedImage,
            stickers: stickers,
            trueOriginalData: trueOriginalData,
            sourceFormat: sourceFormat,
            hasEdits: hasEdits
        )
        let ocrObservable = ocrManager.recognizeText(from: editedImage)

        return Observable.zip(imageDataObservable, ocrObservable)
            .flatMap { [weak self] result -> Observable<Void> in
                guard let self = self else { return .empty() }
                let ((imageData, isAnimatedFlags), ocrText) = result

                let card = self.createCard(
                    date: date,
                    imageData: imageData,
                    ocrText: ocrText,
                    memo: memoText,
                    customFolder: folderText,
                    location: location,
                    isLocked: isLocked,
                    hasEdits: hasEdits
                )

                self.addStickers(to: card, stickers: stickers, isAnimatedFlags: isAnimatedFlags)

                Logger.database.notice("Saved card: filter=\(self.currentFilterIndex.orNil), crop=\(self.currentCropMetadata.presenceLog), stickers=\(stickers.count)")

                return self.realmManager.add(card)
                    .do(onNext: {
                        self.logSaveAnalytics(isFirstCard: isFirstCard, hadLocationBefore: hadLocationBefore, location: location)
                    })
            }
    }


    private struct SanitizedFields {
        let memo: String?
        let customFolder: String?
    }

    private func sanitizeTextFields(memo: String?, customFolder: String?) -> SanitizedFields {
        let memoText = (memo?.isEmpty == false) ? memo : nil
        let folderText = (customFolder?.isEmpty == false) ? customFolder : nil
        return SanitizedFields(memo: memoText, customFolder: folderText)
    }

    private func trackEditTypes(
        memoText: String?,
        folderText: String?,
        oldLocation: CLLocation?,
        newLocation: CLLocation?,
        isLocked: Bool
    ) -> [String] {
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

        let locationChanged = (oldLocation == nil && newLocation != nil) ||
                            (oldLocation != nil && newLocation == nil) ||
                            (oldLocation != nil && newLocation != nil && oldLocation!.distance(from: newLocation!) > 1)
        if locationChanged {
            editTypes.append("location")
        }

        if initialIsLocked != isLocked {
            editTypes.append("lock")
        }

        return editTypes
    }

    private func updateCardInRealm(
        cardId: ObjectId,
        date: Date,
        imageData: PreparedImageData,
        ocrText: String?,
        memoText: String?,
        folderText: String?,
        location: CLLocation?,
        isLocked: Bool,
        hasEdits: Bool,
        stickers: [StickerDTO],
        isAnimatedFlags: [Bool]
    ) -> Observable<Void> {
        return realmManager.update { realm in
            guard let card = realm.object(ofType: Card.self, forPrimaryKey: cardId) else { return }
            card.date = date
            card.editedImageData = imageData.editedImageData
            card.originalImageData = imageData.originalImageData
            card.imageFormat = imageData.imageFormat
            card.wasEdited = hasEdits

            Logger.database.notice("Updated card: filter=\(self.currentFilterIndex.orNil), crop=\(self.currentCropMetadata.presenceLog), stickers=\(stickers.count)")

            card.appliedFilterIndex = self.currentFilterIndex
            card.cropMetadata = self.currentCropMetadata

            card.memo = memoText
            card.customFolder = folderText
            card.isLocked = isLocked
            card.latitude = location?.coordinate.latitude
            card.longitude = location?.coordinate.longitude
            card.ocrText = ocrText

            card.stickers.removeAll()
            for (index, stickerDTO) in stickers.enumerated() {
                let isAnimated = index < isAnimatedFlags.count ? isAnimatedFlags[index] : stickerDTO.isAnimated
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
    }

    private func logUpdateAnalytics(editTypes: [String], hadLocationBefore: Bool, location: CLLocation?) {
        if !editTypes.isEmpty {
            AnalyticsManager.shared.logCardEdit(editType: editTypes.joined(separator: ","))
        }
        if !hadLocationBefore && location != nil {
            AnalyticsManager.shared.logFirstLocationAdded()
        }
    }

    private func updateCardObservable(cardId: ObjectId, date: Date, memo: String?, customFolder: String?, location: CLLocation?, isLocked: Bool = false) -> Observable<Void> {
        guard let editedImage = editedImage else { return .empty() }
        guard let card = realmManager.fetchObject(Card.self, forPrimaryKey: cardId) else { return .empty() }

        let stickers = imageSourceData?.stickers ?? []
        let trueOriginalData = imageSourceData?.originalData
        let sourceFormat = imageSourceData?.format
        let hasEdits = wasImageEdited || !stickers.isEmpty

        Logger.database.info("Update: hasEdits=\(hasEdits), hasOriginal=\(trueOriginalData != nil), format=\(sourceFormat?.rawValue ?? "nil"), stickers=\(stickers.count)")

        let sanitizedFields = sanitizeTextFields(memo: memo, customFolder: customFolder)
        let oldLocation = (card.latitude != nil && card.longitude != nil) ? CLLocation(latitude: card.latitude!, longitude: card.longitude!) : nil
        let editTypes = trackEditTypes(
            memoText: sanitizedFields.memo,
            folderText: sanitizedFields.customFolder,
            oldLocation: oldLocation,
            newLocation: location,
            isLocked: isLocked
        )

        let allCards = realmManager.fetch(Card.self)
        let hadLocationBefore = allCards.contains { $0.latitude != nil && $0.longitude != nil }

        let imageDataObservable = prepareImageData(
            editedImage: editedImage,
            stickers: stickers,
            trueOriginalData: trueOriginalData,
            sourceFormat: sourceFormat,
            hasEdits: hasEdits
        )
        let ocrObservable = imageChanged ? ocrManager.recognizeText(from: editedImage) : Observable.just(card.ocrText)

        return Observable.zip(imageDataObservable, ocrObservable)
            .flatMap { [weak self] result -> Observable<Void> in
                guard let self = self else { return .empty() }
                let ((imageData, isAnimatedFlags), ocrText) = result

                return self.updateCardInRealm(
                    cardId: cardId,
                    date: date,
                    imageData: imageData,
                    ocrText: ocrText,
                    memoText: sanitizedFields.memo,
                    folderText: sanitizedFields.customFolder,
                    location: location,
                    isLocked: isLocked,
                    hasEdits: hasEdits,
                    stickers: stickers,
                    isAnimatedFlags: isAnimatedFlags
                )
                .observe(on: MainScheduler.instance)
                .do(onNext: {
                    self.logUpdateAnalytics(editTypes: editTypes, hadLocationBefore: hadLocationBefore, location: location)
                })
            }
    }

    private func replaceCardObservable(cardId: ObjectId, date: Date, memo: String?, customFolder: String?, location: CLLocation?, isLocked: Bool = false) -> Observable<Void> {
        guard let editedImage = editedImage else { return .empty() }

        let stickers = imageSourceData?.stickers ?? []
        let trueOriginalData = imageSourceData?.originalData
        let sourceFormat = imageSourceData?.format
        let hasEdits = wasImageEdited || !stickers.isEmpty

        Logger.database.info("Replace: hasEdits=\(hasEdits), hasOriginal=\(trueOriginalData != nil), format=\(sourceFormat?.rawValue ?? "nil"), stickers=\(stickers.count)")

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

        if !stickers.isEmpty {
            return Observable.create { [weak self] observer in
                guard let self = self else {
                    observer.onCompleted()
                    return Disposables.create()
                }

                let resizedImage = editedImage.resized()
                MediaEditorImageHandler.compositeStickersOnImage(resizedImage, stickers: stickers) { compositedImage, isAnimatedFlags in
                    let conversionResult = ImageFormatHelper.convertToFormat(
                        editedImage: compositedImage,
                        originalData: trueOriginalData,
                        targetFormat: sourceFormat
                    )
                    let editedImageData = conversionResult.editedImageData
                    let originalImageData = trueOriginalData
                    let imageFormat = conversionResult.imageFormat

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
                                newCard.wasEdited = hasEdits

                                Logger.database.notice("Replaced card: filter=\(self.currentFilterIndex.orNil), crop=\(self.currentCropMetadata.presenceLog), stickers=\(stickers.count)")

                                newCard.appliedFilterIndex = self.currentFilterIndex
                                newCard.cropMetadata = self.currentCropMetadata

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
            let originalImageData: Data?
            let imageFormat: String

            if hasEdits {
                let resizedImage = editedImage.resized()
                let conversionResult = ImageFormatHelper.convertToFormat(
                    editedImage: resizedImage,
                    originalData: trueOriginalData,
                    targetFormat: sourceFormat
                )
                editedImageData = conversionResult.editedImageData
                originalImageData = trueOriginalData
                imageFormat = conversionResult.imageFormat
            } else {
                editedImageData = trueOriginalData ?? {
                    let conversionResult = ImageFormatHelper.convertToFormat(
                        editedImage: editedImage,
                        originalData: nil,
                        targetFormat: sourceFormat
                    )
                    return conversionResult.editedImageData
                }()
                originalImageData = trueOriginalData
                imageFormat = sourceFormat?.rawValue ?? "heic"
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
                    newCard.wasEdited = hasEdits

                    Logger.database.notice("Replaced card: filter=\(self.currentFilterIndex.orNil), crop=\(self.currentCropMetadata.presenceLog), stickers=\(stickers.count)")

                    newCard.appliedFilterIndex = self.currentFilterIndex
                    newCard.cropMetadata = self.currentCropMetadata

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
