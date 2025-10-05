//
//  MediaAnnotationView.swift
//  Sahara
//
//  Created by 금가경 on 10/2/25.
//

import MapKit
import UIKit

final class MediaAnnotationView: BaseMediaAnnotationView {
    func configure(with image: UIImage?) {
        configure(image: image, count: 1)
    }
}
