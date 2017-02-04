//
//  AppDelegate.swift
//  Beacons
//
//  Created by Troy Stribling on 4/5/15.
//  Copyright (c) 2015 Troy Stribling. The MIT License (MIT).
//

import UIKit

enum AppError : Swift.Error {
    case rangingBeacon
    case started
    case outside
    case unknownState
}

struct AppNotification {
    static let didUpdateBeacon = "DidUpdateBeacon"
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    fileprivate func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [AnyHashable: Any]?) -> Bool {
        application.registerUserNotificationSettings(
            UIUserNotificationSettings(types:[UIUserNotificationType.alert, UIUserNotificationType.sound, UIUserNotificationType.badge], categories:nil))
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        Notify.resetEventCount()
    }

    func applicationWillTerminate(_ application: UIApplication) {
    }


}

