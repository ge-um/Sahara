//
//  ReleaseNotesViewModel.swift
//  Sahara
//
//  Created by 금가경 on 10/12/25.
//

import Foundation
import RxCocoa
import RxSwift

final class ReleaseNotesViewModel: BaseViewModelProtocol {
    private let disposeBag = DisposeBag()

    struct Input {
        let viewWillAppear: Observable<Void>
    }

    struct Output {
        let releaseNotes: Driver<[ReleaseNote]>
    }

    func transform(input: Input) -> Output {
        let releaseNotes = input.viewWillAppear
            .map { _ in ReleaseNote.allVersions }
            .asDriver(onErrorJustReturn: [])

        return Output(releaseNotes: releaseNotes)
    }
}
