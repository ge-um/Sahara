//
//  LocationUtility.swift
//  Sahara
//
//  Created by 금가경 on 10/06/25.
//

import CoreLocation

final class LocationUtility {
    static func reverseGeocode(location: CLLocation, completion: @escaping (String) -> Void) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            guard let placemark = placemarks?.first else {
                completion("")
                return
            }

            let address = [
                placemark.locality,
                placemark.thoroughfare,
                placemark.subThoroughfare
            ].compactMap { $0 }.joined(separator: " ")

            completion(address)
        }
    }
}
