//
//  AppDelegate.swift
//
//  Created by 董震宇 on 2020/12/1.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    private var _window: UIWindow?
    private var _gameViewController: GameViewController?
    
    // ------------------------------------------------------------------------------

    func applicationDidFinishLaunching(_ application: UIApplication) {
        _gameViewController = GameViewController()
        
        _window = UIWindow(frame: UIScreen.main.bounds)
        _window?.rootViewController = _gameViewController
        _window?.makeKeyAndVisible()
    }

    // ------------------------------------------------------------------------------

    func applicationWillResignActive(_ application: UIApplication) {}
    func applicationDidEnterBackground(_ application: UIApplication) {}
    func applicationWillEnterForeground(_ application: UIApplication) {}
    func applicationDidBecomeActive(_ application: UIApplication) {}
    func applicationWillTerminate(_ application: UIApplication) {}

    // ------------------------------------------------------------------------------

}

