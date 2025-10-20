//
//  MockCardInfoCoordinator.swift
//  SaharaTests
//
//  Created by 금가경 on 10/20/25.
//

import CoreLocation
import RxSwift
import UIKit
@testable import Sahara

final class MockCardInfoCoordinator: CardInfoCoordinatorProtocol {
    var presentMediaSelectionCalled = false
    var presentMediaEditorCalled = false
    var presentDatePickerCalled = false
    var presentLocationSearchCalled = false
    var dismissCalled = false
    var popToListCalled = false

    var lastPresentedDate: Date?
    var lastPresentedImage: UIImage?
    var lastPopToListIsEditMode: Bool?
    var lastMediaSelectionCompletion: ((UIImage, CLLocation?, Date?) -> Void)?
    var lastMediaEditorCompletion: ((UIImage) -> Void)?

    var onPresentMediaSelection: (() -> Void)?
    var onPresentMediaEditor: (() -> Void)?
    var onPresentDatePicker: (() -> Void)?
    var onPresentLocationSearch: (() -> Void)?
    var onDismiss: (() -> Void)?
    var onPopToList: (() -> Void)?

    func presentMediaSelection(
        selectedImageSubject: BehaviorSubject<UIImage?>,
        completion: @escaping (UIImage, CLLocation?, Date?) -> Void
    ) {
        presentMediaSelectionCalled = true
        lastMediaSelectionCompletion = completion
        onPresentMediaSelection?()
    }

    func presentMediaEditor(
        image: UIImage,
        selectedImageSubject: BehaviorSubject<UIImage?>,
        onEditingComplete: @escaping (UIImage) -> Void
    ) {
        presentMediaEditorCalled = true
        lastPresentedImage = image
        lastMediaEditorCompletion = onEditingComplete
        onPresentMediaEditor?()
    }

    func presentDatePicker(
        initialDate: Date,
        onDateSelected: @escaping (Date) -> Void
    ) {
        presentDatePickerCalled = true
        lastPresentedDate = initialDate
        onDateSelected(Date())
        onPresentDatePicker?()
    }

    func presentLocationSearch(
        onLocationSelected: @escaping (CLLocationCoordinate2D, String) -> Void
    ) {
        presentLocationSearchCalled = true
        let coordinate = CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780)
        onLocationSelected(coordinate, "서울")
        onPresentLocationSearch?()
    }

    func dismiss() {
        dismissCalled = true
        onDismiss?()
    }

    func popToList(isEditMode: Bool) {
        popToListCalled = true
        lastPopToListIsEditMode = isEditMode
        onPopToList?()
    }

    func reset() {
        presentMediaSelectionCalled = false
        presentMediaEditorCalled = false
        presentDatePickerCalled = false
        presentLocationSearchCalled = false
        dismissCalled = false
        popToListCalled = false
        lastPresentedDate = nil
        lastPresentedImage = nil
        lastPopToListIsEditMode = nil
        lastMediaSelectionCompletion = nil
        lastMediaEditorCompletion = nil
        onPresentMediaSelection = nil
        onPresentMediaEditor = nil
        onPresentDatePicker = nil
        onPresentLocationSearch = nil
        onDismiss = nil
        onPopToList = nil
    }
}
