//
//  UIView+FloatingWindow.swift
//  Sahara
//
//  Created by 금가경 on 3/17/26.
//

import UIKit

extension UIView {
    var isInFloatingWindow: Bool {
        guard let window = window,
              let screen = window.windowScene?.screen else { return false }
        return window.frame.width < screen.bounds.width - 1
            || window.frame.height < screen.bounds.height - 1
    }
}

extension Notification.Name {
    static let floatingWindowStateDidChange = Notification.Name("floatingWindowStateDidChange")
}
