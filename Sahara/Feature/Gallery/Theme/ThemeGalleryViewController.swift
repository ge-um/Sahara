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
        view.backgroundColor = .systemBackground

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
            .drive(with: self) { owner, photoMemos in
                let galleryVC = MapPhotoGalleryViewController(photoMemos: photoMemos)
                let nav = UINavigationController(rootViewController: galleryVC)
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

final class ThemeCell: UITableViewCell {
    static let identifier = "ThemeCell"

    private let thumbnailImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.backgroundColor = .systemGray6
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        return label
    }()

    private let countLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureUI() {
        contentView.addSubview(thumbnailImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(countLabel)

        thumbnailImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(80)
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(thumbnailImageView.snp.trailing).offset(16)
            make.top.equalTo(thumbnailImageView).offset(10)
            make.trailing.equalToSuperview().inset(16)
        }

        countLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.trailing.equalToSuperview().inset(16)
        }
    }

    func configure(with group: ThemeGroup) {
        titleLabel.text = group.category.localizedName
        countLabel.text = String(format: NSLocalizedString("common.photo_count", comment: ""), group.photoMemos.count)

        if let firstPhoto = group.photoMemos.first,
           let image = UIImage(data: firstPhoto.editedImageData) {
            thumbnailImageView.image = image
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        thumbnailImageView.image = nil
        titleLabel.text = nil
        countLabel.text = nil
    }
}
