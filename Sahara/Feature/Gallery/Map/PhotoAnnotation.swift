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
    let photoMemoIds: [ObjectId]
    let photoCount: Int

    var title: String? {
        return String(format: NSLocalizedString("common.photo_count", comment: ""), photoCount)
    }

    init(coordinate: CLLocationCoordinate2D, photoMemoIds: [ObjectId]) {
        self.coordinate = coordinate
        self.photoMemoIds = photoMemoIds
        self.photoCount = photoMemoIds.count
        super.init()
    }
}

extension PhotoAnnotation {
    static let clusterID = "PhotoCluster"
}
