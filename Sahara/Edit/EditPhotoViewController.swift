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
    
    private let viewModel: any EditViewModelProtocol
    private let disposeBag = DisposeBag()
    
    init(viewModel: any EditViewModelProtocol) {
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
            saveButtonTapped: saveButton.rx.tap.asObservable()
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

        photoImageView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(20)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(200)
        }
    }
    
    private func configureNavigation() {
        navigationItem.title = "사진 편집"
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: dismissButton)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: saveButton)
    }
}
