//
//  MainTabBarController.swift
//  Main
//
//  Created by 김동준 on 6/30/26
//

import UIKit
import DesignSystem

public final class MainTabBarController: UITabBarController {
    /// 사용자가 탭바에서 직접 탭을 선택했을 때 호출
    var onSelectTab: ((Int) -> Void)?

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        delegate = self
        configureTabBarAppearance()
    }

    deinit {
        print("❎ MainTabBarController deinit!")
    }
}

public extension MainTabBarController {
    func setTabs(
        tabs: [MainTab],
        viewControllers: [UIViewController],
        animated: Bool
    ) {
        zip(tabs, viewControllers).forEach { tab, viewController in
            viewController.tabBarItem = makeTabBarItem(tab: tab)
        }
        setViewControllers(viewControllers, animated: animated)
    }

    func selectTab(_ index: Int) {
        selectedIndex = index
    }
}

extension MainTabBarController: UITabBarControllerDelegate {
    public func tabBarController(
        _ tabBarController: UITabBarController,
        didSelect viewController: UIViewController
    ) {
        guard let index = viewControllers?.firstIndex(of: viewController) else { return }
        onSelectTab?(index)
    }
}

private extension MainTabBarController {
    func makeTabBarItem(tab: MainTab) -> UITabBarItem {
        UITabBarItem(
            title: tab.title,
            // 비선택: 기존 아이콘을 시스템 tint 색으로 표시
            image: tab.image?.withRenderingMode(.alwaysTemplate),
            // 선택: 피그마 fill 아이콘을 원본 색 그대로 표시
            selectedImage: tab.selectedImage?.withRenderingMode(.alwaysOriginal)
        )
    }

    func configureTabBarAppearance() {
        tabBar.tintColor = .gray10
        tabBar.unselectedItemTintColor = .gray5

        // iOS 26+ 는 시스템 Liquid Glass 탭바를 그대로 사용한다.
        if #available(iOS 26.0, *) { return }

        // iOS 25 이하: 기존 디자인(흰 배경 + 상단 구분선) 유지
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        appearance.shadowColor = .gray2

        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
    }
}
