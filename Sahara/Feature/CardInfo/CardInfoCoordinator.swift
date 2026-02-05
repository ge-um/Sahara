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
    weak var cardInfoViewController: UIViewController?
    private var onMediaEditingComplete: ((UIImage, ImageSourceData) -> Void)?
    private var mediaEditorCoordinator: MediaEditorCoordinator?
    private var currentImageSource: ImageSourceData?

    init(parentViewController: UIViewController) {
        self.parentViewController = parentViewController
    }

    func start() {}

    private func getPresentingViewController() -> UIViewController? {
        if let cardInfoVC = cardInfoViewController {
            return cardInfoVC.navigationController ?? cardInfoVC
        }
        return parentViewController
    }

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
        getPresentingViewController()?.present(navController, animated: true)
    }

    func presentMediaEditor(
        imageSource: ImageSourceData,
        selectedImageSubject: BehaviorSubject<UIImage?>,
        onEditingComplete: @escaping (UIImage, ImageSourceData) -> Void
    ) {
        self.onMediaEditingComplete = onEditingComplete
        self.currentImageSource = imageSource

        let navController = UINavigationController()
        navController.modalPresentationStyle = .fullScreen

        self.mediaEditorCoordinator = MediaEditorCoordinator(
            navigationController: navController,
            imageSource: imageSource
        )
        self.mediaEditorCoordinator?.delegate = self
        self.mediaEditorCoordinator?.start()

        getPresentingViewController()?.present(navController, animated: true)
    }

    func presentDatePicker(initialDate: Date, onDateSelected: @escaping (Date) -> Void) {
        let datePickerVC = DatePickerViewController(initialDate: initialDate)
        datePickerVC.onDateSelected = onDateSelected

        if let sheet = datePickerVC.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
        }
        getPresentingViewController()?.present(datePickerVC, animated: true)
    }

    func presentLocationSearch(onLocationSelected: @escaping (CLLocationCoordinate2D, String) -> Void) {
        let locationSearchVC = LocationSearchViewController()
        locationSearchVC.onLocationSelected = onLocationSelected

        let nav = UINavigationController(rootViewController: locationSearchVC)
        getPresentingViewController()?.present(nav, animated: true)
    }

    func dismiss() {
        if let cardInfoVC = cardInfoViewController {
            cardInfoVC.navigationController?.dismiss(animated: true)
        } else {
            parentViewController?.dismiss(animated: true)
        }
    }

    func popToList(isEditMode: Bool) {
        guard let cardInfoVC = cardInfoViewController,
              let cardInfoNavController = cardInfoVC.navigationController,
              let presentingVC = cardInfoNavController.presentingViewController else {
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

        cardInfoNavController.dismiss(animated: true) {
            nav.popViewController(animated: true)
        }
    }
}

extension CardInfoCoordinator: MediaEditorCoordinatorDelegate {
    func didFinishEditing(with image: UIImage, stickers: [StickerDTO]) {
        getPresentingViewController()?.dismiss(animated: true) { [weak self] in
            guard let self = self, let originalImageSource = self.currentImageSource else { return }

            let updatedImageSource = ImageSourceData(
                image: image,
                format: originalImageSource.format,
                stickers: stickers
            )

            self.onMediaEditingComplete?(image, updatedImageSource)
            self.onMediaEditingComplete = nil
            self.mediaEditorCoordinator = nil
            self.currentImageSource = nil
        }
    }

    func didCancelEditing() {
        onMediaEditingComplete = nil
        mediaEditorCoordinator = nil
        currentImageSource = nil
    }
}
