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

public class RegionScannerator : TimedScannerator {
 
    internal class ScanneratorRegion : Region {
        
        internal var scanRegion : Region
        
        internal override var region : CLRegion {
            return self.scanRegion.region
        }
        
        internal init(scanRegion:Region, initializer:(scanneratorRegion:ScanneratorRegion) -> ()) {
            self.scanRegion = scanRegion
            super.init(region:scanRegion.region)
            initializer(scanneratorRegion:self)
        }

    }
    
    private let regionManager                   : RegionManager!
    private var services                        : [CBUUID]?
    private var afterPeripheralDiscovered       : ((peripheral:Peripheral, rssi:Int)->())?
    
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

    public var regions : [Region] {
        return self.regionManager.regions
    }

    override public class func sharedInstance() -> RegionScannerator {
        if thisRegionScannerator == nil {
            thisRegionScannerator = RegionScannerator()
        }
        return thisRegionScannerator!
    }
    
    override public init() {
        super.init()
        self.regionManager = RegionManager.sharedInstance()
        self.desiredAccuracy = kCLLocationAccuracyBest
    }

    public func startScanning(afterPeripheralDiscovered:(peripheral:Peripheral, rssi:Int)->()) {
        Logger.debug("RegionScannerator#startScanning")
        self.afterPeripheralDiscovered = afterPeripheralDiscovered
        self._isScanning = true
        self.services = nil
        self.afterTimeout = nil
        self.regionManager.startUpdatingLocation()
    }
    
    public func startScanningForServiceUUIDs(uuids:[CBUUID], afterPeripheralDiscovered:(peripheral:Peripheral, rssi:Int)->()) {
        Logger.debug("RegionScannerator#startScanningForServiceUUIDs: \(uuids)")
        self.afterPeripheralDiscovered = afterPeripheralDiscovered
        self._isScanning = true
        self.services = uuids
        self.afterTimeout = nil
        self.regionManager.startUpdatingLocation()
    }
    
    override public func startScanning(timeoutSeconds:Float, afterPeripheralDiscovered:(peripheral:Peripheral, rssi:Int)->(), afterTimeout:(()->())? = nil) {
        self.timeoutSeconds = timeoutSeconds
        self.services = nil
        self._isScanning = true
        self.afterTimeout = afterTimeout
        self.timeoutScan()
    }
    
    override public func startScanningForServiceUUIDs(timeoutSeconds:Float, uuids:[CBUUID]!, afterPeripheralDiscoveredCallback:(peripheral:Peripheral, rssi:Int)->(), afterTimeout:(()->())? = nil) {
        self._isScanning = true
        self.services = uuids
        self.afterTimeout = afterTimeout
        self.timeoutSeconds = timeoutSeconds
        self.timeoutScan()
    }

    override public func stopScanning() {
        Logger.debug("RegionScannerator#stopScanning")
        self._isScanning = false
        self.afterTimeout = nil
        self.services = nil
        CentralManager.sharedInstance().stopScanning()
        self.regionManager.stopUpdatingLocation()
    }
    
    public func startMonitoringForRegion(region:Region) {
        Logger.debug("RegionScannerator#startMonitoringForRegion")
        let region = ScanneratorRegion(scanRegion:region) {(scanneratorRegion) in
            scanneratorRegion.exitRegion = {
                if let exitRegion = scanneratorRegion.scanRegion.exitRegion {
                    exitRegion()
                }
                CentralManager.sharedInstance().stopScanning()
            }
            scanneratorRegion.enterRegion = {
                if let enterRegion = scanneratorRegion.scanRegion.enterRegion {
                    enterRegion()
                }
                if let afterPeripheralDiscovered = self.afterPeripheralDiscovered {
                    if let services = self.services {
                        CentralManager.sharedInstance().startScanningForServiceUUIDs(services, afterPeripheralDiscovered:afterPeripheralDiscovered)
                    } else {
                        CentralManager.sharedInstance().startScanning(afterPeripheralDiscovered)
                    }
                }
            }
            scanneratorRegion.startMonitoringRegion = {
                if let startMonitoringRegion = scanneratorRegion.scanRegion.startMonitoringRegion {
                    startMonitoringRegion()
                }
            }
            scanneratorRegion.regionStateChanged = {(state) in
                if let regionStateChanged = scanneratorRegion.scanRegion.regionStateChanged {
                    regionStateChanged(state:state)
                }
            }
            scanneratorRegion.errorMonitoringRegion = {(error) in
                if let errorMonitoringRegion = scanneratorRegion.scanRegion.errorMonitoringRegion {
                    errorMonitoringRegion(error:error)
                }
            }
        }
        self.regionManager.startMonitoringForRegion(region)
    }
    
    public func stopMonitoringForRegion(region:Region) {
        Logger.debug("RegionScannerator#stopMonitoringForRegion")
        self.regionManager.stopMonitoringForRegion(region)
    }

}

var thisRegionScannerator : RegionScannerator?