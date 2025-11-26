//
//  CardInfoCoordinatorProtocol.swift
//  Sahara
//
//  Created by 금가경 on 10/20/25.
//

import CoreLocation
import RxSwift
import UIKit

protocol CardInfoCoordinatorProtocol: AnyObject {
    func presentMediaSelection(
        selectedImageSubject: BehaviorSubject<UIImage?>,
        completion: @escaping (ImageSourceData, CLLocation?, Date?) -> Void
    )

    func presentMediaEditor(
        imageSource: ImageSourceData,
        selectedImageSubject: BehaviorSubject<UIImage?>,
        onEditingComplete: @escaping (UIImage, ImageSourceData, Bool) -> Void
    )

    func presentDatePicker(
        initialDate: Date,
        onDateSelected: @escaping (Date) -> Void
    )

    func presentLocationSearch(
        onLocationSelected: @escaping (CLLocationCoordinate2D, String) -> Void
    )

    func dismiss()
    func popToList(isEditMode: Bool)
}
