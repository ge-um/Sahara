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

    private lazy var tabButtonStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .equalSpacing
        stack.alignment = .center
        return stack
    }()

    private lazy var galleryTabButton: TabButton = {
        let button = TabButton(
            icon: UIImage(named: "gallery"),
            title: NSLocalizedString("tab.gallery", comment: "")
        )
        button.onTap = { [weak self] in
            self?.galleryTabTapped()
        }
        return button
    }()

    private lazy var searchTabButton: TabButton = {
        let button = TabButton(
            icon: UIImage(systemName: "magnifyingglass"),
            title: NSLocalizedString("tab.search", comment: "")
        )
        button.onTap = { [weak self] in
            self?.searchTabTapped()
        }
        return button
    }()

    private lazy var statsTabButton: TabButton = {
        let button = TabButton(
            icon: UIImage(systemName: "chart.bar.fill"),
            title: NSLocalizedString("tab.stats", comment: "")
        )
        button.onTap = { [weak self] in
            self?.statsTabTapped()
        }
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        tabBar.isHidden = true
        setupCustomTabBar()
        setupViewControllers()
    }

    private func setupCustomTabBar() {
        view.addSubview(customTabBar)
        customTabBar.addSubview(tabButtonStackView)

        tabButtonStackView.addArrangedSubview(galleryTabButton)
        tabButtonStackView.addArrangedSubview(searchTabButton)
        tabButtonStackView.addArrangedSubview(statsTabButton)

        customTabBar.applyGradient(.barBack)

        galleryTabButton.snp.makeConstraints { make in
            make.width.height.equalTo(44)
        }

        searchTabButton.snp.makeConstraints { make in
            make.width.height.equalTo(44)
        }

        statsTabButton.snp.makeConstraints { make in
            make.width.height.equalTo(44)
        }

        tabButtonStackView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(60)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-8)
        }

        customTabBar.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
            make.top.equalTo(tabButtonStackView.snp.top).offset(-8)
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

        let searchVC = SearchViewController()
        let searchNav = UINavigationController(rootViewController: searchVC)

        let statsVC = StatsViewController()
        let statsNav = UINavigationController(rootViewController: statsVC)

        viewControllers = [galleryNav, searchNav, statsNav]

        updateTabSelection()
    }

    @objc private func galleryTabTapped() {
        selectedIndex = 0
        updateTabSelection()
    }

    @objc private func searchTabTapped() {
        selectedIndex = 1
        updateTabSelection()
    }

    @objc private func statsTabTapped() {
        selectedIndex = 2
        updateTabSelection()
    }

    private func updateTabSelection() {
        galleryTabButton.setSelected(selectedIndex == 0)
        searchTabButton.setSelected(selectedIndex == 1)
        statsTabButton.setSelected(selectedIndex == 2)
    }
}
