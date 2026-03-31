//
//  LocationSearchViewController.swift
//  Sahara
//
//  Created by 금가경 on 9/26/25.
//

import MapKit
import RxCocoa
import RxSwift
import SnapKit
import UIKit

final class LocationSearchViewController: UIViewController {
    private let viewModel = LocationSearchViewModel()
    private let disposeBag = DisposeBag()
    private let viewDidLoadRelay = PublishRelay<Void>()
    private let locationSelectedRelay = PublishRelay<MKLocalSearchCompletion>()

    private let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = NSLocalizedString("location_search.placeholder", comment: "")
        searchBar.searchBarStyle = .minimal
        if let textField = searchBar.value(forKey: "searchField") as? UITextField {
            textField.font = .typography(.label)
        }
        return searchBar
    }()

    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(LocationSearchCell.self, forCellReuseIdentifier: LocationSearchCell.identifier)
        tableView.keyboardDismissMode = .onDrag
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        tableView.backgroundColor = .clear
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        return tableView
    }()

    private let currentLocationButton: UIButton = {
        let button = UIButton()
        var config = UIButton.Configuration.filled()
        config.title = NSLocalizedString("location_search.use_current_location", comment: "")
        config.image = UIImage(systemName: "location.fill")
        config.imagePlacement = .leading
        config.imagePadding = 8
        config.baseBackgroundColor = .clear
        config.baseForegroundColor = .white
        config.cornerStyle = .medium
        config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)

        var titleAttr = AttributeContainer()
        titleAttr.font = UIFont.typography(.label)
        config.attributedTitle = AttributedString(config.title ?? "", attributes: titleAttr)

        button.configuration = config
        button.layer.cornerRadius = 8
        button.clipsToBounds = true
        return button
    }()

    var onLocationSelected: ((CLLocationCoordinate2D, String) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        bind()
        currentLocationButton.applyGradient(.ctaBlue)
        viewDidLoadRelay.accept(())
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        currentLocationButton.applyGradient(.ctaBlue)
    }

    private func bind() {
        let input = LocationSearchViewModel.Input(
            viewDidLoad: viewDidLoadRelay.asObservable(),
            searchText: searchBar.rx.text.orEmpty.asObservable(),
            currentLocationTapped: currentLocationButton.rx.tap.asObservable(),
            locationSelected: locationSelectedRelay.asObservable()
        )

        let output = viewModel.transform(input: input)

        output.searchResults
            .drive(tableView.rx.items(cellIdentifier: LocationSearchCell.identifier, cellType: LocationSearchCell.self)) { _, result, cell in
                cell.configure(with: result)
            }
            .disposed(by: disposeBag)

        output.selectedLocation
            .drive(with: self) { owner, location in
                owner.onLocationSelected?(location.0, location.1)
                owner.dismiss(animated: true)
            }
            .disposed(by: disposeBag)

        output.showPermissionAlert
            .drive(with: self) { owner, _ in
                PermissionService.shared.showPermissionAlert(for: .location, from: owner)
            }
            .disposed(by: disposeBag)

        output.isLoadingLocation
            .drive(with: self) { owner, isLoading in
                var config = owner.currentLocationButton.configuration
                config?.showsActivityIndicator = isLoading
                owner.currentLocationButton.configuration = config
            }
            .disposed(by: disposeBag)

        tableView.rx.modelSelected(MKLocalSearchCompletion.self)
            .bind(with: self) { owner, completion in
                owner.locationSelectedRelay.accept(completion)
            }
            .disposed(by: disposeBag)

        tableView.rx.itemSelected
            .bind(with: self) { owner, indexPath in
                owner.tableView.deselectRow(at: indexPath, animated: true)
            }
            .disposed(by: disposeBag)

        searchBar.rx.searchButtonClicked
            .bind(with: self) { owner, _ in
                owner.searchBar.resignFirstResponder()
            }
            .disposed(by: disposeBag)
    }

    private func configureUI() {
        view.applyGradient(.subtle)

        navigationController?.view.applyGradient(.subtle)
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true

        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.typography(.title)
        ]
        navigationController?.navigationBar.titleTextAttributes = titleAttributes
        navigationItem.title = NSLocalizedString("location_search.title", comment: "")

        let cancelButton = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )
        cancelButton.setTitleTextAttributes([.font: UIFont.typography(.label)], for: .normal)
        cancelButton.setTitleTextAttributes([.font: UIFont.typography(.label)], for: .highlighted)
        navigationItem.leftBarButtonItem = cancelButton

        view.addSubview(searchBar)
        view.addSubview(currentLocationButton)
        view.addSubview(tableView)

        searchBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.horizontalEdges.equalToSuperview()
        }

        currentLocationButton.snp.makeConstraints { make in
            make.top.equalTo(searchBar.snp.bottom).offset(12)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(50)
        }

        tableView.snp.makeConstraints { make in
            make.top.equalTo(currentLocationButton.snp.bottom).offset(12)
            make.horizontalEdges.bottom.equalToSuperview()
        }
    }

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
}
