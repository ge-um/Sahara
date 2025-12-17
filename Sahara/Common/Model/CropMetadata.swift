//
//  CropMetadata.swift
//  Sahara
//
//  Created by 금가경 on 12/17/25.
//

import RealmSwift

final class CropMetadata: EmbeddedObject {
    @Persisted var x: Double
    @Persisted var y: Double
    @Persisted var width: Double
    @Persisted var height: Double

    convenience init(x: Double, y: Double, width: Double, height: Double) {
        self.init()
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }
}
