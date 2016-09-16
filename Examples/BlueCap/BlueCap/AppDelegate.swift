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
    static let centralManager = CentralManager()
    static let peripheralManager = PeripheralManager()
    static let beaconManager = FLBeaconManager()
    static let profileManager = ProfileManager.sharedInstance
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
        return UIApplication.shared.delegate as! AppDelegate
    }
    
    override init() {
        super.init()
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        TISensorTagServiceProfiles.create()
        BLESIGGATTProfiles.create()
        GnosusProfiles.create()
        NordicProfiles.create()
        let defaultConfig = Bundle.main.url(forResource: "DefaultConfiguration", withExtension: "plist").flatMap { NSDictionary(contentsOf: $0) }.flatMap { $0 as? [String: AnyObject] }
        if let defaultConfig = defaultConfig {
            UserDefaults.standard.register(defaults: defaultConfig)
        }
        application.registerUserNotificationSettings(
            UIUserNotificationSettings(types:[UIUserNotificationType.sound, UIUserNotificationType.alert, UIUserNotificationType.badge], categories:nil))
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        Logger.debug()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        Logger.debug()
        UserDefaults.standard.synchronize()
        if Singletons.centralManager.isScanning {
            Singletons.centralManager.stopScanning()
        }
        if Singletons.centralManager.peripherals.count > 0 {
            Singletons.centralManager.disconnectAllPeripherals()
            Singletons.centralManager.removeAllPeripherals()
        }
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        Logger.debug()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        Logger.debug()
        Notify.resetEventCount()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        Logger.debug()
        UserDefaults.standard.synchronize()
    }

}

