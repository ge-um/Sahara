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
        bind()
    }
    
    private func bind() {
        let input = EditPhotoViewModel.Input()
        let output = viewModel.transform(input: input)
        
        output.editedImage
            .drive(photoImageView.rx.image)
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
}
