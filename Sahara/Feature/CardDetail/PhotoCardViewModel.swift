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
        let animatedStickers: Driver<[AnimatedStickerInfo]>
    }

    struct AnimatedStickerInfo {
        let url: URL?
        let localFilePath: String?
        let x: Double
        let y: Double
        let scale: Double
        let rotation: Double
        let zIndex: Int
    }

    init(cardId: ObjectId) {
        self.cardId = cardId
    }

    func transform(input: Input) -> Output {
        let cardDataRelay = BehaviorRelay<(image: Data, originalImage: Data?, date: Date, latitude: Double?, longitude: Double?, memo: String?, stickers: [Sticker])?>(value: nil)

        input.viewDidLoad
            .withUnretained(self)
            .observe(on: MainScheduler.instance)
            .bind { owner, _ in
                let realm = try! Realm()
                guard let card = realm.object(ofType: Card.self, forPrimaryKey: owner.cardId) else { return }

                let data = (
                    image: card.editedImageData,
                    originalImage: card.originalImageData,
                    date: card.date,
                    latitude: card.latitude,
                    longitude: card.longitude,
                    memo: card.memo,
                    stickers: Array(card.stickers)
                )
                cardDataRelay.accept(data)
            }
            .disposed(by: disposeBag)

        let cardData = cardDataRelay.compactMap { $0 }.asObservable()

        let hasStickers = cardData
            .map { data -> Bool in
                !data.stickers.isEmpty
            }
            .share(replay: 1)

        let photoImage = Observable.combineLatest(cardData, hasStickers)
            .map { data, hasStickers -> UIImage? in
                let screenScale = UIScreen.main.scale
                let screenBounds = UIScreen.main.bounds
                let maxDim = max(screenBounds.width, screenBounds.height) * screenScale
                let imageData = (hasStickers && data.originalImage != nil) ? data.originalImage! : data.image
                return ImageDownsampler.downsample(data: imageData, maxDimension: maxDim)
            }
            .asDriver(onErrorJustReturn: nil)

        let animatedStickers = Observable.combineLatest(cardData, hasStickers)
            .map { data, hasStickers -> [AnimatedStickerInfo] in
                guard hasStickers, data.originalImage != nil else { return [] }
                let stickers = data.stickers
                    .compactMap { sticker -> AnimatedStickerInfo? in
                        let url: URL? = {
                            if let urlString = sticker.resourceUrl {
                                return URL(string: urlString)
                            }
                            return nil
                        }()

                        guard url != nil || sticker.localFilePath != nil else { return nil }

                        return AnimatedStickerInfo(
                            url: url,
                            localFilePath: sticker.localFilePath,
                            x: sticker.x,
                            y: sticker.y,
                            scale: sticker.scale,
                            rotation: sticker.rotation,
                            zIndex: sticker.zIndex
                        )
                    }

                let klipyCount = stickers.filter { $0.url != nil }.count
                let photoCount = stickers.filter { $0.localFilePath != nil }.count
                Logger.cardInfo.info("Loaded stickers for detail view: klipy=\(klipyCount), photo=\(photoCount), total=\(stickers.count)")

                return stickers
            }
            .asDriver(onErrorJustReturn: [])

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
            shouldFlipToFront: shouldFlipToFront,
            animatedStickers: animatedStickers
        )
    }
}
