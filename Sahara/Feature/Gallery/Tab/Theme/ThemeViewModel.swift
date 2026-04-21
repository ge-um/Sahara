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
    private let realmManager: RealmServiceProtocol
    private let disposeBag = DisposeBag()

    init(realmManager: RealmServiceProtocol = RealmService.shared) {
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
            .withLatestFrom(themeGroupsRelay) { indexPath, groups -> ThemeGroup? in
                guard groups.indices.contains(indexPath.row) else { return nil }
                return groups[indexPath.row]
            }
            .compactMap { $0 }
            .asDriver(onErrorDriveWith: .empty())

        return Output(
            themeGroups: themeGroupsRelay.asDriver(),
            isLoading: isLoadingRelay.asDriver(),
            navigateToPhotos: navigateToPhotos
        )
    }

    private func observeAndAnalyzePhotos(themeGroupsRelay: BehaviorRelay<[ThemeGroup]>) -> Observable<Void> {
        let backgroundScheduler = ConcurrentDispatchQueueScheduler(qos: .utility)

        return realmManager.observeAllCards()
            .map { cards -> [(id: ObjectId, visionTags: [VisionTag])] in
                cards.map { (id: $0.id, visionTags: Array($0.visionTags)) }
            }
            .observe(on: backgroundScheduler)
            .map { [weak self] items -> [ThemeGroup] in
                guard let self = self else { return [] }
                var categoryDict: [ThemeCategory: [ObjectId]] = [:]

                let config = self.realmManager.createConfiguration()
                guard let realm = try? Realm(configuration: config) else { return [] }

                for item in items {
                    autoreleasepool {
                        let category: ThemeCategory
                        if !item.visionTags.isEmpty {
                            category = ThemeCategory.category(for: item.visionTags)
                        } else {
                            guard let card = realm.object(ofType: Card.self, forPrimaryKey: item.id),
                                  let imageData = card.resolvedImageData() else { return }
                            category = self.classifyImage(from: imageData)
                        }
                        categoryDict[category, default: []].append(item.id)
                    }
                }

                return categoryDict.map { ThemeGroup(category: $0.key, cardIds: $0.value) }
                    .sorted { first, second in
                        if first.category == .others { return false }
                        if second.category == .others { return true }
                        return first.category.localizedName < second.category.localizedName
                    }
            }
            .observe(on: MainScheduler.instance)
            .map { groups -> Void in
                themeGroupsRelay.accept(groups)
            }
    }

    private func classifyImage(from imageData: Data) -> ThemeCategory {
        guard let image = ImageDownsampler.downsample(data: imageData, maxDimension: 500),
              let cgImage = image.cgImage else {
            return .others
        }

        let request = VNClassifyImageRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
            if let observations = request.results {
                let topLabels = observations.prefix(5).map { $0.identifier }
                return ThemeCategory.category(for: topLabels)
            }
        } catch {}

        return .others
    }
}
