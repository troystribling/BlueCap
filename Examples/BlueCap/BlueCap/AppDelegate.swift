//
//  AppDelegate.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/6/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import UIKit
import UserNotifications
import CoreBluetooth
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
    static private(set) var centralManager = CentralManager(profileManager: Singletons.profileManager, options: [CBCentralManagerOptionRestoreIdentifierKey : "us.gnos.BlueCap.CentralManager" as NSString])
    static private(set) var peripheralManager = PeripheralManager(options: [CBPeripheralManagerOptionRestoreIdentifierKey : "us.gnos.BlueCap.PeripheralManager" as NSString])
    static let beaconManager = BeaconManager()
    static let profileManager = ProfileManager()
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
        TISensorTagServiceProfiles.create(profileManager: Singletons.profileManager)
        BLESIGGATTProfiles.create(profileManager: Singletons.profileManager)
        GnosusProfiles.create(profileManager: Singletons.profileManager)
        NordicProfiles.create(profileManager: Singletons.profileManager)
        let defaultConfig = Bundle.main.url(forResource: "DefaultConfiguration", withExtension: "plist").flatMap { NSDictionary(contentsOf: $0) }.flatMap { $0 as? [String: AnyObject] }
        if let defaultConfig = defaultConfig {
            UserDefaults.standard.register(defaults: defaultConfig)
        }
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in
            guard error != nil else {
                Notification.setPermissionGranted(false)
                return
            }
            Notification.setPermissionGranted(granted)
        }
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
        Notification.resetEventCount()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        Logger.debug()
        UserDefaults.standard.synchronize()
    }

}

