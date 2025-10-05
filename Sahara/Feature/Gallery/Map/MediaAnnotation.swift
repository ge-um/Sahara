//
//  MediaAnnotation.swift
//  Sahara
//
//  Created by 금가경 on 10/1/25.
//

import MapKit
import RealmSwift

final class MediaAnnotation: NSObject, MKAnnotation, IsIdentifiable {
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

extension MediaAnnotation {
    static let clusterID = "MediaCluster"
}
