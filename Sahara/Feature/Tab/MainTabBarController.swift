//
//  MainTabBarController.swift
//  Sahara
//
//  Created by 금가경 on 10/2/25.
//

import UIKit
import SnapKit

// MARK: - Protocols

protocol SidebarToggleable: AnyObject {
    var isSidebarMode: Bool { get }
    func toggleSidebar()
}

protocol SidebarModeObserver: AnyObject {
    func sidebarModeDidChange()
}

// MARK: - MainTabBarController

final class MainTabBarController: UIViewController, SidebarToggleable {

    // MARK: - Properties

    private var childNavigationControllers: [UINavigationController] = []
    private let tabBarContentHeight: CGFloat = 60

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

    // MARK: - Sidebar State

    private(set) var isSidebarMode = false
    private var isSidebarExpanded = true
    private var wasFloating: Bool?

    private var shouldShowSidebar: Bool {
        #if targetEnvironment(macCatalyst)
        return true
        #else
        return traitCollection.userInterfaceIdiom == .pad
            && traitCollection.horizontalSizeClass == .regular
        #endif
    }

    // MARK: - Tab Bar UI

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

    private var tabBarButtons: [TabItem: TabButton] = [:]

    // MARK: - Sidebar UI

    private lazy var sidebarView: SidebarView = {
        let sidebar = SidebarView()
        sidebar.onTabSelected = { [weak self] item in
            self?.tabSelected(item)
        }
        return sidebar
    }()

    private var sidebarWidthConstraint: Constraint?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationUI()
        setupViewControllers()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkFloatingWindowState()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { _ in
            self.checkFloatingWindowState()
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard previousTraitCollection?.horizontalSizeClass != traitCollection.horizontalSizeClass else { return }
        transitionNavigationUI()
    }

    private func checkFloatingWindowState() {
        let floating = view.isInFloatingWindow
        guard floating != wasFloating else { return }
        wasFloating = floating
        NotificationCenter.default.post(name: .floatingWindowStateDidChange, object: nil)
    }

    // MARK: - Navigation UI

    private func setupNavigationUI() {
        if shouldShowSidebar {
            installSidebar()
        } else {
            installTabBar()
        }
    }

    private func transitionNavigationUI() {
        if shouldShowSidebar && !isSidebarMode {
            removeTabBar()
            installSidebar()
            relayoutCurrentChild()
        } else if !shouldShowSidebar && isSidebarMode {
            removeSidebar()
            installTabBar()
            relayoutCurrentChild()
        }
        notifyChildrenOfModeChange()
    }

    // MARK: - Tab Bar

    private func installTabBar() {
        isSidebarMode = false

        view.addSubview(customTabBar)
        customTabBar.addSubview(tabButtonStackView)

        for item in TabItem.allCases {
            let button = TabButton(icon: item.icon, title: item.title)
            button.onTap = { [weak self] in
                self?.tabSelected(item)
            }
            button.snp.makeConstraints { make in
                make.width.height.equalTo(44)
            }
            tabButtonStackView.addArrangedSubview(button)
            tabBarButtons[item] = button
        }

        customTabBar.applyGradient(.tabBar)

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

        updateTabSelection()
        updateChildSafeAreaInsets()
    }

    private func removeTabBar() {
        tabButtonStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        tabBarButtons.removeAll()
        customTabBar.removeFromSuperview()
    }

    // MARK: - Sidebar

    private func installSidebar() {
        isSidebarMode = true
        isSidebarExpanded = true

        view.addSubview(sidebarView)
        sidebarView.alpha = 1

        sidebarView.snp.makeConstraints { make in
            make.top.bottom.leading.equalToSuperview()
            sidebarWidthConstraint = make.width.equalTo(SidebarView.width).constraint
        }

        sidebarView.setSelectedTab(TabItem(rawValue: selectedIndex) ?? .gallery)
        updateChildSafeAreaInsets()
    }

    private func removeSidebar() {
        sidebarView.removeFromSuperview()
        sidebarWidthConstraint = nil
        isSidebarMode = false
    }

    // MARK: - SidebarToggleable

    func toggleSidebar() {
        isSidebarExpanded.toggle()
        let targetWidth: CGFloat = isSidebarExpanded ? SidebarView.width : 0

        sidebarWidthConstraint?.update(offset: targetWidth)

        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut) {
            self.sidebarView.alpha = self.isSidebarExpanded ? 1 : 0
            self.view.layoutIfNeeded()
        }
    }

    // MARK: - Child VC Management

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

        embedChild(childNavigationControllers[0])
        updateTabSelection()
    }

    private func switchTab(from oldIndex: Int, to newIndex: Int) {
        let fromNav = childNavigationControllers[oldIndex]
        fromNav.willMove(toParent: nil)
        fromNav.view.removeFromSuperview()
        fromNav.removeFromParent()

        let toNav = childNavigationControllers[newIndex]
        embedChild(toNav)

        updateTabSelection()
    }

    private func embedChild(_ childNav: UINavigationController) {
        addChild(childNav)

        if isSidebarMode {
            view.insertSubview(childNav.view, belowSubview: sidebarView)
        } else {
            view.insertSubview(childNav.view, belowSubview: customTabBar)
        }

        childNav.view.translatesAutoresizingMaskIntoConstraints = false
        childNav.view.snp.makeConstraints { make in
            if isSidebarMode {
                make.leading.equalTo(sidebarView.snp.trailing)
            } else {
                make.leading.equalToSuperview()
            }
            make.top.trailing.bottom.equalToSuperview()
        }

        childNav.didMove(toParent: self)
        updateChildSafeAreaInsets()
    }

    private func relayoutCurrentChild() {
        guard selectedIndex < childNavigationControllers.count else { return }
        let currentNav = childNavigationControllers[selectedIndex]

        currentNav.view.snp.remakeConstraints { make in
            if isSidebarMode {
                make.leading.equalTo(sidebarView.snp.trailing)
            } else {
                make.leading.equalToSuperview()
            }
            make.top.trailing.bottom.equalToSuperview()
        }

        if isSidebarMode {
            view.insertSubview(currentNav.view, belowSubview: sidebarView)
        } else {
            view.insertSubview(currentNav.view, belowSubview: customTabBar)
        }

        updateChildSafeAreaInsets()
    }

    private func updateChildSafeAreaInsets() {
        let bottomInset: CGFloat = isSidebarMode ? 0 : tabBarContentHeight
        for nav in childNavigationControllers {
            nav.additionalSafeAreaInsets = UIEdgeInsets(
                top: 0, left: 0, bottom: bottomInset, right: 0
            )
        }
    }

    // MARK: - Tab Selection

    private func tabSelected(_ item: TabItem) {
        selectedIndex = item.rawValue
        AnalyticsService.shared.logTabSelected(tabName: item.analyticsName)
    }

    private func updateTabSelection() {
        let selected = TabItem(rawValue: selectedIndex) ?? .gallery

        for (item, button) in tabBarButtons {
            button.setSelected(item == selected)
        }

        if isSidebarMode {
            sidebarView.setSelectedTab(selected)
        }
    }

    // MARK: - Notify Children

    private func notifyChildrenOfModeChange() {
        for nav in childNavigationControllers {
            (nav.viewControllers.first as? SidebarModeObserver)?.sidebarModeDidChange()
        }
    }
}
