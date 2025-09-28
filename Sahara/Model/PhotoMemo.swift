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
    
    convenience init(date: Date, imageData: Data, memo: String? = nil) {
        self.init()
        self.date = date
        self.imageData = imageData
        self.memo = memo
    }
}
