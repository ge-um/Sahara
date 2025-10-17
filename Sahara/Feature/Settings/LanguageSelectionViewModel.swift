//
//  LanguageSelectionViewModel.swift
//  Sahara
//
//  Created by 금가경 on 10/17/25.
//

import Foundation
import RxCocoa
import RxSwift

final class LanguageSelectionViewModel: BaseViewModelProtocol {
    private let disposeBag = DisposeBag()

    struct Input {
        let viewWillAppear: Observable<Void>
        let languageSelected: Observable<Language>
    }

    struct Output {
        let languages: Driver<[Language]>
        let languageChanged: Driver<Language>
    }

    func transform(input: Input) -> Output {
        let languages = input.viewWillAppear
            .map { _ in Language.allCases }
            .asDriver(onErrorJustReturn: [])

        let languageChanged = input.languageSelected
            .asDriver(onErrorDriveWith: .empty())

        return Output(
            languages: languages,
            languageChanged: languageChanged
        )
    }
}
