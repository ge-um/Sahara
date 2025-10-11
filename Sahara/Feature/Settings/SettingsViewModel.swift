//
//  SettingsViewModel.swift
//  Sahara
//
//  Created by 금가경 on 1/11/25.
//

import Foundation
import RxCocoa
import RxSwift

final class SettingsViewModel: BaseViewModelProtocol {
    private let disposeBag = DisposeBag()

    struct Input {
        let viewWillAppear: Observable<Void>
        let itemSelected: Observable<SettingsMenuItem>
    }

    struct Output {
        let sections: Driver<[SettingsSection]>
        let openMailComposer: Driver<String>
    }

    func transform(input: Input) -> Output {
        let defaultSections = [
            SettingsSection(type: .support, items: [.contactDeveloper]),
            SettingsSection(type: .about, items: [.versionInfo])
        ]

        let sections = input.viewWillAppear
            .map { _ in defaultSections }
            .asDriver(onErrorJustReturn: defaultSections)

        let openMailComposer = input.itemSelected
            .compactMap { item in
                switch item {
                case .contactDeveloper:
                    return "gageum0@gmail.com"
                case .versionInfo:
                    return nil
                }
            }
            .asDriver(onErrorDriveWith: .empty())

        return Output(
            sections: sections,
            openMailComposer: openMailComposer
        )
    }
}
