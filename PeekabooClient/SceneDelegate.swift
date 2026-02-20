//
//  SceneDelegate.swift
//  PeekabooClient
//
//  Created by Максим on 27.01.2026.
//

import UIKit
import SwiftUI

@main
class SceneDelegate: UIResponder, UIApplicationDelegate, UIWindowSceneDelegate {

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        let viewModel = DependencyContainer.shared.makeVPNViewModel()

        let homeVC = UIHostingController(rootView: VPNMainView(viewModel: viewModel))
        homeVC.tabBarItem = UITabBarItem(title: "Главная", image: UIImage(systemName: "house"), tag: 0)

        let settingsVC = SettingsViewController()
        settingsVC.tabBarItem = UITabBarItem(title: "Настройки", image: UIImage(systemName: "gear"), tag: 1)

        let tabBar = UITabBarController()
        tabBar.viewControllers = [
            homeVC,
            UINavigationController(rootViewController: settingsVC)
        ]

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = tabBar
        window.overrideUserInterfaceStyle = .dark
        window.makeKeyAndVisible()
        self.window = window
    }

    func sceneDidDisconnect(_ scene: UIScene) {}
    func sceneDidBecomeActive(_ scene: UIScene) {}
    func sceneWillResignActive(_ scene: UIScene) {}
    func sceneWillEnterForeground(_ scene: UIScene) {}
    func sceneDidEnterBackground(_ scene: UIScene) {}
}

