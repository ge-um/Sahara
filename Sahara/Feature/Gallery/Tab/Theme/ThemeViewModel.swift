//
//  ThemeViewModel.swift
//  Sahara
//
//  Created by 금가경 on 10/2/25.
//

import Foundation
import RealmSwift
import RxCocoa
import RxSwift
import UIKit
import Vision

final class ThemeViewModel: BaseViewModelProtocol {
    private let realmManager: RealmManagerProtocol
    private let disposeBag = DisposeBag()

    init(realmManager: RealmManagerProtocol = RealmManager.shared) {
        self.realmManager = realmManager
    }

    struct Input {
        let viewWillAppear: Observable<Void>
        let itemSelected: Observable<IndexPath>
    }

    struct Output {
        let themeGroups: Driver<[ThemeGroup]>
        let isLoading: Driver<Bool>
        let navigateToPhotos: Driver<ThemeGroup>
    }

    func transform(input: Input) -> Output {
        let themeGroupsRelay = BehaviorRelay<[ThemeGroup]>(value: [])
        let isLoadingRelay = BehaviorRelay<Bool>(value: false)

        input.viewWillAppear
            .take(1)
            .withUnretained(self)
            .do(onNext: { _, _ in
                isLoadingRelay.accept(true)
            })
            .flatMap { owner, _ -> Observable<Void> in
                return owner.observeAndAnalyzePhotos(themeGroupsRelay: themeGroupsRelay)
            }
            .do(onNext: { _ in
                isLoadingRelay.accept(false)
            })
            .subscribe()
            .disposed(by: disposeBag)

        let navigateToPhotos = input.itemSelected
            .withLatestFrom(themeGroupsRelay) { indexPath, groups in
                groups[indexPath.row]
            }
            .asDriver(onErrorDriveWith: .empty())

        return Output(
            themeGroups: themeGroupsRelay.asDriver(),
            isLoading: isLoadingRelay.asDriver(),
            navigateToPhotos: navigateToPhotos
        )
    }

    private func observeAndAnalyzePhotos(themeGroupsRelay: BehaviorRelay<[ThemeGroup]>) -> Observable<Void> {
        return realmManager.observeAllCards()
            .map { [weak self] cards -> Void in
                guard let self = self else { return }
                var categoryDict: [ThemeCategory: [ObjectId]] = [:]

                for card in cards {
                    guard let image = ImageDownsampler.downsample(data: card.editedImageData, maxDimension: 500),
                          let cgImage = image.cgImage else { continue }

                    let category = self.classifyImage(cgImage)
                    categoryDict[category, default: []].append(card.id)
                }

                let groups = categoryDict.map { ThemeGroup(category: $0.key, cardIds: $0.value) }
                    .sorted { first, second in
                        if first.category == .others { return false }
                        if second.category == .others { return true }
                        return first.category.localizedName < second.category.localizedName
                    }

                themeGroupsRelay.accept(groups)
            }
    }


    private func classifyImage(_ cgImage: CGImage) -> ThemeCategory {
        let request = VNClassifyImageRequest()

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])

            if let observations = request.results {
                let topLabels = observations.prefix(5).map { $0.identifier }
                return ThemeCategory.category(for: topLabels)
            }
        } catch {
        }

        return .others
    }
}
