//
//  AppDelegate.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/6/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import UIKit
import BlueCapKit

struct BlueCapNotification {
    static let didUpdateBeacon = "DidUpdateBeacon"
}

enum AppError : Int {
    case rangingBeacons = 0
    case outOfRegion    = 1
}

struct BCAppError {
    static let domain = "BlueCapApp"
    static let rangingBeacons = NSError(domain:domain, code:AppError.rangingBeacons.rawValue, userInfo:[NSLocalizedDescriptionKey:"Ranging beacons"])
    static let outOfRegion = NSError(domain:domain, code:AppError.outOfRegion.rawValue, userInfo:[NSLocalizedDescriptionKey:"Out of region"])
}

struct Singletons {
    static let centralManager = BCCentralManager()
    static let peripheralManager = BCPeripheralManager()
    static let timedScannerator = BCTimedScannerator(centralManager:Singletons.centralManager)
    static let beaconManager = FLBeaconManager()
    static let profileManager = BCProfileManager.sharedInstance
}

struct Params {
    static let peripheralsViewRSSIPollingInterval = 5.0
    static let updateConnectionsInterval = 5.0
    static let peripheralViewRSSIPollingInterval = 1.0
    static let peripheralRSSIFutureCapacity = 10
}

@UIApplicationMain

class AppDelegate: UIResponder, UIApplicationDelegate {
                            
    var window : UIWindow?

    class func sharedApplication() -> AppDelegate {
        return UIApplication.sharedApplication().delegate as! AppDelegate
    }
    
    override init() {
        super.init()
    }
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
        TISensorTagServiceProfiles.create()
        BLESIGGATTProfiles.create()
        GnosusProfiles.create()
        NordicProfiles.create()
        application.registerUserNotificationSettings(
            UIUserNotificationSettings(forTypes:[UIUserNotificationType.Sound, UIUserNotificationType.Alert, UIUserNotificationType.Badge], categories:nil))
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        BCLogger.debug()
    }

    func applicationDidEnterBackground(application: UIApplication) {
        BCLogger.debug()
        NSUserDefaults.standardUserDefaults().synchronize()
        if Singletons.centralManager.isScanning {
            Singletons.centralManager.stopScanning()
        }
        if Singletons.centralManager.peripherals.count > 0 {
            Singletons.centralManager.disconnectAllPeripherals()
            Singletons.centralManager.removeAllPeripherals()
        }
    }

    func applicationWillEnterForeground(application: UIApplication) {
        BCLogger.debug()
    }

    func applicationDidBecomeActive(application: UIApplication) {
        BCLogger.debug()
        Notify.resetEventCount()
    }

    func applicationWillTerminate(application: UIApplication) {
        BCLogger.debug()
        NSUserDefaults.standardUserDefaults().synchronize()
    }

}

