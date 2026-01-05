//
//  SceneDelegate.swift
//  iOSSDKExample
//

import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use a UIHostingController as window root view controller.
        if let windowScene = scene as? UIWindowScene {
            // Create window with proper screen bounds
            let window = UIWindow(windowScene: windowScene)
            window.backgroundColor = .white
            window.clipsToBounds = true
            
            // Create hosting controller
            let hostingController = UIHostingController(rootView: ContentView())
            
            // Configure hosting controller for full-screen behavior
            hostingController.view.backgroundColor = .white
            hostingController.view.frame = windowScene.screen.bounds
            hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            hostingController.view.clipsToBounds = true
            hostingController.edgesForExtendedLayout = .all
            hostingController.extendedLayoutIncludesOpaqueBars = true
            hostingController.additionalSafeAreaInsets = .zero
            hostingController.modalPresentationStyle = .fullScreen
            
            // Set window properties
            window.frame = windowScene.screen.bounds
            window.rootViewController = hostingController
            window.makeKeyAndVisible()
            window.autoresizesSubviews = true
            self.window = window
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }

}
