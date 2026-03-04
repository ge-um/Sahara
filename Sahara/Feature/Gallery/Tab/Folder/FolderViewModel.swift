//
//  FolderViewModel.swift
//  Sahara
//
//  Created by 금가경 on 10/13/25.
//

import Foundation
import RealmSwift
import RxCocoa
import RxSwift

struct FolderGroup {
    let folderName: String
    let cards: [Card]
}

final class FolderViewModel: BaseViewModelProtocol {
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
        let folderGroups: Driver<[FolderGroup]>
        let isLoading: Driver<Bool>
        let navigateToPhotos: Driver<FolderGroup>
    }

    func transform(input: Input) -> Output {
        let folderGroupsRelay = BehaviorRelay<[FolderGroup]>(value: [])
        let isLoadingRelay = BehaviorRelay<Bool>(value: false)

        observeAndGroupByFolder(folderGroupsRelay: folderGroupsRelay)

        input.viewWillAppear
            .take(1)
            .withUnretained(self)
            .bind { _, _ in
                isLoadingRelay.accept(true)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isLoadingRelay.accept(false)
                }
            }
            .disposed(by: disposeBag)

        let navigateToPhotos = input.itemSelected
            .withLatestFrom(folderGroupsRelay) { indexPath, groups in
                groups[indexPath.row]
            }
            .asDriver(onErrorDriveWith: .empty())

        return Output(
            folderGroups: folderGroupsRelay.asDriver(),
            isLoading: isLoadingRelay.asDriver(),
            navigateToPhotos: navigateToPhotos
        )
    }

    private func observeAndGroupByFolder(folderGroupsRelay: BehaviorRelay<[FolderGroup]>) {
        realmManager.observeAllCards()
            .map { cards -> [FolderGroup] in
                var folderDict: [String: [Card]] = [:]

                for card in cards {
                    let folderName = card.customFolder ?? NSLocalizedString("folder.default", comment: "")
                    folderDict[folderName, default: []].append(card)
                }

                return folderDict.map { FolderGroup(folderName: $0.key, cards: $0.value) }
                    .sorted { first, second in
                        if first.folderName == NSLocalizedString("folder.default", comment: "") {
                            return true
                        }
                        if second.folderName == NSLocalizedString("folder.default", comment: "") {
                            return false
                        }
                        return first.folderName < second.folderName
                    }
            }
            .bind(to: folderGroupsRelay)
            .disposed(by: disposeBag)
    }
}
