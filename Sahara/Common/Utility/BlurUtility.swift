//
//  BlurUtility.swift
//  Sahara
//
//  Created by 금가경 on 10/6/25.
//

import UIKit

enum BlurUtility {
    static func createBlurView(cornerRadius: CGFloat = 0) -> UIVisualEffectView {
        let blurEffect = UIBlurEffect(style: .extraLight)
        let effectView = UIVisualEffectView(effect: blurEffect)
        effectView.clipsToBounds = true
        effectView.layer.cornerRadius = cornerRadius
        effectView.isHidden = true
        return effectView
    }
}
