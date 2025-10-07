//
//  CardDetailViewModel.swift
//  Sahara
//
//  Created by 금가경 on 10/1/25.
//

import CoreLocation
import Foundation
import RealmSwift
import RxCocoa
import RxSwift
import UIKit

final class CardDetailViewModel {
    private let photoMemoId: ObjectId
    private let realmManager = RealmManager.shared
    private let disposeBag = DisposeBag()

    struct Input {
        let viewDidLoad: Observable<Void>
        let saveButtonTapped: Observable<Void>
        let shareButtonTapped: Observable<Void>
        let deleteConfirmed: Observable<Void>
        let swipeLeft: Observable<Void>
        let swipeRight: Observable<Void>
    }

    struct Output {
        let photoImage: Driver<UIImage?>
        let dateText: Driver<String>
        let locationText: Driver<String>
        let memoText: Driver<String>
        let shouldFlipToBack: Driver<Void>
        let shouldFlipToFront: Driver<Void>
        let saveResult: Driver<Result<Void, Error>>
        let shareImage: Driver<UIImage>
        let deleteCompleted: Driver<Void>
    }

    init(photoMemoId: ObjectId) {
        self.photoMemoId = photoMemoId
    }

    func getPhotoMemo() -> Card? {
        return realmManager.realm.object(ofType: Card.self, forPrimaryKey: photoMemoId)
    }

    func transform(input: Input) -> Output {
        let photoMemoData = input.viewDidLoad
            .compactMap { [weak self] _ -> (image: Data, date: Date, latitude: Double?, longitude: Double?, memo: String?)? in
                guard let self = self,
                      let photoMemo = self.realmManager.realm.object(ofType: Card.self, forPrimaryKey: self.photoMemoId) else {
                    return nil
                }
                return (
                    image: photoMemo.editedImageData,
                    date: photoMemo.createdDate,
                    latitude: photoMemo.latitude,
                    longitude: photoMemo.longitude,
                    memo: photoMemo.memo
                )
            }
            .share(replay: 1)

        let photoImage = photoMemoData
            .map { data -> UIImage? in
                UIImage(data: data.image)
            }
            .asDriver(onErrorJustReturn: nil)

        let dateText = photoMemoData
            .map { data -> String in
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = NSLocalizedString("photo_detail.date_format", comment: "")
                dateFormatter.locale = Locale.current
                return dateFormatter.string(from: data.date)
            }
            .asDriver(onErrorJustReturn: "")

        let locationText = photoMemoData
            .flatMap { data -> Observable<String> in
                guard let latitude = data.latitude,
                      let longitude = data.longitude else {
                    return .just("")
                }

                return Observable.create { observer in
                    let location = CLLocation(latitude: latitude, longitude: longitude)
                    LocationUtility.reverseGeocode(location: location) { address in
                        observer.onNext(address)
                        observer.onCompleted()
                    }
                    return Disposables.create()
                }
                .observe(on: MainScheduler.instance)
            }
            .asDriver(onErrorJustReturn: "")

        let memoText = photoMemoData
            .map { data -> String in
                return data.memo ?? ""
            }
            .asDriver(onErrorJustReturn: "")

        let shouldFlipToBack = input.swipeLeft
            .asDriver(onErrorJustReturn: ())

        let shouldFlipToFront = input.swipeRight
            .asDriver(onErrorJustReturn: ())

        let saveResult = input.saveButtonTapped
            .withLatestFrom(photoMemoData)
            .map { data -> Result<Void, Error> in
                guard let image = UIImage(data: data.image) else {
                    return .failure(NSError(domain: "PhotoDetailViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: NSLocalizedString("photo_detail.image_load_error", comment: "")]))
                }
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                return .success(())
            }
            .asDriver(onErrorJustReturn: .failure(NSError(domain: "PhotoDetailViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: NSLocalizedString("photo_detail.save_failed", comment: "")])))

        let shareImage = input.shareButtonTapped
            .withLatestFrom(photoMemoData)
            .compactMap { data -> UIImage? in
                UIImage(data: data.image)
            }
            .asDriver(onErrorDriveWith: .empty())

        let deleteCompleted = input.deleteConfirmed
            .withUnretained(self)
            .map { owner, _ -> Void in
                owner.realmManager.deleteCard(id: owner.photoMemoId)
                return ()
            }
            .asDriver(onErrorJustReturn: ())

        return Output(
            photoImage: photoImage,
            dateText: dateText,
            locationText: locationText,
            memoText: memoText,
            shouldFlipToBack: shouldFlipToBack,
            shouldFlipToFront: shouldFlipToFront,
            saveResult: saveResult,
            shareImage: shareImage,
            deleteCompleted: deleteCompleted
        )
    }
}
