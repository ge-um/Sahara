//
//  MainTabBarController.swift
//  Sahara
//
//  Created by 금가경 on 10/2/25.
//

import UIKit
import SnapKit

final class MainTabBarController: UITabBarController {
    private let customTabBar: UIView = {
        let view = UIView()
        return view
    }()

    private let galleryStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 4
        return stack
    }()

    private let galleryIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "gallery")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let galleryLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("tab.gallery", comment: "")
        label.font = FontSystem.TextStyle.tabBarLabel.font
        label.textColor = .black
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        tabBar.isHidden = true
        setupCustomTabBar()
        setupViewControllers()
    }

    private func setupCustomTabBar() {
        view.addSubview(customTabBar)
        customTabBar.addSubview(galleryStackView)

        galleryStackView.addArrangedSubview(galleryIconView)
        galleryStackView.addArrangedSubview(galleryLabel)

        customTabBar.applyGradient(.barBack)

        customTabBar.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(72)
        }

        galleryStackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        galleryIconView.snp.makeConstraints { make in
            make.width.height.equalTo(24)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        customTabBar.layer.sublayers?.first(where: { $0 is CAGradientLayer })?.frame = customTabBar.bounds
    }

    private func setupViewControllers() {
        let galleryVM = GalleryViewModel()
        let galleryVC = GalleryViewController(viewModel: galleryVM)
        let galleryNav = UINavigationController(rootViewController: galleryVC)

        viewControllers = [galleryNav]
    }
}
