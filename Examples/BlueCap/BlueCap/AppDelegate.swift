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

enum AppError : Error, LocalizedError {
    case rangingBeacons
    case outOfRegion
    case unknownRegionStatus
    case serviceNotFound
    case characteristicNotFound
    case unlikelyFailure
    case resetting
    case poweredOff
    case unsupported
    case unknown
    case unauthorized

    public var errorDescription: String? {
        switch self {
        case .rangingBeacons:
            return NSLocalizedString("Beacon ranging enabled.", comment: "AppError.rangingBeacons")
        case .outOfRegion:
            return NSLocalizedString("Outside becan region.", comment: "AppError.outOfRegion")
        case .unknownRegionStatus:
            return NSLocalizedString("Unknown region state.", comment: "AppError.unknownRegionStatus")
        case .serviceNotFound:
            return NSLocalizedString("Expected service not found.", comment: "AppError.serviceNotFound")
        case .characteristicNotFound:
            return NSLocalizedString("Expected characteristic not found..", comment: "AppError.characteristicNotFound")
        case .unlikelyFailure:
            return NSLocalizedString("Unlikely failure.", comment: "AppError.unlikelyFailure")
        case .resetting:
            return NSLocalizedString("CoreBluetooth resetting.", comment: "AppError.resetting")
        case .poweredOff:
            return NSLocalizedString("Bluetooth powered off.", comment: "AppError.poweredOff")
        case .unsupported:
            return NSLocalizedString("Bluetooth not supported.", comment: "AppError.unsupported")
        case .unknown:
            return NSLocalizedString("Bluetooth state unkown.", comment: "AppError.unkown")
        case .unauthorized:
            return NSLocalizedString("Bluetooth state unauthorized.", comment: "AppError.unauthorized")
        }
    }

}

struct Singletons {
    static let peripheralManager = PeripheralManager(options: [CBPeripheralManagerOptionRestoreIdentifierKey : "us.gnos.BlueCap.peripheral-manager" as NSString])
    static let discoveryManager = CentralManager(profileManager: Singletons.profileManager, options: [CBCentralManagerOptionRestoreIdentifierKey : "us.gnos.BlueCap.discovery-manager" as NSString])
    static let scanningManager = CentralManager(queue: DispatchQueue(label: "us.gnos.blueCap.scanning-manager.main", qos: .background),
                                                profileManager: Singletons.profileManager,
                                                options: [CBCentralManagerOptionRestoreIdentifierKey : "us.gnos.BlueCap.scanning-manager" as NSString])
    static let beaconManager = BeaconManager()
    static let profileManager = ProfileManager()
}

struct Params {
    static let peripheralsViewRSSIPollingInterval = 5.0
    static let updateConnectionsInterval = 2.0
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
        TISensorTagProfiles.create(profileManager: Singletons.profileManager)
        BLESIGGATTProfiles.create(profileManager: Singletons.profileManager)
        GnosusProfiles.create(profileManager: Singletons.profileManager)
        NordicProfiles.create(profileManager: Singletons.profileManager)
        let defaultConfig = Bundle.main.url(forResource: "DefaultConfiguration", withExtension: "plist").flatMap { NSDictionary(contentsOf: $0) }.flatMap { $0 as? [String: AnyObject] }
        if let defaultConfig = defaultConfig {
            UserDefaults.standard.register(defaults: defaultConfig)
        }
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        Logger.debug()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        Logger.debug()
        UserDefaults.standard.synchronize()
        if Singletons.scanningManager.isScanning {
            Singletons.scanningManager.stopScanning()
        }
        if Singletons.scanningManager.peripherals.count > 0 {
            Singletons.scanningManager.disconnectAllPeripherals()
            Singletons.scanningManager.removeAllPeripherals()
        }
        if Singletons.discoveryManager.peripherals.count > 0 {
            Singletons.discoveryManager.disconnectAllPeripherals()
            Singletons.discoveryManager.removeAllPeripherals()
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

