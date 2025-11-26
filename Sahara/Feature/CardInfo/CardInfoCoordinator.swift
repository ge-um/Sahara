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

final class CardInfoCoordinator: Coordinator, CardInfoCoordinatorProtocol {
    var navigationController: UINavigationController?
    weak var delegate: CardInfoCoordinatorDelegate?
    weak var parentViewController: UIViewController?
    private var onMediaEditingComplete: ((UIImage) -> Void)?
    private var mediaEditorCoordinator: MediaEditorCoordinator?

    init(parentViewController: UIViewController) {
        self.parentViewController = parentViewController
    }

    func start() {}

    func presentMediaSelection(selectedImageSubject: BehaviorSubject<UIImage?>, completion: @escaping (ImageSourceData, CLLocation?, Date?) -> Void) {
        let mediaSelectionVC = MediaSelectionViewController()
        mediaSelectionVC.onMediaSelected = { imageSource, location, date in
            completion(imageSource, location, date)
        }

        let navController = UINavigationController(rootViewController: mediaSelectionVC)
        if let sheet = navController.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        parentViewController?.present(navController, animated: true)
    }

    func presentMediaEditor(
        imageSource: ImageSourceData,
        selectedImageSubject: BehaviorSubject<UIImage?>,
        onEditingComplete: @escaping (UIImage) -> Void
    ) {
        self.onMediaEditingComplete = onEditingComplete

        parentViewController?.dismiss(animated: true) { [weak self] in
            guard let self = self else { return }

            let navController = UINavigationController()
            navController.modalPresentationStyle = .fullScreen

            self.mediaEditorCoordinator = MediaEditorCoordinator(
                navigationController: navController,
                imageSource: imageSource
            )
            self.mediaEditorCoordinator?.delegate = self
            self.mediaEditorCoordinator?.start()

            self.parentViewController?.present(navController, animated: true)
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
        parentViewController?.dismiss(animated: true)
    }

    func popToList(isEditMode: Bool) {
        guard let parentVC = parentViewController,
              let presentingVC = parentVC.presentingViewController else {
            return
        }

        var navController: UINavigationController?

        if let tabBarController = presentingVC as? UITabBarController {
            navController = tabBarController.selectedViewController as? UINavigationController
        } else if let nav = presentingVC as? UINavigationController {
            navController = nav
        } else {
            navController = presentingVC.navigationController
        }

        guard let nav = navController else { return }

        parentVC.dismiss(animated: true) {
            nav.popViewController(animated: true)
        }
    }
}

extension CardInfoCoordinator: MediaEditorCoordinatorDelegate {
    func didFinishEditing(with image: UIImage) {
        parentViewController?.dismiss(animated: true) { [weak self] in
            self?.onMediaEditingComplete?(image)
            self?.onMediaEditingComplete = nil
            self?.mediaEditorCoordinator = nil
        }
    }

    func didCancelEditing() {
        onMediaEditingComplete = nil
        mediaEditorCoordinator = nil
    }
}
