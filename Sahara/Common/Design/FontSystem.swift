//
//  FontSystem.swift
//  Sahara
//
//  Created by 금가경 on 10/2/25.
//

import UIKit

enum FontSystem {
    static func galmuriMono(size: CGFloat) -> UIFont {
        return UIFont(name: "GalmuriMono11", size: size) ?? .systemFont(ofSize: size)
    }
}
