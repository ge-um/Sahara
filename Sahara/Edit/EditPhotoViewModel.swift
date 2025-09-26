//
//  EditPhotoViewModel.swift
//  Sahara
//
//  Created by 금가경 on 9/26/25.
//

import RxCocoa
import RxSwift
import UIKit

protocol EditViewModelProtocol: BaseViewModelProtocol where Input == EditPhotoViewModel.Input, Output == EditPhotoViewModel.Output {
}

final class EditPhotoViewModel: EditViewModelProtocol {
    private let disposeBag = DisposeBag()
    private let selectedPhoto: UIImage?
    
    struct Input {
        
    }
    
    struct Output {
        let editedImage: Driver<UIImage?>
    }
    
    init(selectedPhoto: UIImage?) {
        self.selectedPhoto = selectedPhoto
    }
    
    func transform(input: Input) -> Output {
        let editedImage = BehaviorRelay<UIImage?>(value: selectedPhoto)
        
        return Output(
            editedImage: editedImage.asDriver(onErrorJustReturn: nil
            )
        )
    }
}
