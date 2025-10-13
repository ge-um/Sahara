//
//  CardBackgroundView.swift
//  Sahara
//
//  Created by 금가경 on 10/12/25.
//

import UIKit

final class CardBackgroundView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = ColorSystem.lavender20
        layer.cornerRadius = 12
    }
}
