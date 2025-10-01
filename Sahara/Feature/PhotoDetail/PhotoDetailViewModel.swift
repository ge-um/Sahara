//
//  PhotoDetailViewModel.swift
//  Sahara
//
//  Created by Claude on 10/1/25.
//

import CoreLocation
import Foundation
import RealmSwift
import RxCocoa
import RxSwift
import UIKit

final class PhotoDetailViewModel {
    private let photoMemoId: ObjectId
    private let realm = try! Realm()
    private let disposeBag = DisposeBag()

    struct Input {
        let viewDidLoad: Observable<Void>
        let closeButtonTapped: Observable<Void>
        let saveButtonTapped: Observable<Void>
        let shareButtonTapped: Observable<Void>
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
        let shouldDismiss: Driver<Void>
        let saveResult: Driver<Result<Void, Error>>
        let shareImage: Driver<UIImage>
    }

    init(photoMemoId: ObjectId) {
        self.photoMemoId = photoMemoId
    }

    func transform(input: Input) -> Output {
        let photoMemo = input.viewDidLoad
            .compactMap { [weak self] _ -> PhotoMemo? in
                guard let self = self else { return nil }
                return self.realm.object(ofType: PhotoMemo.self, forPrimaryKey: self.photoMemoId)
            }
            .share(replay: 1)

        let photoImage = photoMemo
            .map { photoMemo -> UIImage? in
                UIImage(data: photoMemo.imageData)
            }
            .asDriver(onErrorJustReturn: nil)

        let dateText = photoMemo
            .map { photoMemo -> String in
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = NSLocalizedString("photo_detail.date_format", comment: "")
                dateFormatter.locale = Locale.current
                return dateFormatter.string(from: photoMemo.date)
            }
            .asDriver(onErrorJustReturn: "")

        let locationText = photoMemo
            .flatMap { photoMemo -> Observable<String> in
                guard let latitude = photoMemo.latitude,
                      let longitude = photoMemo.longitude else {
                    return .just("")
                }

                return Observable.create { observer in
                    let location = CLLocation(latitude: latitude, longitude: longitude)
                    let geocoder = CLGeocoder()
                    geocoder.reverseGeocodeLocation(location) { placemarks, error in
                        if let placemark = placemarks?.first {
                            let address = [
                                placemark.locality,
                                placemark.thoroughfare,
                                placemark.subThoroughfare
                            ].compactMap { $0 }.joined(separator: " ")
                            observer.onNext(address)
                        } else {
                            observer.onNext("")
                        }
                        observer.onCompleted()
                    }
                    return Disposables.create()
                }
                .observe(on: MainScheduler.instance)
            }
            .asDriver(onErrorJustReturn: "")

        let memoText = photoMemo
            .map { photoMemo -> String in
                if let memo = photoMemo.memo, !memo.isEmpty {
                    return memo
                } else {
                    return NSLocalizedString("photo_detail.no_memo", comment: "")
                }
            }
            .asDriver(onErrorJustReturn: NSLocalizedString("photo_detail.no_memo", comment: ""))

        let shouldFlipToBack = input.swipeLeft
            .asDriver(onErrorJustReturn: ())

        let shouldFlipToFront = input.swipeRight
            .asDriver(onErrorJustReturn: ())

        let shouldDismiss = input.closeButtonTapped
            .asDriver(onErrorJustReturn: ())

        let saveResult = input.saveButtonTapped
            .withLatestFrom(photoMemo)
            .map { photoMemo -> Result<Void, Error> in
                guard let image = UIImage(data: photoMemo.imageData) else {
                    return .failure(NSError(domain: "PhotoDetailViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: NSLocalizedString("photo_detail.image_load_error", comment: "")]))
                }
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                return .success(())
            }
            .asDriver(onErrorJustReturn: .failure(NSError(domain: "PhotoDetailViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: NSLocalizedString("photo_detail.save_failed", comment: "")])))

        let shareImage = input.shareButtonTapped
            .withLatestFrom(photoMemo)
            .compactMap { photoMemo -> UIImage? in
                UIImage(data: photoMemo.imageData)
            }
            .asDriver(onErrorDriveWith: .empty())

        return Output(
            photoImage: photoImage,
            dateText: dateText,
            locationText: locationText,
            memoText: memoText,
            shouldFlipToBack: shouldFlipToBack,
            shouldFlipToFront: shouldFlipToFront,
            shouldDismiss: shouldDismiss,
            saveResult: saveResult,
            shareImage: shareImage
        )
    }
}
