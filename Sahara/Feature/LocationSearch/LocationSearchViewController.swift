//
//  LocationSearchViewController.swift
//  Sahara
//
//  Created by 금가경 on 9/26/25.
//

import MapKit
import SnapKit
import UIKit

final class LocationSearchViewController: UIViewController {
    private let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = NSLocalizedString("location_search.placeholder", comment: "")
        searchBar.searchBarStyle = .minimal
        if let textField = searchBar.value(forKey: "searchField") as? UITextField {
            textField.font = FontSystem.galmuriMono(size: 14)
        }
        return searchBar
    }()

    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(LocationSearchCell.self, forCellReuseIdentifier: LocationSearchCell.identifier)
        tableView.delegate = self
        tableView.dataSource = self
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
        titleAttr.font = FontSystem.galmuriMono(size: 14)
        config.attributedTitle = AttributedString(config.title ?? "", attributes: titleAttr)

        button.configuration = config
        button.layer.cornerRadius = 8
        button.clipsToBounds = true
        return button
    }()

    private let searchCompleter = MKLocalSearchCompleter()
    private var searchResults: [MKLocalSearchCompletion] = []
    var onLocationSelected: ((CLLocationCoordinate2D, String) -> Void)?
    private let locationManager = CLLocationManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        setupSearchCompleter()
        setupActions()
        currentLocationButton.applyGradient(.blueGradient)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        currentLocationButton.applyGradient(.blueGradient)
    }

    private func setupSearchCompleter() {
        searchCompleter.delegate = self
        searchCompleter.resultTypes = [.address, .pointOfInterest]
        searchBar.delegate = self

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    private func setupActions() {
        currentLocationButton.addTarget(self, action: #selector(currentLocationTapped), for: .touchUpInside)
    }

    @objc private func currentLocationTapped() {
        let authStatus = locationManager.authorizationStatus

        switch authStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            var config = currentLocationButton.configuration
            config?.showsActivityIndicator = true
            currentLocationButton.configuration = config

            if let cachedLocation = locationManager.location {
                handleLocation(cachedLocation)
            } else {
                locationManager.requestLocation()
            }
        case .denied, .restricted:
            showLocationPermissionAlert()
        @unknown default:
            break
        }
    }

    private func showLocationPermissionAlert() {
        PermissionManager.shared.showPermissionAlert(for: .location, from: self)
    }

    private func configureUI() {
        view.applyGradient(.grayGradient)

        navigationController?.view.applyGradient(.grayGradient)
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true

        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: FontSystem.galmuriMono(size: 16)
        ]
        navigationController?.navigationBar.titleTextAttributes = titleAttributes
        navigationItem.title = NSLocalizedString("location_search.title", comment: "")

        let cancelButton = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )
        cancelButton.setTitleTextAttributes([.font: FontSystem.galmuriMono(size: 14)], for: .normal)
        cancelButton.setTitleTextAttributes([.font: FontSystem.galmuriMono(size: 14)], for: .highlighted)
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

extension LocationSearchViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchCompleter.queryFragment = searchText
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

extension LocationSearchViewController: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        searchResults = completer.results
        tableView.reloadData()
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
    }
}

extension LocationSearchViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: LocationSearchCell.identifier,
            for: indexPath
        ) as? LocationSearchCell else {
            return UITableViewCell()
        }

        let result = searchResults[indexPath.row]
        cell.configure(with: result)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let result = searchResults[indexPath.row]
        let searchRequest = MKLocalSearch.Request(completion: result)
        let search = MKLocalSearch(request: searchRequest)

        search.start { [weak self] response, error in
            guard let coordinate = response?.mapItems.first?.placemark.coordinate else { return }

            let title = result.title
            let subtitle = result.subtitle
            let fullAddress = subtitle.isEmpty ? title : "\(title), \(subtitle)"

            self?.onLocationSelected?(coordinate, fullAddress)
            self?.dismiss(animated: true)
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}

extension LocationSearchViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocationButton.configuration?.showsActivityIndicator = false
        handleLocation(location)
    }

    private func handleLocation(_ location: CLLocation) {
        LocationUtility.reverseGeocode(location: location) { [weak self] address in
            guard let self = self else { return }
            var config = self.currentLocationButton.configuration
            config?.showsActivityIndicator = false
            self.currentLocationButton.configuration = config

            let finalAddress = address.isEmpty ? "현재 위치" : address
            self.onLocationSelected?(location.coordinate, finalAddress)
            self.dismiss(animated: true)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        currentLocationButton.configuration?.showsActivityIndicator = false
        showToast(message: NSLocalizedString("location_search.location_error", comment: ""))
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {

    }
}

final class LocationSearchCell: UITableViewCell {
    static let identifier = "LocationSearchCell"

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = FontSystem.galmuriMono(size: 14)
        label.textColor = .label
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = FontSystem.galmuriMono(size: 12)
        label.textColor = .secondaryLabel
        return label
    }()

    private let iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "mappin.circle.fill")
        imageView.tintColor = .systemBlue
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.addSubview(iconView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)

        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(20)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(28)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(12)
            make.leading.equalTo(iconView.snp.trailing).offset(12)
            make.trailing.equalToSuperview().inset(20)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.equalTo(titleLabel)
            make.trailing.equalToSuperview().inset(20)
        }
    }

    func configure(with completion: MKLocalSearchCompletion) {
        titleLabel.text = completion.title
        subtitleLabel.text = completion.subtitle
    }
}