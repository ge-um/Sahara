//
//  MainTabBarController.swift
//  Sahara
//
//  Created by 금가경 on 10/2/25.
//

import UIKit
import SnapKit

final class MainTabBarController: UIViewController {
    private var childNavigationControllers: [UINavigationController] = []

    var selectedIndex: Int = 0 {
        didSet {
            guard oldValue != selectedIndex,
                  !childNavigationControllers.isEmpty else { return }
            switchTab(from: oldValue, to: selectedIndex)
        }
    }

    var selectedViewController: UIViewController? {
        guard selectedIndex < childNavigationControllers.count else { return nil }
        return childNavigationControllers[selectedIndex]
    }

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

    private lazy var settingsTabButton: TabButton = {
        let button = TabButton(
            icon: UIImage(systemName: "gearshape.fill"),
            title: NSLocalizedString("tab.settings", comment: "")
        )
        button.onTap = { [weak self] in
            self?.settingsTabTapped()
        }
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCustomTabBar()
        setupViewControllers()
    }

    private func setupCustomTabBar() {
        view.addSubview(customTabBar)
        customTabBar.addSubview(tabButtonStackView)

        tabButtonStackView.addArrangedSubview(galleryTabButton)
        tabButtonStackView.addArrangedSubview(searchTabButton)
        tabButtonStackView.addArrangedSubview(statsTabButton)
        tabButtonStackView.addArrangedSubview(settingsTabButton)

        customTabBar.applyGradient(.tabBar)

        galleryTabButton.snp.makeConstraints { make in
            make.width.height.equalTo(44)
        }

        searchTabButton.snp.makeConstraints { make in
            make.width.height.equalTo(44)
        }

        statsTabButton.snp.makeConstraints { make in
            make.width.height.equalTo(44)
        }

        settingsTabButton.snp.makeConstraints { make in
            make.width.height.equalTo(44)
        }

        tabButtonStackView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.width.lessThanOrEqualTo(400)
            make.horizontalEdges.equalToSuperview().inset(48).priority(.medium)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-8)
        }

        customTabBar.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
            make.top.equalTo(tabButtonStackView.snp.top).offset(-8)
        }
    }

    private func setupViewControllers() {
        let galleryVM = GalleryViewModel()
        let galleryVC = GalleryViewController(viewModel: galleryVM)
        let galleryNav = UINavigationController(rootViewController: galleryVC)

        let searchVC = SearchViewController()
        let searchNav = UINavigationController(rootViewController: searchVC)

        let statsVC = StatsViewController()
        let statsNav = UINavigationController(rootViewController: statsVC)

        let settingsVM = SettingsViewModel()
        let settingsVC = SettingsViewController(viewModel: settingsVM)
        let settingsNav = UINavigationController(rootViewController: settingsVC)

        childNavigationControllers = [galleryNav, searchNav, statsNav, settingsNav]

        let firstNav = childNavigationControllers[0]
        addChild(firstNav)
        view.insertSubview(firstNav.view, belowSubview: customTabBar)
        firstNav.view.frame = view.bounds
        firstNav.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        firstNav.didMove(toParent: self)

        updateTabSelection()
    }

    private func switchTab(from oldIndex: Int, to newIndex: Int) {
        let fromNav = childNavigationControllers[oldIndex]
        fromNav.willMove(toParent: nil)
        fromNav.view.removeFromSuperview()
        fromNav.removeFromParent()

        let toNav = childNavigationControllers[newIndex]
        addChild(toNav)
        view.insertSubview(toNav.view, belowSubview: customTabBar)
        toNav.view.frame = view.bounds
        toNav.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        toNav.didMove(toParent: self)

        updateTabSelection()
    }

    @objc private func galleryTabTapped() {
        selectedIndex = 0
        AnalyticsService.shared.logTabSelected(tabName: "gallery")
    }

    @objc private func searchTabTapped() {
        selectedIndex = 1
        AnalyticsService.shared.logTabSelected(tabName: "search")
    }

    @objc private func statsTabTapped() {
        selectedIndex = 2
        AnalyticsService.shared.logTabSelected(tabName: "stats")
    }

    @objc private func settingsTabTapped() {
        selectedIndex = 3
        AnalyticsService.shared.logTabSelected(tabName: "settings")
    }

    private func updateTabSelection() {
        galleryTabButton.setSelected(selectedIndex == 0)
        searchTabButton.setSelected(selectedIndex == 1)
        statsTabButton.setSelected(selectedIndex == 2)
        settingsTabButton.setSelected(selectedIndex == 3)
    }
}
