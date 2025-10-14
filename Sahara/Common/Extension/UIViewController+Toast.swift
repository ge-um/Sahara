//
//  UIViewController+Toast.swift
//  Sahara
//
//  Created by 금가경 on 10/4/25.
//

import UIKit

extension UIViewController {
    func showToast(message: String, duration: TimeInterval = 2.0) {
        let toast = ToastView(message: message)
        toast.show(in: view, duration: duration)
    }

    func showBiometricPermissionAlert() {
        let alert = UIAlertController(
            title: NSLocalizedString("biometric.permission_required", comment: ""),
            message: NSLocalizedString("biometric.permission_message", comment: ""),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: NSLocalizedString("media_selection.go_to_settings", comment: ""), style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })
        alert.addAction(UIAlertAction(title: NSLocalizedString("common.cancel", comment: ""), style: .cancel) { [weak self] _ in
            self?.showToast(message: NSLocalizedString("biometric.permission_denied", comment: ""))
        })
        present(alert, animated: true)
    }
}
