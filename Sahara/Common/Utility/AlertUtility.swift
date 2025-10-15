//
//  AlertUtility.swift
//  Sahara
//
//  Created by 금가경 on 1/11/25.
//

import UIKit

final class AlertUtility {
    static func showDeleteConfirmation(
        on viewController: UIViewController,
        onConfirm: @escaping () -> Void
    ) {
        let alert = UIAlertController(
            title: NSLocalizedString("card_detail.delete_title", comment: ""),
            message: NSLocalizedString("card_detail.delete_message", comment: ""),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(
            title: NSLocalizedString("card_detail.delete_cancel", comment: ""),
            style: .cancel
        ))
        alert.addAction(UIAlertAction(
            title: NSLocalizedString("card_detail.delete_confirm", comment: ""),
            style: .destructive
        ) { _ in
            onConfirm()
        })
        viewController.present(alert, animated: true)
    }
}
