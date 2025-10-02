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
    }

    private func configureTabBar() {
        // 탭바 그라디언트 배경
        tabBarGradientLayer.colors = ColorSystem.Gradient.barBack.colors
        tabBarGradientLayer.locations = ColorSystem.Gradient.barBack.locations
        tabBarGradientLayer.startPoint = ColorSystem.Gradient.barBack.startPoint
        tabBarGradientLayer.endPoint = ColorSystem.Gradient.barBack.endPoint
        tabBar.layer.insertSublayer(tabBarGradientLayer, at: 0)

        tabBar.tintColor = .black
        tabBar.unselectedItemTintColor = .gray
        tabBar.isTranslucent = false

        // 탭바 상단 구분선 제거
        tabBar.shadowImage = UIImage()
        tabBar.backgroundImage = UIImage()
    }

    private func setupViewControllers() {
        let galleryVM = GalleryViewModel()
        let galleryVC = GalleryViewController(viewModel: galleryVM)
        let galleryNav = UINavigationController(rootViewController: galleryVC)

        // Asset의 gallery 아이콘 사용
        let tabBarItem = UITabBarItem(
            title: NSLocalizedString("tab.gallery", comment: ""),
            image: UIImage(named: "gallery"),
            selectedImage: UIImage(named: "gallery")
        )

        // 탭바 텍스트 스타일 적용
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
