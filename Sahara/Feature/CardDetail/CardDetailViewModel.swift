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
import WidgetKit

final class CardDetailViewModel: BaseViewModelProtocol {
    let cardId: ObjectId
    private let realmManager: RealmServiceProtocol
    private let disposeBag = DisposeBag()

    struct Input {
        let viewDidLoad: Observable<Void>
        let saveButtonTapped: Observable<Void>
        let shareButtonTapped: Observable<Void>
        let deleteConfirmed: Observable<Void>
        let widgetToggleTapped: Observable<Void>
    }

    struct Output {
        let saveResult: Driver<Result<Void, Error>>
        let saveFileURL: Driver<URL>
        let shareImage: Driver<UIImage>
        let deleteCompleted: Driver<Void>
        let isWidgetPinned: Driver<Bool>
    }

    init(cardId: ObjectId, realmManager: RealmServiceProtocol = RealmService.shared) {
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
                let cardAgeDays = Calendar.current.dateComponents([.day], from: card.date, to: Date()).day ?? 0
                AnalyticsService.shared.logCardViewed(cardAgeDays: cardAgeDays)
            }
            .disposed(by: disposeBag)

        let cardImage = cardImageRelay.compactMap { $0 }.asObservable()

        let saveAction = configureSaveAction(
            trigger: input.saveButtonTapped, imageData: cardImage
        )
        let saveResult = saveAction.saveResult
        let saveFileURL = saveAction.saveFileURL

        let shareImage = input.shareButtonTapped
            .withLatestFrom(cardImage)
            .compactMap { imageData -> UIImage? in
                let screen = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first?.screen
                let screenScale = screen?.scale ?? 2.0
                let screenBounds = screen?.bounds ?? CGRect(x: 0, y: 0, width: 393, height: 852)
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

        let cardIdString = cardId.stringValue
        let isWidgetPinnedRelay = BehaviorRelay<Bool>(
            value: AppGroupContainer.pinnedCardId == cardIdString
        )

        input.widgetToggleTapped
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                let isPinned = AppGroupContainer.pinnedCardId == self.cardId.stringValue
                if isPinned {
                    AppGroupContainer.pinnedCardId = nil
                } else {
                    AppGroupContainer.pinnedCardId = self.cardId.stringValue
                }
                isWidgetPinnedRelay.accept(!isPinned)
                WidgetDataService.shared.refreshWidgetData()
            })
            .disposed(by: disposeBag)

        input.viewDidLoad
            .map { AppGroupContainer.pinnedCardId == cardIdString }
            .bind(to: isWidgetPinnedRelay)
            .disposed(by: disposeBag)

        return Output(
            saveResult: saveResult,
            saveFileURL: saveFileURL,
            shareImage: shareImage,
            deleteCompleted: deleteCompleted,
            isWidgetPinned: isWidgetPinnedRelay.asDriver()
        )
    }

    private func configureSaveAction(
        trigger: Observable<Void>, imageData: Observable<Data>
    ) -> (saveResult: Driver<Result<Void, Error>>, saveFileURL: Driver<URL>) {
        #if targetEnvironment(macCatalyst)
        let saveResult: Driver<Result<Void, Error>> = .empty()
        let saveFileURL = trigger
            .withLatestFrom(imageData)
            .observe(on: ConcurrentDispatchQueueScheduler(qos: .userInitiated))
            .compactMap { imageData -> URL? in
                let ext = ImageFormatConverter.detect(from: imageData)?.rawValue ?? "jpeg"
                let fileName = "Sahara_Photo_\(UUID().uuidString).\(ext)"
                let tempURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent(fileName)
                do {
                    try imageData.write(to: tempURL)
                    return tempURL
                } catch {
                    return nil
                }
            }
            .observe(on: MainScheduler.instance)
            .asDriver(onErrorDriveWith: .empty())
        return (saveResult, saveFileURL)
        #else
        let saveFileURL: Driver<URL> = .empty()
        let saveResult = trigger
            .withLatestFrom(imageData)
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
        return (saveResult, saveFileURL)
        #endif
    }
}
