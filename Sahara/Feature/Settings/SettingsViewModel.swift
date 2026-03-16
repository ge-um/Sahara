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
        let exportPhotos: Driver<Void>
        let exportBackup: Driver<Void>
        let importBackup: Driver<Void>
    }

    func transform(input: Input) -> Output {
        let defaultSections = [
            SettingsSection(type: .general, items: [.language]),
            SettingsSection(type: .dataManagement, items: [.exportPhotos, .exportBackup, .importBackup, .cloudSync]),
            SettingsSection(type: .notifications, items: [.serviceNews]),
            SettingsSection(type: .support, items: [.contactDeveloper]),
            SettingsSection(type: .about, items: [.releaseNotes, .versionInfo])
        ]

        let sections = input.viewWillAppear
            .map { _ in defaultSections }
            .asDriver(onErrorJustReturn: defaultSections)

        let openLanguageSelection = input.itemSelected.whenSelected(.language)
        let openMailComposer = input.itemSelected
            .compactMap { $0 == .contactDeveloper ? DeveloperConfig.developerEmail : nil }
            .asDriver(onErrorDriveWith: .empty())
        let openReleaseNotes = input.itemSelected.whenSelected(.releaseNotes)
        let exportPhotos = input.itemSelected.whenSelected(.exportPhotos)
        let exportBackup = input.itemSelected.whenSelected(.exportBackup)
        let importBackup = input.itemSelected.whenSelected(.importBackup)

        return Output(
            sections: sections,
            openLanguageSelection: openLanguageSelection,
            openMailComposer: openMailComposer,
            openReleaseNotes: openReleaseNotes,
            exportPhotos: exportPhotos,
            exportBackup: exportBackup,
            importBackup: importBackup
        )
    }
}

private extension Observable where Element == SettingsMenuItem {
    func whenSelected(_ target: SettingsMenuItem) -> Driver<Void> {
        compactMap { $0 == target ? () : nil }
            .asDriver(onErrorDriveWith: .empty())
    }
}
