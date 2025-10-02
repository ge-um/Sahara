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
        let saved: Driver<Void>
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

        let saved = input.saveButtonTapped
            .withLatestFrom(
                Observable.combineLatest(
                    input.date,
                    input.memo,
                    locationRelay.asObservable()
                )
            )
            .do(onNext: { [weak self] date, memo, location in
                guard let self = self else { return }
                self.saveToRealm(date: date, memo: memo, location: location)
            })
            .map { _ in () }
            .asDriver(onErrorJustReturn: ())

        let dismiss = input.cancelButtonTapped
            .asDriver(onErrorJustReturn: ())

        let hasImage = imageRelay.map { $0 != nil }.asDriver(onErrorJustReturn: false)

        return Output(
            editedImage: imageRelay.asDriver(),
            hasImage: hasImage,
            location: locationRelay.compactMap { $0 }.asDriver(onErrorDriveWith: .empty()),
            saved: saved,
            dismiss: dismiss
        )
    }

    private func saveToRealm(date: Date, memo: String?, location: CLLocation?) {
        guard let editedImage = editedImage,
              let imageData = editedImage.jpegData(compressionQuality: 0.8) else { return }

        let memoText = (memo?.isEmpty == false && memo != "메모를 남기면 사진 뒤쪽에서 메모를 볼 수 있어요! (300자 제한)") ? memo : nil

        let photoMemo = Memo(
            createdDate: date,
            editedImageData: imageData,
            memo: memoText,
            latitude: location?.coordinate.latitude,
            longitude: location?.coordinate.longitude
        )

        RealmManager.shared.save(photoMemo)
        NotificationCenter.default.post(name: NSNotification.Name("PhotoSaved"), object: nil)
    }
}