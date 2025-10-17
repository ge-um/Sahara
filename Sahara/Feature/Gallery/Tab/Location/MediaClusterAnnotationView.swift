//
//  MediaClusterAnnotationView.swift
//  Sahara
//
//  Created by 금가경 on 10/4/25.
//

import MapKit
import UIKit

final class MediaClusterAnnotationView: BaseMediaAnnotationView {
    func configure(with count: Int, image: UIImage?, isLocked: Bool = false) {
        configure(image: image, count: count, isLocked: isLocked)
    }
}
