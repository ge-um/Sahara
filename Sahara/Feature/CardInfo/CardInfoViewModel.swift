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
    private let imagePrepareService: ImagePrepareServiceProtocol
    private var editedImage: UIImage?
    private var imageSourceData: ImageSourceData?
    private var cardToEditId: ObjectId?
    private var originalDate: Date?
    private var originalLocation: CLLocation?
    private var sourceType: EditSourceType?
    private var imageChanged = false
    private var initialMemo: String?
    private var initialIsLocked: Bool = false
    private var initialCustomFolder: String?

    struct Input {
        let selectedImage: Observable<UIImage?>
        let imageSourceData: Observable<ImageSourceData?>
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
        let initialImageSourceData: ImageSourceData?
        let deleted: Driver<Void>
        let shouldPopToList: Driver<Bool>
        let shouldPopToListOnDelete: Driver<Bool>
    }

    init(editedImage: UIImage?, realmManager: RealmManagerProtocol = RealmManager.shared, ocrManager: OCRManagerProtocol = OCRManager.shared, imagePrepareService: ImagePrepareServiceProtocol = ImagePrepareService()) {
        self.realmManager = realmManager
        self.ocrManager = ocrManager
        self.imagePrepareService = imagePrepareService
        self.editedImage = editedImage
        self.cardToEditId = nil
        self.sourceType = nil
    }

    init(initialDate: Date, sourceType: EditSourceType, realmManager: RealmManagerProtocol = RealmManager.shared, ocrManager: OCRManagerProtocol = OCRManager.shared, imagePrepareService: ImagePrepareServiceProtocol = ImagePrepareService()) {
        self.realmManager = realmManager
        self.ocrManager = ocrManager
        self.imagePrepareService = imagePrepareService
        self.editedImage = nil
        self.cardToEditId = nil
        self.originalDate = initialDate
        self.sourceType = sourceType
    }

    private func loadCardData(from card: Card, imageData: Data) {
        let screenScale = UIScreen.main.scale
        let screenBounds = UIScreen.main.bounds
        let maxDim = max(screenBounds.width, screenBounds.height) * screenScale * 2
        self.editedImage = ImageDownsampler.downsample(data: imageData, maxDimension: maxDim)
        self.originalDate = card.date
        self.initialMemo = card.memo
        self.initialIsLocked = card.isLocked
        self.initialCustomFolder = card.customFolder

        if let lat = card.latitude, let lon = card.longitude {
            self.originalLocation = CLLocation(latitude: lat, longitude: lon)
        }
    }

    private func createImageSourceData(from card: Card, editedImage: UIImage, imageData: Data) -> ImageSourceData {
        let format = card.imageFormat.flatMap { ImageSourceData.ImageFormat(rawValue: $0) }
        let originalData: Data? = imageData.isEmpty ? nil : imageData
        return ImageSourceData(image: editedImage, originalData: originalData, format: format)
    }

    init(cardToEdit cardId: ObjectId, sourceType: EditSourceType, realmManager: RealmManagerProtocol = RealmManager.shared, ocrManager: OCRManagerProtocol = OCRManager.shared, imagePrepareService: ImagePrepareServiceProtocol = ImagePrepareService()) {
        self.realmManager = realmManager
        self.ocrManager = ocrManager
        self.imagePrepareService = imagePrepareService
        self.cardToEditId = cardId
        self.sourceType = sourceType

        guard let card = realmManager.fetchObject(Card.self, forPrimaryKey: cardId) else {
            return
        }

        let imageData = card.resolvedImageData()
        loadCardData(from: card, imageData: imageData)

        if let editedImage = self.editedImage {
            self.imageSourceData = createImageSourceData(from: card, editedImage: editedImage, imageData: imageData)
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

        return realmManager.deleteCard(forPrimaryKey: cardId)
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
            initialImageSourceData: imageSourceData,
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

    private struct AnalyticsContext {
        let isFirstCard: Bool
        let hadLocationBefore: Bool
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

    private func prepareImage(from editedImage: UIImage) -> Observable<PreparedImageData> {
        let metadata = imageSourceData ?? ImageSourceData(image: editedImage)
        return imagePrepareService.prepareForSave(baseImage: metadata.image, metadata: metadata)
    }

    private func createCard(
        date: Date,
        imageData: PreparedImageData,
        ocrText: String?,
        memo: String?,
        customFolder: String?,
        location: CLLocation?,
        isLocked: Bool
    ) -> Card {
        let card = Card(
            date: date,
            createdDate: Date(),
            editedImageData: Data(),
            memo: memo,
            latitude: location?.coordinate.latitude,
            longitude: location?.coordinate.longitude,
            isLocked: isLocked
        )
        card.customFolder = customFolder
        card.ocrText = ocrText
        card.imageFormat = imageData.imageFormat

        do {
            let fileName = try ImageFileManager.shared.saveImageFile(
                data: imageData.editedImageData,
                cardId: card.id,
                format: imageData.imageFormat
            )
            card.imagePath = fileName
            Logger.database.notice("[ImageStorage] Saved to disk: \(fileName) (\(imageData.editedImageData.count / 1024)KB)")
        } catch {
            card.editedImageData = imageData.editedImageData
            Logger.database.error("[ImageStorage] Disk save failed, fallback to Realm: \(error.localizedDescription)")
        }

        return card
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

        let sanitized = sanitizeTextFields(memo: memo, customFolder: customFolder)
        let analyticsCtx = collectAnalyticsContext()
        let stickers = imageSourceData?.stickers ?? []

        Logger.database.info("Save: stickers=\(stickers.count)")

        let imageData$ = prepareImage(from: editedImage)
        let ocr$ = ocrManager.recognizeText(from: editedImage)

        return Observable.zip(imageData$, ocr$)
            .observe(on: MainScheduler.instance)
            .flatMap { [weak self] imageData, ocrText -> Observable<Void> in
                guard let self = self else { return .empty() }

                let card = self.createCard(
                    date: date,
                    imageData: imageData,
                    ocrText: ocrText,
                    memo: sanitized.memo,
                    customFolder: sanitized.customFolder,
                    location: location,
                    isLocked: isLocked
                )

                Logger.database.notice("Saved card: stickers=\(stickers.count)")

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
        isLocked: Bool
    ) -> Observable<Void> {
        let oldImagePath = realmManager.fetchObject(Card.self, forPrimaryKey: cardId)?.imagePath

        var newImagePath: String?
        do {
            newImagePath = try ImageFileManager.shared.saveImageFile(
                data: imageData.editedImageData,
                cardId: cardId,
                format: imageData.imageFormat
            )
        } catch {
            newImagePath = nil
        }

        return realmManager.update { realm in
            guard let card = realm.object(ofType: Card.self, forPrimaryKey: cardId) else { return }
            card.date = date
            if let newImagePath = newImagePath {
                card.imagePath = newImagePath
                card.editedImageData = Data()
            } else {
                card.editedImageData = imageData.editedImageData
            }
            card.imageFormat = imageData.imageFormat
            card.memo = memoText
            card.customFolder = folderText
            card.isLocked = isLocked
            card.latitude = location?.coordinate.latitude
            card.longitude = location?.coordinate.longitude
            card.ocrText = ocrText
        }
        .do(onNext: {
            if let oldPath = oldImagePath, oldPath != newImagePath {
                ImageFileManager.shared.deleteImageFile(at: oldPath)
            }
            ThumbnailCache.shared.invalidate(for: cardId)
        })
    }

    private func logUpdateAnalytics(editTypes: [String], hadLocationBefore: Bool, location: CLLocation?) {
        if !editTypes.isEmpty {
            AnalyticsManager.shared.logCardEdit(editType: editTypes.joined(separator: ","))
        }
        if !hadLocationBefore && location != nil {
            AnalyticsManager.shared.logFirstLocationAdded()
        }
    }

    private func updateCardMetadataOnly(
        cardId: ObjectId,
        date: Date,
        memoText: String?,
        folderText: String?,
        location: CLLocation?,
        isLocked: Bool
    ) -> Observable<Void> {
        return realmManager.update { realm in
            guard let card = realm.object(ofType: Card.self, forPrimaryKey: cardId) else { return }
            card.date = date
            card.memo = memoText
            card.customFolder = folderText
            card.isLocked = isLocked
            card.latitude = location?.coordinate.latitude
            card.longitude = location?.coordinate.longitude
        }
    }

    private func updateCardObservable(cardId: ObjectId, date: Date, memo: String?, customFolder: String?, location: CLLocation?, isLocked: Bool = false) -> Observable<Void> {
        guard let editedImage = editedImage else { return .empty() }
        guard let card = realmManager.fetchObject(Card.self, forPrimaryKey: cardId) else { return .empty() }

        let sanitizedFields = sanitizeTextFields(memo: memo, customFolder: customFolder)
        let analyticsCtx = collectAnalyticsContext()

        let oldLocation = (card.latitude != nil && card.longitude != nil) ? CLLocation(latitude: card.latitude!, longitude: card.longitude!) : nil
        let editTypes = trackEditTypes(
            memoText: sanitizedFields.memo,
            folderText: sanitizedFields.customFolder,
            oldLocation: oldLocation,
            newLocation: location,
            isLocked: isLocked
        )

        if !imageChanged {
            return updateCardMetadataOnly(
                cardId: cardId,
                date: date,
                memoText: sanitizedFields.memo,
                folderText: sanitizedFields.customFolder,
                location: location,
                isLocked: isLocked
            )
            .do(onNext: { [weak self] in
                guard let self = self else { return }
                self.logUpdateAnalytics(editTypes: editTypes, hadLocationBefore: analyticsCtx.hadLocationBefore, location: location)
            })
        }

        let stickers = imageSourceData?.stickers ?? []
        Logger.database.info("Update: stickers=\(stickers.count)")

        let imageData$ = prepareImage(from: editedImage)
        let ocr$ = ocrManager.recognizeText(from: editedImage)

        return Observable.zip(imageData$, ocr$)
            .observe(on: MainScheduler.instance)
            .flatMap { [weak self] imageData, ocrText -> Observable<Void> in
                guard let self = self else { return .empty() }

                return self.updateCardInRealm(
                    cardId: cardId,
                    date: date,
                    imageData: imageData,
                    ocrText: ocrText,
                    memoText: sanitizedFields.memo,
                    folderText: sanitizedFields.customFolder,
                    location: location,
                    isLocked: isLocked
                )
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
        isLocked: Bool
    ) -> Observable<Void> {
        let oldImagePath = realmManager.fetchObject(Card.self, forPrimaryKey: cardId)?.imagePath

        let newCard = createCard(
            date: date,
            imageData: imageData,
            ocrText: ocrText,
            memo: memoText,
            customFolder: folderText,
            location: location,
            isLocked: isLocked
        )

        Logger.database.notice("Replaced card")

        return realmManager.update { realm in
            realm.add(newCard)
            if let cardToDelete = realm.object(ofType: Card.self, forPrimaryKey: cardId) {
                realm.delete(cardToDelete)
            }
        }
        .do(onNext: {
            if let oldPath = oldImagePath {
                ImageFileManager.shared.deleteImageFile(at: oldPath)
            }
            ThumbnailCache.shared.invalidate(for: cardId)
        })
    }

    private func replaceCardObservable(cardId: ObjectId, date: Date, memo: String?, customFolder: String?, location: CLLocation?, isLocked: Bool = false) -> Observable<Void> {
        guard let editedImage = editedImage else { return .empty() }
        guard let card = realmManager.fetchObject(Card.self, forPrimaryKey: cardId) else { return .empty() }

        let sanitizedFields = sanitizeTextFields(memo: memo, customFolder: customFolder)
        let analyticsCtx = collectAnalyticsContext()
        let stickers = imageSourceData?.stickers ?? []

        Logger.database.info("Replace: stickers=\(stickers.count)")

        let oldLocation = (card.latitude != nil && card.longitude != nil) ? CLLocation(latitude: card.latitude!, longitude: card.longitude!) : nil
        let editTypes = trackEditTypes(
            memoText: sanitizedFields.memo,
            folderText: sanitizedFields.customFolder,
            oldLocation: oldLocation,
            newLocation: location,
            isLocked: isLocked
        )

        let imageData$ = prepareImage(from: editedImage)
        let ocr$ = imageChanged ? ocrManager.recognizeText(from: editedImage) : Observable.just(card.ocrText)

        return Observable.zip(imageData$, ocr$)
            .observe(on: MainScheduler.instance)
            .flatMap { [weak self] imageData, ocrText -> Observable<Void> in
                guard let self = self else { return .empty() }

                return self.createNewCardAndReplaceOld(
                    cardId: cardId,
                    date: date,
                    imageData: imageData,
                    ocrText: ocrText,
                    memoText: sanitizedFields.memo,
                    folderText: sanitizedFields.customFolder,
                    location: location,
                    isLocked: isLocked
                )
                .do(onNext: {
                    self.logUpdateAnalytics(editTypes: editTypes, hadLocationBefore: analyticsCtx.hadLocationBefore, location: location)
                })
            }
    }
}
