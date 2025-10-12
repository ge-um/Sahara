//
//  LocationSelectionCard.swift
//  Sahara
//
//  Created by 금가경 on 10/12/25.
//

import CoreLocation
import MapKit
import RxCocoa
import RxSwift
import SnapKit
import UIKit

final class LocationSelectionCard: UIView {
    private let cardView: UIView = {
        let view = UIView()
        view.backgroundColor = ColorSystem.cardBackground
        view.layer.cornerRadius = 12
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("card_info.location", comment: "")
        label.font = FontSystem.galmuriMono(size: 14)
        label.textColor = ColorSystem.labelTitle
        return label
    }()

    let locationLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("card_info.location_placeholder", comment: "")
        label.font = FontSystem.galmuriMono(size: 14)
        label.textColor = ColorSystem.labelPrimary
        label.numberOfLines = 2
        return label
    }()

    let removeButton: UIButton = {
        let button = UIButton()
        var config = UIButton.Configuration.filled()
        config.title = "✕"
        config.baseBackgroundColor = UIColor(hex: "4D4D4D")
        config.baseForegroundColor = .white
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(top: 2, leading: 2, bottom: 2, trailing: 2)

        var titleAttr = AttributeContainer()
        titleAttr.font = FontSystem.galmuriMono(size: 10)
        config.attributedTitle = AttributedString(config.title ?? "", attributes: titleAttr)

        button.configuration = config
        button.isHidden = true
        return button
    }()

    let searchButton: UIButton = {
        let button = UIButton()
        var config = UIButton.Configuration.filled()
        config.title = NSLocalizedString("card_info.search_location", comment: "")
        config.image = UIImage(systemName: "magnifyingglass")
        config.imagePlacement = .leading
        config.imagePadding = 8
        config.baseBackgroundColor = .clear
        config.baseForegroundColor = .black
        config.cornerStyle = .medium
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)

        var titleAttr = AttributeContainer()
        titleAttr.font = FontSystem.galmuriMono(size: 14)
        config.attributedTitle = AttributedString(config.title ?? "", attributes: titleAttr)

        button.configuration = config
        button.layer.cornerRadius = 8
        button.clipsToBounds = true
        return button
    }()

    let mapView: MKMapView = {
        let mapView = MKMapView()
        mapView.layer.cornerRadius = 12
        mapView.clipsToBounds = true
        mapView.isHidden = true
        return mapView
    }()

    var mapViewHeightConstraint: Constraint?
    private let disposeBag = DisposeBag()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureUI() {
        addSubview(cardView)
        cardView.addSubview(titleLabel)
        cardView.addSubview(locationLabel)
        cardView.addSubview(removeButton)
        cardView.addSubview(searchButton)
        cardView.addSubview(mapView)

        cardView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        titleLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(16)
        }

        locationLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.equalToSuperview().inset(16)
            make.trailing.equalTo(removeButton.snp.leading).offset(-8)
        }

        removeButton.snp.makeConstraints { make in
            make.centerY.equalTo(locationLabel)
            make.trailing.equalToSuperview().inset(16)
            make.width.height.equalTo(16)
        }

        searchButton.snp.makeConstraints { make in
            make.top.equalTo(locationLabel.snp.bottom).offset(12)
            make.horizontalEdges.equalToSuperview().inset(16)
            make.height.equalTo(44)
        }

        mapView.snp.makeConstraints { make in
            make.top.equalTo(searchButton.snp.bottom).offset(12)
            make.horizontalEdges.equalToSuperview().inset(16)
            mapViewHeightConstraint = make.height.equalTo(0).constraint
            make.bottom.equalToSuperview().inset(16)
        }
    }

    func updateMapView(with coordinate: CLLocationCoordinate2D) {
        mapView.isHidden = false
        mapViewHeightConstraint?.update(offset: 200)
        layoutIfNeeded()

        let region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: 1000,
            longitudinalMeters: 1000
        )
        mapView.setRegion(region, animated: true)

        mapView.removeAnnotations(mapView.annotations)
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
    }

    func hideMapView() {
        mapView.isHidden = true
        mapViewHeightConstraint?.update(offset: 0)
        mapView.removeAnnotations(mapView.annotations)
    }

    func bind(
        viewModel: LocationSelectionCardViewModel,
        initialLocation: Observable<CLLocation?>,
        selectedLocation: Observable<(coordinate: CLLocationCoordinate2D, address: String)>
    ) -> LocationSelectionCardViewModel.Output {
        let input = LocationSelectionCardViewModel.Input(
            searchButtonTapped: searchButton.rx.tap.asObservable(),
            removeButtonTapped: removeButton.rx.tap.asObservable(),
            initialLocation: initialLocation,
            selectedLocation: selectedLocation
        )

        let output = viewModel.transform(input: input)

        output.locationText
            .drive(locationLabel.rx.text)
            .disposed(by: disposeBag)

        output.locationTextColor
            .drive(locationLabel.rx.textColor)
            .disposed(by: disposeBag)

        output.removeButtonHidden
            .drive(removeButton.rx.isHidden)
            .disposed(by: disposeBag)

        output.mapCoordinate
            .compactMap { $0 }
            .drive(with: self) { owner, coordinate in
                owner.updateMapView(with: coordinate)
            }
            .disposed(by: disposeBag)

        output.mapCoordinate
            .filter { $0 == nil }
            .drive(with: self) { owner, _ in
                owner.hideMapView()
            }
            .disposed(by: disposeBag)

        return output
    }
}
