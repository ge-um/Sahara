//
//  SettingsSectionBackgroundView.swift
//  Sahara
//
//  Created by 금가경 on 3/27/26.
//

import UIKit

final class SettingsSectionBackgroundView: UICollectionReusableView {
    static let elementKind = "SettingsSectionBackground"

    override init(frame: CGRect) {
        super.init(frame: frame)
        applyGlassCardStyle()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
        layer.zPosition = -1
    }
}
