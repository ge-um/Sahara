//
//  MainTabBarController.swift
//  Sahara
//
//  Created by 금가경 on 10/2/25.
//

import UIKit

final class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        configureTabBar()
        setupViewControllers()
    }

    private func configureTabBar() {
        tabBar.backgroundColor = .systemBackground
        tabBar.tintColor = .label
        tabBar.unselectedItemTintColor = .secondaryLabel
    }

    private func setupViewControllers() {
        let galleryVM = GalleryViewModel()
        let galleryVC = GalleryViewController(viewModel: galleryVM)
        let galleryNav = UINavigationController(rootViewController: galleryVC)
        galleryNav.tabBarItem = UITabBarItem(
            title: NSLocalizedString("tab.gallery", comment: ""),
            image: UIImage(systemName: "photo.on.rectangle"),
            selectedImage: UIImage(systemName: "photo.on.rectangle.fill")
        )

        viewControllers = [galleryNav]
    }
}
