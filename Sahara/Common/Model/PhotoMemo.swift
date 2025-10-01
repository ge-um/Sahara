//
//  PhotoMemo.swift
//  Sahara
//
//  Created by 금가경 on 9/27/25.
//

import RealmSwift
import UIKit

final class PhotoMemo: Object {
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted var date: Date
    @Persisted var imageData: Data
    @Persisted var memo: String?
    @Persisted var latitude: Double?
    @Persisted var longitude: Double?

    convenience init(date: Date, imageData: Data, memo: String? = nil, latitude: Double? = nil, longitude: Double? = nil) {
        self.init()
        self.date = date
        self.imageData = imageData
        self.memo = memo
        self.latitude = latitude
        self.longitude = longitude
    }
}
