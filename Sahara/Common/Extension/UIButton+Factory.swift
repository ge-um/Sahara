//
//  UIButton+Factory.swift
//  Sahara
//

import UIKit

extension UIButton {
    static func makeSaveButton() -> UIButton {
        let button = UIButton()
        var config = UIButton.Configuration.filled()
        config.title = NSLocalizedString("common.save", comment: "")
        config.baseBackgroundColor = .clear
        config.baseForegroundColor = .white
        config.cornerStyle = .medium
        config.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)

        var titleAttr = AttributeContainer()
        titleAttr.font = UIFont.typography(.label)
        config.attributedTitle = AttributedString(config.title ?? "", attributes: titleAttr)

        button.configuration = config
        button.layer.cornerRadius = 6
        button.clipsToBounds = true
        return button
    }
}
