//
//  PhotoAnnotation.swift
//  Sahara
//
//  Created by Claude on 10/1/25.
//

import MapKit
import RealmSwift

final class PhotoAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let photoMemos: [PhotoMemo]

    var title: String? {
        return String(format: NSLocalizedString("common.photo_count", comment: ""), photoMemos.count)
    }

    init(coordinate: CLLocationCoordinate2D, photoMemos: [PhotoMemo]) {
        self.coordinate = coordinate
        self.photoMemos = photoMemos
        super.init()
    }
}