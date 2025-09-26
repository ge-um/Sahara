//
//  GalleryViewModel.swift
//  Sahara
//
//  Created by 금가경 on 9/26/25.
//

import Foundation
import RxCocoa
import RxSwift

protocol GalleryViewModelProtocol: BaseViewModelProtocol where Input == GalleryViewModel.Input, Output == GalleryViewModel.Output {
}

final class GalleryViewModel: GalleryViewModelProtocol {
    private let disposeBag = DisposeBag()
    
    struct Input {
        let addButtonTapped: Observable<Void>
    }
    
    struct Output {
        let showPhotoPicker: Driver<Void>
    }
    
    func transform(input: Input) -> Output {
        let showPhotoPicker = PublishRelay<Void>()
        
        input.addButtonTapped
            .bind(to: showPhotoPicker)
            .disposed(by: disposeBag)
        
        return Output(
            showPhotoPicker: showPhotoPicker.asDriver(
                onErrorJustReturn: ()
            )
        )
    }
}
