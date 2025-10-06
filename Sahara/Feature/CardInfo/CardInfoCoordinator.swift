//
//  CardInfoCoordinator.swift
//  Sahara
//
//  Created by 금가경 on 10/6/25.
//

import CoreLocation
import RxSwift
import UIKit

protocol CardInfoCoordinatorDelegate: AnyObject {
    func didFinishEditing()
    func didCancel()
}

final class CardInfoCoordinator: Coordinator {
    var navigationController: UINavigationController?
    weak var delegate: CardInfoCoordinatorDelegate?
    weak var parentViewController: UIViewController?

    init(parentViewController: UIViewController) {
        self.parentViewController = parentViewController
    }

    func start() {}

    func presentMediaSelection(selectedImageSubject: BehaviorSubject<UIImage?>, completion: @escaping (UIImage, CLLocation?, Date?) -> Void) {
        let mediaSelectionVC = MediaSelectionViewController()
        mediaSelectionVC.onMediaSelected = { image, location, date in
            completion(image, location, date)
        }

        let navController = UINavigationController(rootViewController: mediaSelectionVC)
        if let sheet = navController.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        parentViewController?.present(navController, animated: true)
    }

    func presentMediaEditor(
        image: UIImage,
        selectedImageSubject: BehaviorSubject<UIImage?>,
        onEditingComplete: @escaping (UIImage) -> Void
    ) {
        parentViewController?.dismiss(animated: true) { [weak self] in
            let viewModel = MediaEditorViewModel(originalImage: image)
            let editorVC = MediaEditorViewController(viewModel: viewModel)
            editorVC.onEditingComplete = onEditingComplete

            let navController = UINavigationController(rootViewController: editorVC)
            navController.modalPresentationStyle = .fullScreen
            self?.parentViewController?.present(navController, animated: true)
        }
    }

    func presentDatePicker(initialDate: Date, onDateSelected: @escaping (Date) -> Void) {
        let datePickerVC = DatePickerViewController(initialDate: initialDate)
        datePickerVC.onDateSelected = onDateSelected

        if let sheet = datePickerVC.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
        }
        parentViewController?.present(datePickerVC, animated: true)
    }

    func presentLocationSearch(onLocationSelected: @escaping (CLLocationCoordinate2D, String) -> Void) {
        let locationSearchVC = LocationSearchViewController()
        locationSearchVC.onLocationSelected = onLocationSelected

        let nav = UINavigationController(rootViewController: locationSearchVC)
        parentViewController?.present(nav, animated: true)
    }

    func dismiss() {
        if let navController = parentViewController?.navigationController,
           navController.presentingViewController == nil {
            navController.popViewController(animated: true)
        } else {
            parentViewController?.navigationController?.dismiss(animated: true)
        }
    }

    func popToList(isEditMode: Bool) {
        if let navController = parentViewController?.navigationController {
            let viewControllers = navController.viewControllers
            if isEditMode {
                let targetIndex = viewControllers.count >= 4 ? viewControllers.count - 4 : 0
                navController.popToViewController(viewControllers[targetIndex], animated: true)
            } else {
                navController.popToRootViewController(animated: true)
            }
        }
    }
}
