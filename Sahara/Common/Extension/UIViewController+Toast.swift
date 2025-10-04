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
}
