//
//  ThemeGalleryViewController.swift
//  Sahara
//
//  Created by 금가경 on 10/1/25.
//

import RxCocoa
import RxSwift
import SnapKit
import UIKit

final class ThemeGalleryViewController: UIViewController {
    private let viewModel = ThemeGalleryViewModel()
    private let disposeBag = DisposeBag()
    private let viewWillAppearRelay = PublishRelay<Void>()

    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(ThemeCell.self, forCellReuseIdentifier: ThemeCell.identifier)
        tableView.rowHeight = 100
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        return tableView
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

    func refreshData() {
        viewWillAppearRelay.accept(())
    }

    private func configureUI() {
        view.backgroundColor = .clear

        view.addSubview(tableView)
        view.addSubview(activityIndicator)

        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        activityIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    private func bind() {
        let input = ThemeGalleryViewModel.Input(
            viewWillAppear: viewWillAppearRelay.asObservable(),
            itemSelected: tableView.rx.itemSelected.asObservable()
        )

        let output = viewModel.transform(input: input)

        output.themeGroups
            .drive(tableView.rx.items(cellIdentifier: ThemeCell.identifier, cellType: ThemeCell.self)) { _, group, cell in
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
            .drive(with: self) { owner, themeGroup in
                let galleryVC = MapPhotoGalleryViewController(photoMemos: themeGroup.photoMemos, themeCategory: themeGroup.category)
                let nav = UINavigationController(rootViewController: galleryVC)
                nav.modalPresentationStyle = .fullScreen
                owner.present(nav, animated: true)
            }
            .disposed(by: disposeBag)

        tableView.rx.itemSelected
            .bind(with: self) { owner, indexPath in
                owner.tableView.deselectRow(at: indexPath, animated: true)
            }
            .disposed(by: disposeBag)
    }
}
