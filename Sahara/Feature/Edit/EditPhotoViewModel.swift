//
//  EditPhotoViewModel.swift
//  Sahara
//
//  Created by 금가경 on 9/26/25.
//

import RealmSwift
import RxCocoa
import RxSwift
import UIKit

protocol EditViewModelProtocol: BaseViewModelProtocol where Input == EditPhotoViewModel.Input, Output == EditPhotoViewModel.Output {
}

final class EditPhotoViewModel: EditViewModelProtocol {
    private let disposeBag = DisposeBag()
    private let realm = try! Realm()
    
    private let selectedPhoto: UIImage?
    
    struct Input {
        let dismissButtonTapped: Observable<Void>
        let saveButtonTapped: Observable<Void>
        let memoText: Observable<String?>
        let selectedDate: Observable<Date>
    }
    
    struct Output {
        let editedImage: Driver<UIImage?>
        let dismiss: Driver<Void>
    }
    
    init(selectedPhoto: UIImage?) {
        self.selectedPhoto = selectedPhoto
    }
    
    func transform(input: Input) -> Output {
        let editedImage = BehaviorRelay<UIImage?>(value: selectedPhoto)
        let dismiss = PublishRelay<Void>()
        
        input.dismissButtonTapped
            .bind(to: dismiss)
            .disposed(by: disposeBag)
        
        input.saveButtonTapped
            .withLatestFrom(
                Observable.combineLatest(input.memoText, input.selectedDate)
            )
            .subscribe(with: self) { owner, memoAndDate in
                let (memoText, selectedDate) = memoAndDate
                owner.saveToRealm(memo: memoText, date: selectedDate)
                dismiss.accept(())
            }
            .disposed(by: disposeBag)
        
        return Output(
            editedImage: editedImage.asDriver(onErrorJustReturn: nil),
            dismiss: dismiss.asDriver(onErrorJustReturn: ())
        )
    }
}

extension EditPhotoViewModel {
    private func saveToRealm(memo: String?, date: Date) {
        guard let selectedPhoto, let imageData = selectedPhoto.jpegData(compressionQuality: 0.8) else { return }
        
        let photoMemo = PhotoMemo(date: date, imageData: imageData, memo: memo)
        
        do {
            try realm.write {
                realm.add(photoMemo)
            }
        } catch {
            print("Failed to save data")
        }
        print(realm.configuration.fileURL!)
    }
}
