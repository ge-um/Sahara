//
//  CardInfoViewModel.swift
//  Sahara
//
//  Created by 금가경 on 9/26/25.
//

import CoreLocation
import Foundation
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
    private var editedImage: UIImage?
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

    init(editedImage: UIImage?, realmManager: RealmManagerProtocol = RealmManager.shared) {
        self.realmManager = realmManager
        self.editedImage = editedImage
        self.cardToEditId = nil
        self.sourceType = nil
    }

    init(initialDate: Date, sourceType: EditSourceType, realmManager: RealmManagerProtocol = RealmManager.shared) {
        self.realmManager = realmManager
        self.editedImage = nil
        self.cardToEditId = nil
        self.originalDate = initialDate
        self.sourceType = sourceType
    }

    init(cardToEdit cardId: ObjectId, sourceType: EditSourceType, realmManager: RealmManagerProtocol = RealmManager.shared) {
        self.realmManager = realmManager
        self.cardToEditId = cardId
        self.sourceType = sourceType

        guard let card = realmManager.fetchObject(Card.self, forPrimaryKey: cardId) else {
            return
        }

        self.editedImage = UIImage(data: card.editedImageData)
        self.originalDate = card.date
        self.initialMemo = card.memo
        self.initialIsLocked = card.isLocked
        self.initialCustomFolder = card.customFolder
        if let lat = card.latitude, let lon = card.longitude {
            self.originalLocation = CLLocation(latitude: lat, longitude: lon)
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
                        NotificationCenter.default.post(name: AppNotification.photoDeleted.name, object: nil)

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
        guard let editedImage = editedImage,
              let imageData = editedImage.jpegData(compressionQuality: 0.8) else { return .empty() }

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

        return OCRManager.shared.recognizeText(from: editedImage)
            .flatMap { [weak self] ocrText -> Observable<Void> in
                guard let self = self else { return .empty() }

                let card = Card(
                    date: date,
                    createdDate: Date(),
                    editedImageData: imageData,
                    memo: memoText,
                    latitude: location?.coordinate.latitude,
                    longitude: location?.coordinate.longitude,
                    isLocked: isLocked
                )
                card.customFolder = folderText
                card.ocrText = ocrText

                return self.realmManager.add(card)
                    .observe(on: MainScheduler.instance)
                    .do(onNext: {
                        NotificationCenter.default.post(name: AppNotification.photoSaved.name, object: nil)
                    })
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

    private func updateCardObservable(cardId: ObjectId, date: Date, memo: String?, customFolder: String?, location: CLLocation?, isLocked: Bool = false) -> Observable<Void> {
        guard let editedImage = editedImage,
              let imageData = editedImage.jpegData(compressionQuality: 0.8) else { return .empty() }

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

        let ocrObservable = imageChanged ? OCRManager.shared.recognizeText(from: editedImage) : Observable.just(oldOcrText)

        return ocrObservable
            .flatMap { [weak self] ocrText -> Observable<Void> in
                guard let self = self else { return .empty() }

                return self.realmManager.update { realm in
                    guard let card = realm.object(ofType: Card.self, forPrimaryKey: cardId) else { return }
                    card.date = date
                    card.editedImageData = imageData
                    card.memo = memoText
                    card.customFolder = folderText
                    card.isLocked = isLocked
                    card.latitude = location?.coordinate.latitude
                    card.longitude = location?.coordinate.longitude
                    card.ocrText = ocrText
                }
                .observe(on: MainScheduler.instance)
                .do(onNext: {
                    NotificationCenter.default.post(name: AppNotification.photoSaved.name, object: nil)
                })
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

    private func replaceCardObservable(cardId: ObjectId, date: Date, memo: String?, customFolder: String?, location: CLLocation?, isLocked: Bool = false) -> Observable<Void> {
        guard let editedImage = editedImage,
              let imageData = editedImage.jpegData(compressionQuality: 0.8) else { return .empty() }
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

        let ocrObservable = imageChanged ? OCRManager.shared.recognizeText(from: editedImage) : Observable.just(oldOcrText)

        return ocrObservable
            .flatMap { [weak self] ocrText -> Observable<Void> in
                guard let self = self else { return .empty() }

                let newCard = Card(
                    date: date,
                    createdDate: Date(),
                    editedImageData: imageData,
                    memo: memoText,
                    latitude: location?.coordinate.latitude,
                    longitude: location?.coordinate.longitude,
                    isLocked: isLocked
                )
                newCard.customFolder = folderText
                newCard.ocrText = ocrText

                return self.realmManager.update { realm in
                    realm.add(newCard)
                    if let cardToDelete = realm.object(ofType: Card.self, forPrimaryKey: cardId) {
                        realm.delete(cardToDelete)
                    }
                }
                .observe(on: MainScheduler.instance)
                .do(onNext: {
                    NotificationCenter.default.post(name: AppNotification.photoSaved.name, object: nil)
                })
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
