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
    }

    struct Output {
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
        let cardImageRelay = BehaviorRelay<Data?>(value: nil)

        input.viewDidLoad
            .withUnretained(self)
            .observe(on: MainScheduler.instance)
            .bind { owner, _ in
                let realm = try! Realm()
                guard let card = realm.object(ofType: Card.self, forPrimaryKey: owner.cardId) else { return }
                cardImageRelay.accept(card.editedImageData)
            }
            .disposed(by: disposeBag)

        let cardImage = cardImageRelay.compactMap { $0 }.asObservable()

        let saveResult = input.saveButtonTapped
            .withLatestFrom(cardImage)
            .flatMap { imageData -> Observable<Result<Void, Error>> in
                guard let image = UIImage(data: imageData) else {
                    return .just(.failure(NSError(domain: "CardDetailViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: NSLocalizedString("photo_detail.image_load_error", comment: "")])))
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
                UIImage(data: imageData)
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
            saveResult: saveResult,
            shareImage: shareImage,
            deleteCompleted: deleteCompleted
        )
    }
}
