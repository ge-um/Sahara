//
//  PhotoCardViewModel.swift
//  Sahara
//
//  Created by 금가경 on 10/12/25.
//

import CoreLocation
import Foundation
import RealmSwift
import RxCocoa
import RxSwift
import UIKit

final class PhotoCardViewModel: BaseViewModelProtocol {
    private let cardId: ObjectId
    private let disposeBag = DisposeBag()

    struct Input {
        let viewDidLoad: Observable<Void>
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
    }

    init(cardId: ObjectId) {
        self.cardId = cardId
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

        return Output(
            photoImage: photoImage,
            dateText: dateText,
            locationText: locationText,
            memoText: memoText,
            shouldFlipToBack: shouldFlipToBack,
            shouldFlipToFront: shouldFlipToFront
        )
    }
}
