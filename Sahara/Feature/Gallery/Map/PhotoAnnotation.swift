//
//  PhotoAnnotation.swift
//  Sahara
//
//  Created by 금가경 on 10/1/25.
//

import MapKit
import RealmSwift

final class PhotoAnnotation: NSObject, MKAnnotation, IsIdentifiable {
    let coordinate: CLLocationCoordinate2D
    let photoMemos: [Card]

    var title: String? {
        return String(format: NSLocalizedString("common.photo_count", comment: ""), photoMemos.count)
    }

    init(coordinate: CLLocationCoordinate2D, photoMemos: [Card]) {
        self.coordinate = coordinate
        self.photoMemos = photoMemos
        super.init()
    }
}
