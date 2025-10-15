//
//  LocationSearchViewModel.swift
//  Sahara
//
//  Created by 금가경 on 10/9/25.
//

import CoreLocation
import Foundation
import MapKit
import RxCocoa
import RxSwift

final class LocationSearchViewModel: NSObject, BaseViewModelProtocol, MKLocalSearchCompleterDelegate, CLLocationManagerDelegate {
    private let disposeBag = DisposeBag()
    private let locationManager = CLLocationManager()
    private let searchCompleter = MKLocalSearchCompleter()

    private let searchResultsSubject = BehaviorSubject<[MKLocalSearchCompletion]>(value: [])
    private let locationUpdateSubject = PublishSubject<CLLocation>()

    struct Input {
        let viewDidLoad: Observable<Void>
        let searchText: Observable<String>
        let currentLocationTapped: Observable<Void>
        let locationSelected: Observable<MKLocalSearchCompletion>
    }

    struct Output {
        let searchResults: Driver<[MKLocalSearchCompletion]>
        let selectedLocation: Driver<(CLLocationCoordinate2D, String)>
        let showPermissionAlert: Driver<Void>
        let isLoadingLocation: Driver<Bool>
    }

    override init() {
        super.init()
        searchCompleter.delegate = self
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func transform(input: Input) -> Output {
        let selectedLocationRelay = PublishRelay<(CLLocationCoordinate2D, String)>()
        let showPermissionAlertRelay = PublishRelay<Void>()
        let isLoadingRelay = BehaviorRelay<Bool>(value: false)

        input.viewDidLoad
            .bind(with: self) { owner, _ in
                owner.searchCompleter.resultTypes = [.address, .pointOfInterest]
            }
            .disposed(by: disposeBag)

        input.searchText
            .do(onNext: { text in
                if !text.isEmpty {
                    AnalyticsManager.shared.logLocationSearchUsed()
                }
            })
            .bind(with: self) { owner, text in
                owner.searchCompleter.queryFragment = text
            }
            .disposed(by: disposeBag)

        input.currentLocationTapped
            .withUnretained(self)
            .do(onNext: { owner, _ in
                let authStatus = owner.locationManager.authorizationStatus
                if authStatus == .denied || authStatus == .restricted {
                    AnalyticsManager.shared.logLocationPermissionDenied()
                }
            })
            .bind { owner, _ in
                let authStatus = owner.locationManager.authorizationStatus

                switch authStatus {
                case .notDetermined:
                    owner.locationManager.requestWhenInUseAuthorization()
                case .authorizedWhenInUse, .authorizedAlways:
                    isLoadingRelay.accept(true)
                    if let cachedLocation = owner.locationManager.location {
                        owner.handleLocation(cachedLocation, selectedRelay: selectedLocationRelay, loadingRelay: isLoadingRelay)
                    } else {
                        owner.locationManager.requestLocation()
                    }
                case .denied, .restricted:
                    showPermissionAlertRelay.accept(())
                @unknown default:
                    break
                }
            }
            .disposed(by: disposeBag)

        locationUpdateSubject
            .withUnretained(self)
            .do(onNext: { _ in
                AnalyticsManager.shared.logLocationSaved(source: "current_location")
            })
            .bind { owner, location in
                owner.handleLocation(location, selectedRelay: selectedLocationRelay, loadingRelay: isLoadingRelay)
            }
            .disposed(by: disposeBag)

        input.locationSelected
            .withUnretained(self)
            .do(onNext: { _ in
                AnalyticsManager.shared.logLocationSaved(source: "search")
            })
            .flatMap { owner, completion -> Observable<(CLLocationCoordinate2D, String)> in
                return owner.searchLocation(completion: completion)
            }
            .bind(to: selectedLocationRelay)
            .disposed(by: disposeBag)

        return Output(
            searchResults: searchResultsSubject.asDriver(onErrorJustReturn: []),
            selectedLocation: selectedLocationRelay.asDriver(onErrorDriveWith: .empty()),
            showPermissionAlert: showPermissionAlertRelay.asDriver(onErrorJustReturn: ()),
            isLoadingLocation: isLoadingRelay.asDriver()
        )
    }

    private func handleLocation(_ location: CLLocation, selectedRelay: PublishRelay<(CLLocationCoordinate2D, String)>, loadingRelay: BehaviorRelay<Bool>) {
        LocationUtility.reverseGeocode(location: location) { address in
            loadingRelay.accept(false)
            let finalAddress = address.isEmpty ? NSLocalizedString("location_search.current_location", comment: "") : address
            selectedRelay.accept((location.coordinate, finalAddress))
        }
    }

    private func searchLocation(completion: MKLocalSearchCompletion) -> Observable<(CLLocationCoordinate2D, String)> {
        return Observable.create { observer in
            let searchRequest = MKLocalSearch.Request(completion: completion)
            let search = MKLocalSearch(request: searchRequest)

            search.start { response, error in
                guard let coordinate = response?.mapItems.first?.placemark.coordinate else {
                    observer.onCompleted()
                    return
                }

                let title = completion.title
                let subtitle = completion.subtitle
                let fullAddress = subtitle.isEmpty ? title : "\(title), \(subtitle)"

                observer.onNext((coordinate, fullAddress))
                observer.onCompleted()
            }

            return Disposables.create()
        }
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        searchResultsSubject.onNext(completer.results)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        locationUpdateSubject.onNext(location)
    }
}
