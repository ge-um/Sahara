//
//  FolderViewController.swift
//  Sahara
//
//  Created by 금가경 on 10/13/25.
//

import RxCocoa
import RxSwift
import SnapKit
import UIKit

final class FolderViewController: UIViewController {
    private let viewModel = FolderViewModel()
    private let disposeBag = DisposeBag()
    private let viewWillAppearRelay = PublishRelay<Void>()

    private lazy var collectionView: UICollectionView = {
        let layout = GridLayout(numberOfColumns: 2, cellSpacing: 8)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(FolderCell.self, forCellWithReuseIdentifier: FolderCell.identifier)
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        return collectionView
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        return indicator
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        bind()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewWillAppearRelay.accept(())
    }

    private func configureUI() {
        view.backgroundColor = .clear

        view.addSubview(collectionView)
        view.addSubview(activityIndicator)

        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        activityIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    private func bind() {
        let input = FolderViewModel.Input(
            viewWillAppear: viewWillAppearRelay.asObservable(),
            itemSelected: collectionView.rx.itemSelected.asObservable()
        )

        let output = viewModel.transform(input: input)

        output.folderGroups
            .drive(collectionView.rx.items(cellIdentifier: FolderCell.identifier, cellType: FolderCell.self)) { _, group, cell in
                cell.configure(with: group)
            }
            .disposed(by: disposeBag)

        output.isLoading
            .drive(with: self) { owner, isLoading in
                if isLoading {
                    owner.activityIndicator.startAnimating()
                } else {
                    owner.activityIndicator.stopAnimating()
                }
            }
            .disposed(by: disposeBag)

        output.navigateToPhotos
            .drive(with: self) { owner, folderGroup in
                let galleryVC = CardListViewController(folderName: folderGroup.folderName)
                if let parentGalleryVC = owner.parent as? GalleryViewController {
                    parentGalleryVC.navigationController?.pushViewController(galleryVC, animated: true)
                }
            }
            .disposed(by: disposeBag)
    }
}
