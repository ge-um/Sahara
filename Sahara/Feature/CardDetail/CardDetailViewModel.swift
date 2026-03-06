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
    let cardId: ObjectId
    private let realmManager: RealmManagerProtocol
    private let disposeBag = DisposeBag()

    struct Input {
        let viewDidLoad: Observable<Void>
        let saveButtonTapped: Observable<Void>
        let shareButtonTapped: Observable<Void>
        let deleteConfirmed: Observable<Void>
    }

    struct Output {
        let saveResult: Driver<Result<Void, Error>>
        let shareImage: Driver<UIImage>
        let deleteCompleted: Driver<Void>
    }

    init(cardId: ObjectId, realmManager: RealmManagerProtocol = RealmManager.shared) {
        self.cardId = cardId
        self.realmManager = realmManager
    }

    func transform(input: Input) -> Output {
        let cardImageRelay = BehaviorRelay<Data?>(value: nil)

        input.viewDidLoad
            .withUnretained(self)
            .observe(on: MainScheduler.instance)
            .bind { owner, _ in
                guard let card = owner.realmManager.fetchObject(Card.self, forPrimaryKey: owner.cardId) else { return }
                cardImageRelay.accept(card.resolvedImageData())
            }
            .disposed(by: disposeBag)

        let cardImage = cardImageRelay.compactMap { $0 }.asObservable()

        let saveResult = input.saveButtonTapped
            .withLatestFrom(cardImage)
            .flatMap { imageData -> Observable<Result<Void, Error>> in
                return Observable.create { observer in
                    PHPhotoLibrary.shared().performChanges({
                        let request = PHAssetCreationRequest.forAsset()
                        request.addResource(with: .photo, data: imageData, options: nil)
                    }) { success, error in
                        if success {
                            observer.onNext(.success(()))
                        } else if let error = error {
                            observer.onNext(.failure(error))
                        } else {
                            observer.onNext(.failure(NSError(domain: "CardDetailViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: NSLocalizedString("photo_detail.save_failed", comment: "")])))
                        }
                        observer.onCompleted()
                    }
                    return Disposables.create()
                }
            }
            .asDriver(onErrorJustReturn: .failure(NSError(domain: "CardDetailViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: NSLocalizedString("photo_detail.save_failed", comment: "")])))

        let shareImage = input.shareButtonTapped
            .withLatestFrom(cardImage)
            .compactMap { imageData -> UIImage? in
                let screenScale = UIScreen.main.scale
                let screenBounds = UIScreen.main.bounds
                let maxDim = max(screenBounds.width, screenBounds.height) * screenScale
                return ImageDownsampler.downsample(data: imageData, maxDimension: maxDim)
            }
            .asDriver(onErrorDriveWith: .empty())

        let deleteCompleted = input.deleteConfirmed
            .withUnretained(self)
            .flatMap { owner, _ in
                owner.realmManager.deleteCard(forPrimaryKey: owner.cardId)
                    .catch { _ in .empty() }
            }
            .asDriver(onErrorJustReturn: ())

        return Output(
            saveResult: saveResult,
            shareImage: shareImage,
            deleteCompleted: deleteCompleted
        )
    }
}
