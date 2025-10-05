//
//  ThemeGalleryViewModel.swift
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

final class ThemeGalleryViewModel: BaseViewModelProtocol {
    private let realmManager = RealmManager.shared
    private let disposeBag = DisposeBag()

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
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onCompleted()
                return Disposables.create()
            }

            let realm = try! Realm()
            let cards = realm.objects(Card.self)

            observer.onNext(())

            let token = cards.observe { [weak self] changes in
                guard let self = self else { return }

                switch changes {
                case .initial(let results), .update(let results, _, _, _):
                    let memos = Array(results)
                    var categoryDict: [ThemeCategory: [Card]] = [:]

                    for photoMemo in memos {
                        guard let image = UIImage(data: photoMemo.editedImageData),
                              let cgImage = image.cgImage else { continue }

                        let category = self.classifyImage(cgImage)
                        categoryDict[category, default: []].append(photoMemo)
                    }

                    let groups = categoryDict.map { ThemeGroup(category: $0.key, photoMemos: $0.value) }
                        .sorted { $0.category.localizedName < $1.category.localizedName }

                    themeGroupsRelay.accept(groups)

                case .error(let error):
                    observer.onError(error)
                }
            }

            return Disposables.create {
                token.invalidate()
            }
        }
    }

    private func analyzePhotos() -> Observable<[ThemeGroup]> {
        return Observable.create { observer in
            let memos = self.realmManager.fetch(Card.self).map { Array($0) } ?? []

            var categoryDict: [ThemeCategory: [Card]] = [:]

            for photoMemo in memos {
                guard let image = UIImage(data: photoMemo.editedImageData),
                      let cgImage = image.cgImage else { continue }

                let category = self.classifyImage(cgImage)
                categoryDict[category, default: []].append(photoMemo)
            }

            let groups = categoryDict.map { ThemeGroup(category: $0.key, photoMemos: $0.value) }
                .sorted { $0.category.localizedName < $1.category.localizedName }

            observer.onNext(groups)
            observer.onCompleted()

            return Disposables.create()
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
