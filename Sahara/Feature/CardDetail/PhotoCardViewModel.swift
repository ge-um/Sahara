//
//  PhotoCardViewModel.swift
//  Sahara
//
//  Created by 금가경 on 10/12/25.
//

import CoreLocation
import Foundation
import OSLog
import RealmSwift
import RxCocoa
import RxSwift
import UIKit

final class PhotoCardViewModel: BaseViewModelProtocol {
    private let cardId: ObjectId
    private let realmManager: RealmManagerProtocol
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

    init(cardId: ObjectId, realmManager: RealmManagerProtocol = RealmManager.shared) {
        self.cardId = cardId
        self.realmManager = realmManager
    }

    func transform(input: Input) -> Output {
        let cardDataRelay = BehaviorRelay<(image: Data, date: Date, latitude: Double?, longitude: Double?, memo: String?)?>(value: nil)

        input.viewDidLoad
            .withUnretained(self)
            .observe(on: MainScheduler.instance)
            .bind { owner, _ in
                guard let card = owner.realmManager.fetchObject(Card.self, forPrimaryKey: owner.cardId),
                      let imageData = card.resolvedImageData() else { return }

                let data = (
                    image: imageData,
                    date: card.date,
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
                let screenScale = UIScreen.main.scale
                let screenBounds = UIScreen.main.bounds
                let maxDim = max(screenBounds.width, screenBounds.height) * screenScale
                return ImageDownsampler.downsample(data: data.image, maxDimension: maxDim)
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
