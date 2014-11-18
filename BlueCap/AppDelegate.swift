//
//  AppDelegate.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/6/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import UIKit
import BlueCapKit

struct BlueCapNotification {
    static let peripheralDisconnected   = "PeripheralDisconnected"
    static let didUpdateBeacon          = "DidUpdateBeacon"
    static let didBecomeActive          = "DidBecomeActive"
    static let didResignActive          = "DidResignActive"
}


@UIApplicationMain

class AppDelegate: UIResponder, UIApplicationDelegate {
                            
    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: NSDictionary?) -> Bool {
        TISensorTagServiceProfiles.create()
        BLESIGGATTProfiles.create()
        GnosusProfiles.create()
        NordicProfiles.create()
        application.registerUserNotificationSettings(
            UIUserNotificationSettings(forTypes:UIUserNotificationType.Sound|UIUserNotificationType.Alert|UIUserNotificationType.Badge,
                categories:nil))
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
    }

    func applicationDidEnterBackground(application: UIApplication) {
        NSUserDefaults.standardUserDefaults().synchronize()
        NSNotificationCenter.defaultCenter().postNotificationName(BlueCapNotification.didResignActive, object:nil)
        let central = CentralManager.sharedInstance()
        if central.isScanning {
            central.stopScanning()
            central.disconnectAllPeripherals()
            central.removeAllPeripherals()
        }
    }

    func applicationWillEnterForeground(application: UIApplication) {
    }

    func applicationDidBecomeActive(application: UIApplication) {
        Notify.resetEventCount()
        NSNotificationCenter.defaultCenter().postNotificationName(BlueCapNotification.didBecomeActive, object:nil)
    }

    func applicationWillTerminate(application: UIApplication) {
         NSUserDefaults.standardUserDefaults().synchronize()
    }


}

