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
        let openLanguageSelection: Driver<Void>
        let openMailComposer: Driver<String>
        let openReleaseNotes: Driver<Void>
    }

    func transform(input: Input) -> Output {
        let defaultSections = [
            SettingsSection(type: .general, items: [.language]),
            SettingsSection(type: .notifications, items: [.serviceNews]),
            SettingsSection(type: .support, items: [.contactDeveloper]),
            SettingsSection(type: .about, items: [.releaseNotes, .versionInfo])
        ]

        let sections = input.viewWillAppear
            .map { _ in defaultSections }
            .asDriver(onErrorJustReturn: defaultSections)

        let openLanguageSelection = input.itemSelected
            .compactMap { item in
                switch item {
                case .language:
                    return ()
                default:
                    return nil
                }
            }
            .asDriver(onErrorDriveWith: .empty())

        let openMailComposer = input.itemSelected
            .compactMap { item in
                switch item {
                case .contactDeveloper:
                    return DeveloperConfig.developerEmail
                default:
                    return nil
                }
            }
            .asDriver(onErrorDriveWith: .empty())

        let openReleaseNotes = input.itemSelected
            .compactMap { item in
                switch item {
                case .releaseNotes:
                    return ()
                default:
                    return nil
                }
            }
            .asDriver(onErrorDriveWith: .empty())

        return Output(
            sections: sections,
            openLanguageSelection: openLanguageSelection,
            openMailComposer: openMailComposer,
            openReleaseNotes: openReleaseNotes
        )
    }
}
