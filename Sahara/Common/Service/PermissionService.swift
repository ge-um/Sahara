//
//  PermissionService.swift
//  Sahara
//
//  Created by 금가경 on 10/4/25.
//

import AVFoundation
import CoreLocation
import Photos
import UIKit

final class PermissionService {
    enum PermissionType {
        case camera
        case photoLibrary
        case location
    }

    enum PermissionStatus {
        case authorized
        case denied
        case notDetermined
        case limited
    }

    static let shared = PermissionService()

    private init() {}

    func checkPermission(for type: PermissionType) -> PermissionStatus {
        switch type {
        case .camera:
            return checkCameraPermission()
        case .photoLibrary:
            return checkPhotoLibraryPermission()
        case .location:
            return checkLocationPermission()
        }
    }

    func requestPermission(
        for type: PermissionType,
        from viewController: UIViewController,
        completion: @escaping (PermissionStatus) -> Void
    ) {
        switch type {
        case .camera:
            requestCameraPermission(from: viewController, completion: completion)
        case .photoLibrary:
            requestPhotoLibraryPermission(from: viewController, completion: completion)
        case .location:
            break
        }
    }

    func showPermissionAlert(
        for type: PermissionType,
        from viewController: UIViewController
    ) {
        let (title, message) = alertContent(for: type)

        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(
            title: NSLocalizedString("media_selection.go_to_settings", comment: ""),
            style: .default
        ) { [weak self] _ in
            self?.openSettings(for: type)
        })

        alert.addAction(UIAlertAction(
            title: NSLocalizedString("common.cancel", comment: ""),
            style: .cancel
        ))

        viewController.present(alert, animated: true)
    }

    private func openSettings(for type: PermissionType) {
        #if targetEnvironment(macCatalyst)
        let urlString: String
        switch type {
        case .photoLibrary:
            urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_Photos"
        case .camera:
            urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera"
        case .location:
            urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices"
        }
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
        #else
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
        #endif
    }

    private func checkCameraPermission() -> PermissionStatus {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            return .authorized
        case .denied, .restricted:
            return .denied
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .denied
        }
    }

    private func checkPhotoLibraryPermission() -> PermissionStatus {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch status {
        case .authorized:
            return .authorized
        case .limited:
            return .limited
        case .denied, .restricted:
            return .denied
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .denied
        }
    }

    private func checkLocationPermission() -> PermissionStatus {
        let manager = CLLocationManager()
        let status = manager.authorizationStatus

        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            return .authorized
        case .denied, .restricted:
            return .denied
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .denied
        }
    }

    private func requestCameraPermission(
        from viewController: UIViewController,
        completion: @escaping (PermissionStatus) -> Void
    ) {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                completion(granted ? .authorized : .denied)
            }
        }
    }

    private func requestPhotoLibraryPermission(
        from viewController: UIViewController,
        completion: @escaping (PermissionStatus) -> Void
    ) {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    completion(.authorized)
                case .limited:
                    completion(.limited)
                case .denied, .restricted:
                    completion(.denied)
                case .notDetermined:
                    completion(.notDetermined)
                @unknown default:
                    completion(.denied)
                }
            }
        }
    }

    private func alertContent(for type: PermissionType) -> (title: String, message: String) {
        switch type {
        case .camera:
            return (
                NSLocalizedString("media_selection.camera_permission_title", comment: ""),
                NSLocalizedString("media_selection.camera_permission_message", comment: "")
            )
        case .photoLibrary:
            return (
                NSLocalizedString("media_selection.photo_permission_title", comment: ""),
                NSLocalizedString("media_selection.photo_permission_message", comment: "")
            )
        case .location:
            return (
                NSLocalizedString("location_search.location_permission_title", comment: ""),
                NSLocalizedString("location_search.location_permission_message", comment: "")
            )
        }
    }
}
