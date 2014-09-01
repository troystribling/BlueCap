//
//  AppDelegate.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/6/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import UIKit
import BlueCapKit

@UIApplicationMain

class AppDelegate: UIResponder, UIApplicationDelegate {
                            
    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: NSDictionary?) -> Bool {
        TISensorTagServiceProfiles.create()
        BLESIGGATTProfiles.create()
        GnosusProfiles.create()
        NordicProfiles.create()
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
    }

    func applicationDidEnterBackground(application: UIApplication) {
        let central = CentralManager.sharedInstance()
        central.stopScanning()
        central.disconnectAllPeripherals()
    }

    func applicationWillEnterForeground(application: UIApplication) {
    }

    func applicationDidBecomeActive(application: UIApplication) {
    }

    func applicationWillTerminate(application: UIApplication) {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.synchronize()
    }


}

