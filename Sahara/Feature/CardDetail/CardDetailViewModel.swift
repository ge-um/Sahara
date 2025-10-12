//
//  CardDetailViewModel.swift
//  Sahara
//
//  Created by 금가경 on 10/1/25.
//

import CoreLocation
import Foundation
import Photos
import RealmSwift
import RxCocoa
import RxSwift
import UIKit

final class CardDetailViewModel: BaseViewModelProtocol {
    private let cardId: ObjectId
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

    init(cardId: ObjectId) {
        self.cardId = cardId
    }

    func getCard() -> Card? {
        let realm = try! Realm()
        return realm.object(ofType: Card.self, forPrimaryKey: cardId)
    }

    func transform(input: Input) -> Output {
        let cardDataRelay = BehaviorRelay<(image: Data, date: Date, latitude: Double?, longitude: Double?, memo: String?)?>(value: nil)

        input.viewDidLoad
            .withUnretained(self)
            .observe(on: MainScheduler.instance)
            .bind { owner, _ in
                let realm = try! Realm()
                guard let card = realm.object(ofType: Card.self, forPrimaryKey: owner.cardId) else { return }

                let data = (
                    image: card.editedImageData,
                    date: card.createdDate,
                    latitude: card.latitude,
                    longitude: card.longitude,
                    memo: card.memo
                )
                cardDataRelay.accept(data)
            }
            .disposed(by: disposeBag)

        let cardData = cardDataRelay.compactMap { $0 }.asObservable()

        let photoImage = cardData
            .map { data -> UIImage? in
                UIImage(data: data.image)
            }
            .asDriver(onErrorJustReturn: nil)

        let dateText = cardData
            .map { data -> String in
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = NSLocalizedString("photo_detail.date_format", comment: "")
                dateFormatter.locale = Locale.current
                return dateFormatter.string(from: data.date)
            }
            .asDriver(onErrorJustReturn: "")

        let locationText = cardData
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

        let memoText = cardData
            .map { data -> String in
                return data.memo ?? ""
            }
            .asDriver(onErrorJustReturn: "")

        let shouldFlipToBack = input.swipeLeft
            .asDriver(onErrorJustReturn: ())

        let shouldFlipToFront = input.swipeRight
            .asDriver(onErrorJustReturn: ())

        let saveResult = input.saveButtonTapped
            .withLatestFrom(cardData)
            .flatMap { data -> Observable<Result<Void, Error>> in
                guard let image = UIImage(data: data.image) else {
                    return .just(.failure(NSError(domain: "PhotoDetailViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: NSLocalizedString("photo_detail.image_load_error", comment: "")])))
                }

                return Observable.create { observer in
                    PHPhotoLibrary.shared().performChanges({
                        PHAssetChangeRequest.creationRequestForAsset(from: image)
                    }) { success, error in
                        if success {
                            observer.onNext(.success(()))
                        } else if let error = error {
                            observer.onNext(.failure(error))
                        } else {
                            observer.onNext(.failure(NSError(domain: "PhotoDetailViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: NSLocalizedString("photo_detail.save_failed", comment: "")])))
                        }
                        observer.onCompleted()
                    }
                    return Disposables.create()
                }
            }
            .asDriver(onErrorJustReturn: .failure(NSError(domain: "PhotoDetailViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: NSLocalizedString("photo_detail.save_failed", comment: "")])))

        let shareImage = input.shareButtonTapped
            .withLatestFrom(cardData)
            .compactMap { data -> UIImage? in
                UIImage(data: data.image)
            }
            .asDriver(onErrorDriveWith: .empty())

        let deleteCompleted = input.deleteConfirmed
            .withUnretained(self)
            .map { owner, _ -> Void in
                let realm = try! Realm()
                guard let card = realm.object(ofType: Card.self, forPrimaryKey: owner.cardId) else { return () }

                do {
                    try realm.write {
                        realm.delete(card)
                    }
                } catch {}

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
