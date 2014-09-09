//
//  RegionScannerator.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/25/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation
import CoreLocation
import CoreBluetooth

public class RegionScannerator {
 
    internal class RegionScanneratorMonitor : RegionMonitor {
        
        internal var regionMonitor : RegionMonitor
        
        internal override var region : CLRegion {
            return self.regionMonitor.region
        }
        
        internal init(regionMonitor:RegionMonitor, initializer:(regionMonitor:RegionScanneratorMonitor) -> ()) {
            self.regionMonitor = regionMonitor
            super.init(region:regionMonitor.region)
            initializer(regionMonitor:self)
        }

    }
    
    private let regionManager                   : RegionManager
    private var services                        : [CBUUID]?
    private var afterPeripheralDiscovered       : ((peripheral:Peripheral, rssi:Int)->())?

    private var _isScanning = false
    
    public var distanceFilter : CLLocationDistance {
        get {
            return self.regionManager.distanceFilter
        }
        set {
            self.regionManager.distanceFilter = newValue
        }
    }
    
    public var desiredAccuracy : CLLocationAccuracy {
        get {
            return self.regionManager.desiredAccuracy
        }
        set {
            self.regionManager.desiredAccuracy = newValue
        }
    }

    public var regions : [CLRegion] {
        return self.regionManager.regions
    }
    
    public var regionMonitors : [RegionMonitor] {
        return self.regionManager.regionMonitors
    }

    public var isScanning : Bool {
        return self._isScanning
    }
    
    public class func sharedInstance() -> RegionScannerator {
        if thisRegionScannerator == nil {
            thisRegionScannerator = RegionScannerator()
        }
        return thisRegionScannerator!
    }
    
    public init() {
        self.regionManager = RegionManager.sharedInstance()
        self.desiredAccuracy = kCLLocationAccuracyBest
    }

    public func startScanning(afterPeripheralDiscovered:(peripheral:Peripheral, rssi:Int)->()) {
        Logger.debug("RegionScannerator#startScanning")
        self.afterPeripheralDiscovered = afterPeripheralDiscovered
        self._isScanning = true
        self.regionManager.startUpdatingLocation()
    }
    
    public func startScanningForServiceUUIDds(uuids:[CBUUID], afterPeripheralDiscovered:(peripheral:Peripheral, rssi:Int)->()) {
        Logger.debug("RegionScannerator#startScanningForServiceUUIDs: \(uuids)")
        self.afterPeripheralDiscovered = afterPeripheralDiscovered
        self._isScanning = true
        self.services = uuids
        self.regionManager.startUpdatingLocation()
    }
    
    public func stopScanning() {
        Logger.debug("RegionScannerator#stopScanning")
        CentralManager.sharedInstance().stopScanning()
        self._isScanning = false
        self.regionManager.stopUpdatingLocation()
    }
    
    public func startMonitoringForRegion(regionMonitor:RegionMonitor) {
        Logger.debug("RegionScannerator#startMonitoringForRegion")
        let scanneratorMonitor = RegionScanneratorMonitor(regionMonitor:regionMonitor) {(regionMonitor) in
            regionMonitor.exitRegion = {
                if let exitRegion = regionMonitor.regionMonitor.exitRegion {
                    exitRegion()
                } else {
                    CentralManager.sharedInstance().stopScanning()
                }
            }
            regionMonitor.enterRegion = {
                if let enterRegion = regionMonitor.regionMonitor.enterRegion {
                    enterRegion()
                } else {
                    if let afterPeripheralDiscovered = self.afterPeripheralDiscovered {
                        if let services = self.services {
                            CentralManager.sharedInstance().startScanningForServiceUUIDds(services, afterPeripheralDiscovered:afterPeripheralDiscovered)
                        } else {
                            CentralManager.sharedInstance().startScanning(afterPeripheralDiscovered)
                        }
                    }
                }
            }
            regionMonitor.startMonitoringRegion = {
                if let startMonitoringRegion = regionMonitor.regionMonitor.startMonitoringRegion {
                    startMonitoringRegion()
                }
            }
            regionMonitor.regionStateChanged = {(state) in
                if let regionStateChanged = regionMonitor.regionMonitor.regionStateChanged {
                    regionStateChanged(state:state)
                }
            }
            regionMonitor.errorMonitoringRegion = {(error) in
                if let errorMonitoringRegion = regionMonitor.regionMonitor.errorMonitoringRegion {
                    errorMonitoringRegion(error:error)
                }
            }
        }
        self.regionManager.startMonitoringForRegion(regionMonitor)
    }
    
    public func stopMonitoringForRegion(regionMonitor:RegionMonitor) {
        Logger.debug("RegionScannerator#stopMonitoringForRegion")
        self.regionManager.stopMonitoringForRegion(regionMonitor)
    }

}

var thisRegionScannerator : RegionScannerator?