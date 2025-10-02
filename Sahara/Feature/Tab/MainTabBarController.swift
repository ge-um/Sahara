//
//  MainTabBarController.swift
//  Sahara
//
//  Created by 금가경 on 10/2/25.
//

import UIKit

final class MainTabBarController: UITabBarController {
    private let tabBarGradientLayer = CAGradientLayer()

    override func viewDidLoad() {
        super.viewDidLoad()
        configureTabBar()
        setupViewControllers()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tabBarGradientLayer.frame = tabBar.bounds

        var tabBarFrame = tabBar.frame
        tabBarFrame.size.height = 70
        tabBarFrame.origin.y = view.frame.size.height - 70
        tabBar.frame = tabBarFrame
    }

    private func configureTabBar() {
        tabBarGradientLayer.colors = ColorSystem.Gradient.barBack.colors
        tabBarGradientLayer.locations = ColorSystem.Gradient.barBack.locations
        tabBarGradientLayer.startPoint = ColorSystem.Gradient.barBack.startPoint
        tabBarGradientLayer.endPoint = ColorSystem.Gradient.barBack.endPoint
        tabBar.layer.insertSublayer(tabBarGradientLayer, at: 0)

        tabBar.tintColor = .black
        tabBar.unselectedItemTintColor = .gray
        tabBar.isTranslucent = false

        tabBar.shadowImage = UIImage()
        tabBar.backgroundImage = UIImage()
    }

    private func setupViewControllers() {
        let galleryVM = GalleryViewModel()
        let galleryVC = GalleryViewController(viewModel: galleryVM)
        let galleryNav = UINavigationController(rootViewController: galleryVC)

        let tabBarItem = UITabBarItem(
            title: NSLocalizedString("tab.gallery", comment: ""),
            image: UIImage(named: "gallery"),
            selectedImage: UIImage(named: "gallery")
        )

        tabBarItem.imageInsets = UIEdgeInsets(top: 6, left: 0, bottom: -6, right: 0)
        tabBarItem.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: 3)

        let normalAttributes: [NSAttributedString.Key: Any] = [
            .font: FontSystem.TextStyle.tabBarLabel.font,
            .kern: FontSystem.TextStyle.tabBarLabel.letterSpacing
        ]
        let selectedAttributes: [NSAttributedString.Key: Any] = [
            .font: FontSystem.TextStyle.tabBarLabel.font,
            .kern: FontSystem.TextStyle.tabBarLabel.letterSpacing
        ]
        tabBarItem.setTitleTextAttributes(normalAttributes, for: .normal)
        tabBarItem.setTitleTextAttributes(selectedAttributes, for: .selected)

        galleryNav.tabBarItem = tabBarItem

        viewControllers = [galleryNav]
    }
}
