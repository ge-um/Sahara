//
//  TabItem.swift
//  Sahara
//
//  Created by 금가경 on 3/16/26.
//

import UIKit

enum TabItem: Int, CaseIterable {
    case gallery = 0
    case search = 1
    case stats = 2
    case settings = 3

    var icon: UIImage? {
        switch self {
        case .gallery: return UIImage(named: "gallery")
        case .search: return UIImage(named: "search")
        case .stats: return UIImage(named: "chart")
        case .settings: return UIImage(named: "gear")
        }
    }

    var title: String {
        switch self {
        case .gallery: return NSLocalizedString("tab.gallery", comment: "")
        case .search: return NSLocalizedString("tab.search", comment: "")
        case .stats: return NSLocalizedString("tab.stats", comment: "")
        case .settings: return NSLocalizedString("tab.settings", comment: "")
        }
    }
}
