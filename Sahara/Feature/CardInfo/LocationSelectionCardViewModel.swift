//
//  LocationSelectionCardViewModel.swift
//  Sahara
//
//  Created by 금가경 on 10/12/25.
//

import CoreLocation
import Foundation
import RxCocoa
import RxSwift
import UIKit

final class LocationSelectionCardViewModel: BaseViewModelProtocol {
    private let disposeBag = DisposeBag()

    struct Input {
        let searchButtonTapped: Observable<Void>
        let removeButtonTapped: Observable<Void>
        let initialLocation: Observable<CLLocation?>
        let selectedLocation: Observable<(coordinate: CLLocationCoordinate2D, address: String)>
    }

    struct Output {
        let locationText: Driver<String>
        let locationTextColor: Driver<UIColor>
        let removeButtonHidden: Driver<Bool>
        let mapCoordinate: Driver<CLLocationCoordinate2D?>
        let presentLocationSearch: Driver<Void>
        let location: Driver<CLLocation?>
    }

    func transform(input: Input) -> Output {
        let locationRelay = BehaviorRelay<CLLocation?>(value: nil)
        let locationTextRelay = BehaviorRelay<String>(value: "")
        let locationTextColorRelay = BehaviorRelay<UIColor>(value: .token(.textSecondary))
        let mapCoordinateRelay = BehaviorRelay<CLLocationCoordinate2D?>(value: nil)

        input.initialLocation
            .compactMap { $0 }
            .withUnretained(self)
            .flatMap { owner, location -> Observable<(CLLocation, String)> in
                return Observable.create { observer in
                    LocationUtility.reverseGeocode(location: location) { address in
                        observer.onNext((location, address))
                        observer.onCompleted()
                    }
                    return Disposables.create()
                }
            }
            .bind { location, address in
                locationRelay.accept(location)
                locationTextRelay.accept(address.isEmpty ? "" : address)
                locationTextColorRelay.accept(.token(.textPrimary))
                mapCoordinateRelay.accept(location.coordinate)
            }
            .disposed(by: disposeBag)

        input.selectedLocation
            .bind { coordinate, address in
                let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                locationRelay.accept(location)
                locationTextRelay.accept(address)
                locationTextColorRelay.accept(.token(.textPrimary))
                mapCoordinateRelay.accept(coordinate)
            }
            .disposed(by: disposeBag)

        input.removeButtonTapped
            .bind(with: self) { owner, _ in
                locationRelay.accept(nil)
                locationTextRelay.accept("")
                locationTextColorRelay.accept(.token(.textSecondary))
                mapCoordinateRelay.accept(nil)
            }
            .disposed(by: disposeBag)

        let presentLocationSearch = input.searchButtonTapped
            .asDriver(onErrorJustReturn: ())

        let removeButtonHidden = locationRelay
            .map { $0 == nil }
            .asDriver(onErrorJustReturn: true)

        return Output(
            locationText: locationTextRelay.asDriver(),
            locationTextColor: locationTextColorRelay.asDriver(),
            removeButtonHidden: removeButtonHidden,
            mapCoordinate: mapCoordinateRelay.asDriver(),
            presentLocationSearch: presentLocationSearch,
            location: locationRelay.asDriver()
        )
    }
}
