//
//  EditPhotoViewController.swift
//  Sahara
//
//  Created by 금가경 on 9/26/25.
//

import RxCocoa
import RxSwift
import SnapKit
import UIKit

final class EditPhotoViewController: UIViewController {
    private let photoImageView = UIImageView()
    
    private let memo: UITextView = {
        let textView = UITextView()
        textView.text = "메모를 남기면 사진 뒤쪽에서 메모를 볼 수 있어요! (300자 제한)"
        return textView
    }()
    
    private let date: UIDatePicker = {
        let picker = UIDatePicker()
        picker.date = Date()
        picker.datePickerMode = .date
        picker.calendar = .autoupdatingCurrent
        return picker
    }()
    
    private let saveButton: UIButton = {
        let button = UIButton()
        var config = UIButton.Configuration.plain()
        config.title = "저장"
        button.configuration = config
        return button
    }()
    
    private let dismissButton: UIButton = {
        let button = UIButton()
        var config = UIButton.Configuration.plain()
        config.title = "닫기"
        button.configuration = config
        return button
    }()
    
    private let viewModel: EditPhotoViewModel
    private let disposeBag = DisposeBag()
    
    init(viewModel: EditPhotoViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        configureNavigation()
        bind()
    }
    
    private func bind() {
        let input = EditPhotoViewModel.Input(
            dismissButtonTapped: dismissButton.rx.tap.asObservable(),
            saveButtonTapped: saveButton.rx.tap.asObservable(),
            memoText: memo.rx.text.asObservable(),
            selectedDate: date.rx.date.asObservable()
        )
        let output = viewModel.transform(input: input)
        
        output.editedImage
            .drive(photoImageView.rx.image)
            .disposed(by: disposeBag)
        
        output.dismiss
            .drive(with: self) { owner, _ in
                owner.dismiss(animated: true)
            }
            .disposed(by: disposeBag)
    }
    
    private func configureUI() {
        view.backgroundColor = .white
        
        view.addSubview(photoImageView)
        view.addSubview(date)
        view.addSubview(memo)

        photoImageView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(20)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(200)
        }
        
        date.snp.makeConstraints { make in
            make.top.equalTo(photoImageView.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
            make.height.equalTo(100)
        }
        
        memo.snp.makeConstraints { make in
            make.top.equalTo(date.snp.bottom).offset(20)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(100)
        }
    }
    
    private func configureNavigation() {
        navigationItem.title = "사진 편집"
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: dismissButton)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: saveButton)
    }
}
