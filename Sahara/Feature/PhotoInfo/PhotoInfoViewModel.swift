//
//  PhotoInfoViewModel.swift
//  Sahara
//
//  Created by 금가경 on 9/26/25.
//

import CoreLocation
import Foundation
import RxCocoa
import RxSwift
import UIKit

final class PhotoInfoViewModel: BaseViewModelProtocol {
    private let disposeBag = DisposeBag()
    private var editedImage: UIImage?

    struct Input {
        let selectedImage: Observable<UIImage?>
        let date: Observable<Date>
        let memo: Observable<String?>
        let location: Observable<CLLocation>
        let saveButtonTapped: Observable<Void>
        let cancelButtonTapped: Observable<Void>
    }

    struct Output {
        let editedImage: Driver<UIImage?>
        let hasImage: Driver<Bool>
        let location: Driver<CLLocation>
        let saved: Driver<Bool>
        let saveError: Driver<String>
        let dismiss: Driver<Void>
    }

    init(editedImage: UIImage?) {
        self.editedImage = editedImage
    }

    func transform(input: Input) -> Output {
        let locationRelay = BehaviorRelay<CLLocation?>(value: nil)
        let imageRelay = BehaviorRelay<UIImage?>(value: editedImage)

        input.selectedImage
            .bind(with: self) { owner, image in
                owner.editedImage = image
                imageRelay.accept(image)
            }
            .disposed(by: disposeBag)

        input.location
            .map { $0 as CLLocation? }
            .bind(to: locationRelay)
            .disposed(by: disposeBag)

        let saveErrorRelay = PublishRelay<String>()

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

                // 메모가 300자 초과 시 에러
                if let memo = memo, !memo.isEmpty, memo != "메모를 남기고 카드 뒷면에서 확인해보세요!", memo.count > 300 {
                    saveErrorRelay.accept("메모는 300자를 초과할 수 없습니다.")
                    return false
                }

                self.saveToRealm(date: date, memo: memo, location: location)
                return true
            }
            .asDriver(onErrorJustReturn: false)

        let dismiss = input.cancelButtonTapped
            .asDriver(onErrorJustReturn: ())

        let hasImage = imageRelay.map { $0 != nil }.asDriver(onErrorJustReturn: false)

        return Output(
            editedImage: imageRelay.asDriver(),
            hasImage: hasImage,
            location: locationRelay.compactMap { $0 }.asDriver(onErrorDriveWith: .empty()),
            saved: saved,
            saveError: saveErrorRelay.asDriver(onErrorJustReturn: ""),
            dismiss: dismiss
        )
    }

    private func saveToRealm(date: Date, memo: String?, location: CLLocation?) {
        guard let editedImage = editedImage,
              let imageData = editedImage.jpegData(compressionQuality: 0.8) else { return }

        let memoText = (memo?.isEmpty == false && memo != "메모를 남기고 카드 뒷면에서 확인해보세요!") ? memo : nil

        let photoMemo = Memo(
            createdDate: date,
            editedImageData: imageData,
            memo: memoText,
            latitude: location?.coordinate.latitude,
            longitude: location?.coordinate.longitude
        )

        RealmManager.shared.save(photoMemo)
        NotificationCenter.default.post(name: AppNotification.photoSaved.name, object: nil)
    }
}