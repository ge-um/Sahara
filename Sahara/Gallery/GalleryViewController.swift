//
//  GalleryViewController.swift
//  Sahara
//
//  Created by 금가경 on 9/26/25.
//

import PhotosUI
import RxCocoa
import RxSwift
import SnapKit
import UIKit

final class GalleryViewController: UIViewController {
    private let addButton: UIButton = {
        let button = UIButton()
        var config = UIButton.Configuration.plain()
        config.title = "메모 작성하기"
        config.baseForegroundColor = .white
        config.background.backgroundColor = .systemBlue
        button.configuration = config
        return button
    }()
    
    private let photoImageView = UIImageView()
    
    private let viewModel: any GalleryViewModelProtocol
    private let disposeBag = DisposeBag()
    
    init(viewModel: any GalleryViewModelProtocol) {
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
    
    private func configureUI() {
        view.backgroundColor = .white
        
        view.addSubview(addButton)
        view.addSubview(photoImageView)
        
        addButton.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.height.equalTo(44)
        }
        
        photoImageView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(20)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(200)
        }
    }
    
    private func bind() {
        let input = GalleryViewModel.Input(
            addButtonTapped: addButton.rx.tap.asObservable()
        )
        let output = viewModel.transform(input: input)
        
        output.showPhotoPicker
            .drive(with: self) { owner, configuration in
                var configuration = PHPickerConfiguration()
                configuration.selectionLimit = 1
                configuration.filter = .any(of: [.images])
                let picker = PHPickerViewController(configuration: configuration)
                picker.delegate = self
                owner.present(picker, animated: true)
            }
            .disposed(by: disposeBag)
    }
}

extension GalleryViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        let itemProvider = results.first?.itemProvider
        
        if let itemProvider = itemProvider, itemProvider.canLoadObject(ofClass: UIImage.self) {
            itemProvider.loadObject(ofClass: UIImage.self) { image, error in
                DispatchQueue.main.async {
                    let image = image as? UIImage
                    
                    let vm = EditPhotoViewModel(selectedPhoto: image)
                    let vc = EditPhotoViewController(viewModel: vm)
                    vc.modalPresentationStyle = .fullScreen
                    self.present(vc, animated: true)
                }
            }
        }
    }
}
