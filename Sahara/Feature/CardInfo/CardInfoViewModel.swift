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

    private func loadCardData(from card: Card) {
        self.editedImage = UIImage(data: card.editedImageData)
        self.originalDate = card.date
        self.initialMemo = card.memo
        self.initialIsLocked = card.isLocked
        self.initialCustomFolder = card.customFolder

        if let lat = card.latitude, let lon = card.longitude {
            self.originalLocation = CLLocation(latitude: lat, longitude: lon)
        }
    }

    private func createImageSourceData(from card: Card, editedImage: UIImage) -> ImageSourceData {
        let stickers = Array(card.stickers.map { StickerDTO(from: $0) })
        let format = card.imageFormat.flatMap { ImageSourceData.ImageFormat(rawValue: $0) }

        return ImageSourceData(
            image: editedImage,
            originalData: card.originalImageData,
            format: format,
            stickers: stickers
        )
    }

    init(cardToEdit cardId: ObjectId, sourceType: EditSourceType, realmManager: RealmManagerProtocol = RealmManager.shared, ocrManager: OCRManagerProtocol = OCRManager.shared) {
        self.realmManager = realmManager
        self.ocrManager = ocrManager
        self.cardToEditId = cardId
        self.sourceType = sourceType

        guard let card = realmManager.fetchObject(Card.self, forPrimaryKey: cardId) else {
            return
        }

        loadCardData(from: card)

        if let editedImage = self.editedImage {
            self.imageSourceData = createImageSourceData(from: card, editedImage: editedImage)
        }
    }

    private func bindInputs(
        input: Input,
        imageRelay: BehaviorRelay<UIImage?>,
        locationRelay: BehaviorRelay<CLLocation?>
    ) {
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
    }

    private func logCardSaveAnalytics(memo: String?, location: CLLocation?, isLocked: Bool) {
        AnalyticsManager.shared.logCardSave(
            hasPhoto: editedImage != nil,
            hasMemo: !(memo?.isEmpty ?? true),
            hasLocation: location != nil,
            isLocked: isLocked
        )
    }

    private func handleSaveAction(
        date: Date,
        memo: String?,
        customFolder: String?,
        location: CLLocation?,
        isLocked: Bool,
        saveErrorRelay: PublishRelay<String>,
        shouldPopToListRelay: PublishRelay<Bool>
    ) -> Observable<Bool> {
        if editedImage == nil {
            saveErrorRelay.accept(NSLocalizedString("card_info.image_required", comment: ""))
            return .just(false)
        }

        if let cardId = cardToEditId {
            let shouldPop = shouldPopToList(newDate: date, newLocation: location)
            shouldPopToListRelay.accept(shouldPop)

            if shouldPop {
                return replaceCardObservable(cardId: cardId, date: date, memo: memo, customFolder: customFolder, location: location, isLocked: isLocked)
                    .map { true }
            } else {
                return updateCardObservable(cardId: cardId, date: date, memo: memo, customFolder: customFolder, location: location, isLocked: isLocked)
                    .map { true }
            }
        } else {
            shouldPopToListRelay.accept(false)
            return saveToRealmObservable(date: date, memo: memo, customFolder: customFolder, location: location, isLocked: isLocked)
                .map { true }
        }
    }

    private func handleDeleteAction(shouldPopToListOnDeleteRelay: PublishRelay<Bool>) -> Observable<Void> {
        guard let cardId = cardToEditId else { return .just(()) }

        return realmManager.delete(Card.self, forPrimaryKey: cardId)
            .do(onNext: { [weak self] _ in
                guard let self = self else { return }
                shouldPopToListOnDeleteRelay.accept(self.sourceType != nil)
            })
    }

    func transform(input: Input) -> Output {
        let isEditMode = cardToEditId != nil
        let initialLocation: CLLocation? = originalLocation

        let locationRelay = BehaviorRelay<CLLocation?>(value: initialLocation)
        let imageRelay = BehaviorRelay<UIImage?>(value: editedImage)
        let saveErrorRelay = PublishRelay<String>()
        let shouldPopToListRelay = PublishRelay<Bool>()
        let shouldPopToListOnDeleteRelay = PublishRelay<Bool>()

        bindInputs(input: input, imageRelay: imageRelay, locationRelay: locationRelay)

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
                self?.logCardSaveAnalytics(memo: memo, location: location, isLocked: isLocked)
            })
            .flatMap { [weak self] date, memo, customFolder, location, isLocked -> Observable<Bool> in
                guard let self = self else { return .just(false) }
                return self.handleSaveAction(
                    date: date,
                    memo: memo,
                    customFolder: customFolder,
                    location: location,
                    isLocked: isLocked,
                    saveErrorRelay: saveErrorRelay,
                    shouldPopToListRelay: shouldPopToListRelay
                )
            }
            .asDriver(onErrorJustReturn: false)

        let deleted = input.deleteButtonTapped
            .withUnretained(self)
            .do(onNext: { _, _ in
                AnalyticsManager.shared.logCardDelete()
            })
            .flatMap { [weak self] _, _ -> Observable<Void> in
                guard let self = self else { return .just(()) }
                return self.handleDeleteAction(shouldPopToListOnDeleteRelay: shouldPopToListOnDeleteRelay)
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
            return hasDayChanged(from: originalDate, to: newDate)

        case .locationView:
            return hasLocationChanged(from: originalLocation, to: newLocation, threshold: 100.0)

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

    private struct ImageProcessingContext {
        let stickers: [StickerDTO]
        let originalData: Data?
        let sourceFormat: ImageSourceData.ImageFormat?
        let hasEdits: Bool
    }

    private struct AnalyticsContext {
        let isFirstCard: Bool
        let hadLocationBefore: Bool
    }

    private func extractImageContext() -> ImageProcessingContext {
        let stickers = imageSourceData?.stickers ?? []
        let originalData = imageSourceData?.originalData
        let sourceFormat = imageSourceData?.format
        let hasEdits = wasImageEdited || !stickers.isEmpty
        return ImageProcessingContext(
            stickers: stickers,
            originalData: originalData,
            sourceFormat: sourceFormat,
            hasEdits: hasEdits
        )
    }

    private func collectAnalyticsContext() -> AnalyticsContext {
        let isFirstCard = realmManager.isEmpty(Card.self)
        let allCards = realmManager.fetch(Card.self)
        let hadLocationBefore = allCards.contains { $0.latitude != nil && $0.longitude != nil }
        return AnalyticsContext(isFirstCard: isFirstCard, hadLocationBefore: hadLocationBefore)
    }

    private func hasDayChanged(from old: Date, to new: Date) -> Bool {
        let calendar = Calendar.current
        let oldComponents = calendar.dateComponents([.year, .month, .day], from: old)
        let newComponents = calendar.dateComponents([.year, .month, .day], from: new)
        return oldComponents != newComponents
    }

    private func createStickerObjects(from dtos: [StickerDTO], isAnimatedFlags: [Bool]) -> [Sticker] {
        return dtos.enumerated().map { index, dto in
            let isAnimated = index < isAnimatedFlags.count ? isAnimatedFlags[index] : dto.isAnimated
            return Sticker(
                x: dto.x,
                y: dto.y,
                scale: dto.scale,
                rotation: dto.rotation,
                zIndex: dto.zIndex,
                sourceType: dto.sourceType,
                resourceUrl: dto.resourceUrl,
                localFilePath: dto.localFilePath,
                photoAssetId: dto.photoAssetId,
                isAnimated: isAnimated
            )
        }
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
        let stickerObjects = createStickerObjects(from: stickers, isAnimatedFlags: isAnimatedFlags)
        stickerObjects.forEach { card.stickers.append($0) }
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

        let context = extractImageContext()
        let sanitized = sanitizeTextFields(memo: memo, customFolder: customFolder)
        let analyticsCtx = collectAnalyticsContext()

        Logger.database.info("Save: hasEdits=\(context.hasEdits), hasOriginal=\(context.originalData != nil), format=\(context.sourceFormat?.rawValue ?? "nil"), stickers=\(context.stickers.count)")

        let imageDataObservable = prepareImageData(
            editedImage: editedImage,
            stickers: context.stickers,
            trueOriginalData: context.originalData,
            sourceFormat: context.sourceFormat,
            hasEdits: context.hasEdits
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
                    memo: sanitized.memo,
                    customFolder: sanitized.customFolder,
                    location: location,
                    isLocked: isLocked,
                    hasEdits: context.hasEdits
                )

                self.addStickers(to: card, stickers: context.stickers, isAnimatedFlags: isAnimatedFlags)

                Logger.database.notice("Saved card: filter=\(self.currentFilterIndex.orNil), crop=\(self.currentCropMetadata.presenceLog), stickers=\(context.stickers.count)")

                return self.realmManager.add(card)
                    .do(onNext: {
                        self.logSaveAnalytics(isFirstCard: analyticsCtx.isFirstCard, hadLocationBefore: analyticsCtx.hadLocationBefore, location: location)
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

    private func hasLocationChanged(from old: CLLocation?, to new: CLLocation?, threshold: Double = 1.0) -> Bool {
        switch (old, new) {
        case (nil, .some):
            return true
        case (.some, nil):
            return true
        case let (.some(oldLoc), .some(newLoc)):
            return oldLoc.distance(from: newLoc) > threshold
        case (nil, nil):
            return false
        }
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
        if hasLocationChanged(from: oldLocation, to: newLocation, threshold: 1.0) {
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
            let stickerObjects = self.createStickerObjects(from: stickers, isAnimatedFlags: isAnimatedFlags)
            stickerObjects.forEach { card.stickers.append($0) }
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

        let context = extractImageContext()
        let sanitizedFields = sanitizeTextFields(memo: memo, customFolder: customFolder)
        let analyticsCtx = collectAnalyticsContext()

        Logger.database.info("Update: hasEdits=\(context.hasEdits), hasOriginal=\(context.originalData != nil), format=\(context.sourceFormat?.rawValue ?? "nil"), stickers=\(context.stickers.count)")

        let oldLocation = (card.latitude != nil && card.longitude != nil) ? CLLocation(latitude: card.latitude!, longitude: card.longitude!) : nil
        let editTypes = trackEditTypes(
            memoText: sanitizedFields.memo,
            folderText: sanitizedFields.customFolder,
            oldLocation: oldLocation,
            newLocation: location,
            isLocked: isLocked
        )

        let imageDataObservable = prepareImageData(
            editedImage: editedImage,
            stickers: context.stickers,
            trueOriginalData: context.originalData,
            sourceFormat: context.sourceFormat,
            hasEdits: context.hasEdits
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
                    hasEdits: context.hasEdits,
                    stickers: context.stickers,
                    isAnimatedFlags: isAnimatedFlags
                )
                .observe(on: MainScheduler.instance)
                .do(onNext: {
                    self.logUpdateAnalytics(editTypes: editTypes, hadLocationBefore: analyticsCtx.hadLocationBefore, location: location)
                })
            }
    }

    private func createNewCardAndReplaceOld(
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
        let newCard = createCard(
            date: date,
            imageData: imageData,
            ocrText: ocrText,
            memo: memoText,
            customFolder: folderText,
            location: location,
            isLocked: isLocked,
            hasEdits: hasEdits
        )

        addStickers(to: newCard, stickers: stickers, isAnimatedFlags: isAnimatedFlags)

        Logger.database.notice("Replaced card: filter=\(self.currentFilterIndex.orNil), crop=\(self.currentCropMetadata.presenceLog), stickers=\(stickers.count)")

        return realmManager.update { realm in
            realm.add(newCard)
            if let cardToDelete = realm.object(ofType: Card.self, forPrimaryKey: cardId) {
                realm.delete(cardToDelete)
            }
        }
    }

    private func replaceCardObservable(cardId: ObjectId, date: Date, memo: String?, customFolder: String?, location: CLLocation?, isLocked: Bool = false) -> Observable<Void> {
        guard let editedImage = editedImage else { return .empty() }
        guard let card = realmManager.fetchObject(Card.self, forPrimaryKey: cardId) else { return .empty() }

        let context = extractImageContext()
        let sanitizedFields = sanitizeTextFields(memo: memo, customFolder: customFolder)
        let analyticsCtx = collectAnalyticsContext()

        Logger.database.info("Replace: hasEdits=\(context.hasEdits), hasOriginal=\(context.originalData != nil), format=\(context.sourceFormat?.rawValue ?? "nil"), stickers=\(context.stickers.count)")

        let oldLocation = (card.latitude != nil && card.longitude != nil) ? CLLocation(latitude: card.latitude!, longitude: card.longitude!) : nil
        let editTypes = trackEditTypes(
            memoText: sanitizedFields.memo,
            folderText: sanitizedFields.customFolder,
            oldLocation: oldLocation,
            newLocation: location,
            isLocked: isLocked
        )

        let imageDataObservable = prepareImageData(
            editedImage: editedImage,
            stickers: context.stickers,
            trueOriginalData: context.originalData,
            sourceFormat: context.sourceFormat,
            hasEdits: context.hasEdits
        )
        let ocrObservable = imageChanged ? ocrManager.recognizeText(from: editedImage) : Observable.just(card.ocrText)

        return Observable.zip(imageDataObservable, ocrObservable)
            .flatMap { [weak self] result -> Observable<Void> in
                guard let self = self else { return .empty() }
                let ((imageData, isAnimatedFlags), ocrText) = result

                return self.createNewCardAndReplaceOld(
                    cardId: cardId,
                    date: date,
                    imageData: imageData,
                    ocrText: ocrText,
                    memoText: sanitizedFields.memo,
                    folderText: sanitizedFields.customFolder,
                    location: location,
                    isLocked: isLocked,
                    hasEdits: context.hasEdits,
                    stickers: context.stickers,
                    isAnimatedFlags: isAnimatedFlags
                )
                .observe(on: MainScheduler.instance)
                .do(onNext: {
                    self.logUpdateAnalytics(editTypes: editTypes, hadLocationBefore: analyticsCtx.hadLocationBefore, location: location)
                })
            }
    }
}
