//
//  BlurUtility.swift
//  Sahara
//
//  Created by 금가경 on 10/6/25.
//

import UIKit

enum BlurUtility {
    static func createBlurView(cornerRadius: CGFloat = 0) -> UIVisualEffectView {
        let blurEffect = UIBlurEffect(style: .regular)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.clipsToBounds = true
        blurView.layer.cornerRadius = cornerRadius
        blurView.isHidden = true
        return blurView
    }
}
