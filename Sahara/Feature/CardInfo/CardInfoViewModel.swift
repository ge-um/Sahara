//
//  CardInfoViewModel.swift
//  Sahara
//
//  Created by 금가경 on 9/26/25.
//

import CoreLocation
import Foundation
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
    private var cardToEdit: Card?
    private var originalDate: Date?
    private var originalLocation: CLLocation?
    private var sourceType: EditSourceType?
    private var imageChanged = false

    struct Input {
        let selectedImage: Observable<UIImage?>
        let date: Observable<Date>
        let memo: Observable<String?>
        let location: Observable<CLLocation>
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
        let deleted: Driver<Void>
        let shouldPopToList: Driver<Bool>
    }

    init(editedImage: UIImage?) {
        self.editedImage = editedImage
        self.cardToEdit = nil
        self.sourceType = nil
    }

    init(initialDate: Date, sourceType: EditSourceType) {
        self.editedImage = nil
        self.cardToEdit = nil
        self.originalDate = initialDate
        self.sourceType = sourceType
    }

    init(cardToEdit: Card, sourceType: EditSourceType) {
        self.cardToEdit = cardToEdit
        self.editedImage = UIImage(data: cardToEdit.editedImageData)
        self.originalDate = cardToEdit.createdDate
        self.sourceType = sourceType
        if let lat = cardToEdit.latitude, let lon = cardToEdit.longitude {
            self.originalLocation = CLLocation(latitude: lat, longitude: lon)
        }
    }

    func transform(input: Input) -> Output {
        let isEditMode = cardToEdit != nil
        let initialLocation: CLLocation? = {
            guard let card = cardToEdit,
                  let lat = card.latitude,
                  let lon = card.longitude else { return nil }
            return CLLocation(latitude: lat, longitude: lon)
        }()

        let locationRelay = BehaviorRelay<CLLocation?>(value: initialLocation)
        let imageRelay = BehaviorRelay<UIImage?>(value: editedImage)

        input.selectedImage
            .compactMap { $0 }
            .bind(with: self) { owner, image in
                owner.editedImage = image
                imageRelay.accept(image)
                if owner.cardToEdit != nil {
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

        let saved = input.saveButtonTapped
            .withLatestFrom(
                Observable.combineLatest(
                    input.date,
                    input.memo,
                    locationRelay.asObservable()
                )
            )
            .map { [weak self] date, memo, location -> Bool in
                guard let self = self else { return false }

                if self.editedImage == nil {
                    saveErrorRelay.accept(NSLocalizedString("card_info.image_required", comment: ""))
                    return false
                }

                if let card = self.cardToEdit {
                    let shouldPop = self.shouldPopToList(newDate: date, newLocation: location)
                    if shouldPop {
                        self.replaceCard(card, date: date, memo: memo, location: location)
                    } else {
                        self.updateCard(card, date: date, memo: memo, location: location)
                    }
                    shouldPopToListRelay.accept(shouldPop)
                } else {
                    self.saveToRealm(date: date, memo: memo, location: location)
                    shouldPopToListRelay.accept(false)
                }
                return true
            }
            .asDriver(onErrorJustReturn: false)

        let deleted = input.deleteButtonTapped
            .withUnretained(self)
            .map { owner, _ -> Void in
                guard let card = owner.cardToEdit else { return () }
                RealmManager.shared.delete(card)
                NotificationCenter.default.post(name: AppNotification.photoDeleted.name, object: nil)
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
            initialDate: originalDate ?? cardToEdit?.createdDate ?? Date(),
            initialMemo: cardToEdit?.memo,
            initialLocation: initialLocation,
            deleted: deleted,
            shouldPopToList: shouldPopToListRelay.asDriver(onErrorJustReturn: false)
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

    private func saveToRealm(date: Date, memo: String?, location: CLLocation?) {
        guard let editedImage = editedImage,
              let imageData = editedImage.jpegData(compressionQuality: 0.8) else { return }

        let placeholders = ["메모를 입력하세요", "Enter memo", "メモを入力してください"]
        let memoText: String? = {
            guard let memo = memo, !memo.isEmpty else { return nil }
            return placeholders.contains(memo) ? nil : memo
        }()

        let photoMemo = Card(
            createdDate: date,
            editedImageData: imageData,
            memo: memoText,
            latitude: location?.coordinate.latitude,
            longitude: location?.coordinate.longitude
        )

        RealmManager.shared.save(photoMemo)
        NotificationCenter.default.post(name: AppNotification.photoSaved.name, object: nil)
    }

    private func updateCard(_ card: Card, date: Date, memo: String?, location: CLLocation?) {
        guard let editedImage = editedImage,
              let imageData = editedImage.jpegData(compressionQuality: 0.8) else { return }

        let placeholders = ["메모를 입력하세요", "Enter memo", "メモを入力してください"]
        let memoText: String? = {
            guard let memo = memo, !memo.isEmpty else { return nil }
            return placeholders.contains(memo) ? nil : memo
        }()

        RealmManager.shared.update {
            card.createdDate = date
            card.editedImageData = imageData
            card.memo = memoText
            card.latitude = location?.coordinate.latitude
            card.longitude = location?.coordinate.longitude
        }

        NotificationCenter.default.post(name: AppNotification.photoSaved.name, object: nil)
    }

    private func replaceCard(_ card: Card, date: Date, memo: String?, location: CLLocation?) {
        guard let editedImage = editedImage,
              let imageData = editedImage.jpegData(compressionQuality: 0.8) else { return }

        let placeholders = ["메모를 입력하세요", "Enter memo", "メモを入力してください"]
        let memoText: String? = {
            guard let memo = memo, !memo.isEmpty else { return nil }
            return placeholders.contains(memo) ? nil : memo
        }()

        RealmManager.shared.delete(card)

        let newCard = Card(
            createdDate: date,
            editedImageData: imageData,
            memo: memoText,
            latitude: location?.coordinate.latitude,
            longitude: location?.coordinate.longitude
        )

        RealmManager.shared.save(newCard)
        NotificationCenter.default.post(name: AppNotification.photoSaved.name, object: nil)
    }
}
