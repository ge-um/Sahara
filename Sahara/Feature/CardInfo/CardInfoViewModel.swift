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
}

final class CardInfoViewModel: BaseViewModelProtocol {
    private let disposeBag = DisposeBag()
    private var editedImage: UIImage?
    private var cardToEditId: ObjectId?
    private var originalDate: Date?
    private var originalLocation: CLLocation?
    private var sourceType: EditSourceType?
    private var imageChanged = false
    private var initialMemo: String?
    private var initialIsLocked: Bool = false

    struct Input {
        let selectedImage: Observable<UIImage?>
        let date: Observable<Date>
        let memo: Observable<String?>
        let location: Observable<CLLocation>
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
        let initialLocation: CLLocation?
        let initialIsLocked: Bool
        let deleted: Driver<Void>
        let shouldPopToList: Driver<Bool>
        let shouldPopToListOnDelete: Driver<Bool>
    }

    init(editedImage: UIImage?) {
        self.editedImage = editedImage
        self.cardToEditId = nil
        self.sourceType = nil
    }

    init(initialDate: Date, sourceType: EditSourceType) {
        self.editedImage = nil
        self.cardToEditId = nil
        self.originalDate = initialDate
        self.sourceType = sourceType
    }

    init(cardToEdit: Card, sourceType: EditSourceType) {
        self.cardToEditId = cardToEdit.id
        self.editedImage = UIImage(data: cardToEdit.editedImageData)
        self.originalDate = cardToEdit.createdDate
        self.initialMemo = cardToEdit.memo
        self.initialIsLocked = cardToEdit.isLocked
        self.sourceType = sourceType
        if let lat = cardToEdit.latitude, let lon = cardToEdit.longitude {
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
            .map { $0 as CLLocation? }
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
                    locationRelay.asObservable(),
                    input.isLocked
                )
            )
            .map { [weak self] date, memo, location, isLocked -> Bool in
                guard let self = self else { return false }

                if self.editedImage == nil {
                    saveErrorRelay.accept(NSLocalizedString("card_info.image_required", comment: ""))
                    return false
                }

                if let cardId = self.cardToEditId {
                    let shouldPop = self.shouldPopToList(newDate: date, newLocation: location)
                    if shouldPop {
                        self.replaceCard(cardId: cardId, date: date, memo: memo, location: location, isLocked: isLocked)
                    } else {
                        self.updateCard(cardId: cardId, date: date, memo: memo, location: location, isLocked: isLocked)
                    }
                    shouldPopToListRelay.accept(shouldPop)
                } else {
                    self.saveToRealm(date: date, memo: memo, location: location, isLocked: isLocked)
                    shouldPopToListRelay.accept(false)
                }

                AnalyticsManager.shared.logCardSave(
                    hasPhoto: self.editedImage != nil,
                    hasMemo: !(memo?.isEmpty ?? true),
                    hasLocation: location != nil,
                    isLocked: isLocked
                )

                return true
            }
            .asDriver(onErrorJustReturn: false)

        let deleted = input.deleteButtonTapped
            .withUnretained(self)
            .map { owner, _ -> Void in
                guard let cardId = owner.cardToEditId else { return () }

                RealmManager.shared.deleteCard(id: cardId)
                NotificationCenter.default.post(name: AppNotification.photoDeleted.name, object: nil)
                AnalyticsManager.shared.logCardDelete()

                if owner.sourceType != nil {
                    shouldPopToListOnDeleteRelay.accept(true)
                } else {
                    shouldPopToListOnDeleteRelay.accept(false)
                }

                return ()
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
        }
    }

    private func saveToRealm(date: Date, memo: String?, location: CLLocation?, isLocked: Bool = false) {
        guard let editedImage = editedImage,
              let imageData = editedImage.jpegData(compressionQuality: 0.8) else { return }

        let placeholders = ["메모를 입력하세요", "Enter memo", "メモを入力してください"]
        let memoText: String? = {
            guard let memo = memo, !memo.isEmpty else { return nil }
            return placeholders.contains(memo) ? nil : memo
        }()

        let card = Card(
            createdDate: date,
            editedImageData: imageData,
            memo: memoText,
            latitude: location?.coordinate.latitude,
            longitude: location?.coordinate.longitude,
            isLocked: isLocked
        )

        let isFirstCard = RealmManager.shared.isEmpty(Card.self)
        let hadLocationBefore = !RealmManager.shared.realm.objects(Card.self).filter("latitude != nil AND longitude != nil").isEmpty

        RealmManager.shared.save(card)

        if isFirstCard {
            AnalyticsManager.shared.logFirstCardCreated()
        }

        if !hadLocationBefore && location != nil {
            AnalyticsManager.shared.logFirstLocationAdded()
        }

        NotificationCenter.default.post(name: AppNotification.photoSaved.name, object: nil)
    }

    private func updateCard(cardId: ObjectId, date: Date, memo: String?, location: CLLocation?, isLocked: Bool = false) {
        guard let editedImage = editedImage,
              let imageData = editedImage.jpegData(compressionQuality: 0.8) else { return }

        let placeholders = ["메모를 입력하세요", "Enter memo", "メモを入力してください"]
        let memoText: String? = {
            guard let memo = memo, !memo.isEmpty else { return nil }
            return placeholders.contains(memo) ? nil : memo
        }()

        let realm = RealmManager.shared.realm
        guard let card = realm.object(ofType: Card.self, forPrimaryKey: cardId) else { return }

        let hadLocationBefore = !realm.objects(Card.self).filter("latitude != nil AND longitude != nil").isEmpty

        RealmManager.shared.update {
            card.createdDate = date
            card.editedImageData = imageData
            card.memo = memoText
            card.isLocked = isLocked
            card.latitude = location?.coordinate.latitude
            card.longitude = location?.coordinate.longitude
        }

        if !hadLocationBefore && location != nil {
            AnalyticsManager.shared.logFirstLocationAdded()
        }

        NotificationCenter.default.post(name: AppNotification.photoSaved.name, object: nil)
    }

    private func replaceCard(cardId: ObjectId, date: Date, memo: String?, location: CLLocation?, isLocked: Bool = false) {
        guard let editedImage = editedImage,
              let imageData = editedImage.jpegData(compressionQuality: 0.8) else { return }

        let placeholders = ["메모를 입력하세요", "Enter memo", "メモを入力してください"]
        let memoText: String? = {
            guard let memo = memo, !memo.isEmpty else { return nil }
            return placeholders.contains(memo) ? nil : memo
        }()

        let realm = RealmManager.shared.realm
        let hadLocationBefore = !realm.objects(Card.self).filter("latitude != nil AND longitude != nil").isEmpty

        RealmManager.shared.deleteCard(id: cardId)

        let newCard = Card(
            createdDate: date,
            editedImageData: imageData,
            memo: memoText,
            latitude: location?.coordinate.latitude,
            longitude: location?.coordinate.longitude,
            isLocked: isLocked
        )

        RealmManager.shared.save(newCard)

        if !hadLocationBefore && location != nil {
            AnalyticsManager.shared.logFirstLocationAdded()
        }

        NotificationCenter.default.post(name: AppNotification.photoSaved.name, object: nil)
    }
}
