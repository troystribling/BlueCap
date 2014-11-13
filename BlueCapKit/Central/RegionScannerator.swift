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
 
    internal class ScanneratorRegion : CircularRegion {
        
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
    private var lastLocation                    : CLLocation?
    
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
        self.startUpdatingLocation()
    }
    
    public func startScanningForServiceUUIDs(uuids:[CBUUID], afterPeripheralDiscovered:(peripheral:Peripheral, rssi:Int)->()) {
        Logger.debug("RegionScannerator#startScanningForServiceUUIDs: \(uuids)")
        self.afterPeripheralDiscovered = afterPeripheralDiscovered
        self._isScanning = true
        self.services = uuids
        self.afterTimeout = nil
        self.startUpdatingLocation()
    }
    
    override public func startScanning(timeoutSeconds:Double, afterPeripheralDiscovered:(peripheral:Peripheral, rssi:Int)->(), afterTimeout:(()->())? = nil) {
        self.timeoutSeconds = timeoutSeconds
        self.services = nil
        self._isScanning = true
        self.afterTimeout = afterTimeout
        self.startUpdatingLocation()
        self.timeoutScan()
    }
    
    override public func startScanningForServiceUUIDs(timeoutSeconds:Double, uuids:[CBUUID]!, afterPeripheralDiscoveredCallback:(peripheral:Peripheral, rssi:Int)->(), afterTimeout:(()->())? = nil) {
        self._isScanning = true
        self.services = uuids
        self.afterTimeout = afterTimeout
        self.timeoutSeconds = timeoutSeconds
        self.startUpdatingLocation()
        self.timeoutScan()
    }

    override public func stopScanning() {
        Logger.debug("RegionScannerator#stopScanning")
        self._isScanning = false
        self.afterTimeout = nil
        self.services = nil
        self.lastLocation = nil
        CentralManager.sharedInstance().stopScanning()
        self.regionManager.stopUpdatingLocation()
    }
    
    public func startMonitoringForRegion(region:CircularRegion) {
        Logger.debug("RegionScannerator#startMonitoringForRegion")
        let region = ScanneratorRegion(scanRegion:region) {(scanneratorRegion) in
            scanneratorRegion.exitRegion = {
                if let exitRegion = scanneratorRegion.scanRegion.exitRegion {
                    exitRegion()
                }
                CentralManager.sharedInstance().disconnectAllPeripherals()
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
            scanneratorRegion.regionStateDetermined = {(state) in
                if let regionStateDetermined = scanneratorRegion.scanRegion.regionStateDetermined {
                    regionStateDetermined(state:state)
                }
            }
            scanneratorRegion.errorMonitoringRegion = {(error) in
                if let errorMonitoringRegion = scanneratorRegion.scanRegion.errorMonitoringRegion {
                    errorMonitoringRegion(error:error)
                }
            }
        }
        self.regionManager.startMonitoringForRegion(region)
        if let lastLocation = self.lastLocation {
            if let enterRegion = region.enterRegion {
                if region.containsCoordinate(lastLocation.coordinate) {
                    enterRegion()
                }
            }
        }
    }
    
    public func stopMonitoringForRegion(region:Region) {
        Logger.debug("RegionScannerator#stopMonitoringForRegion")
        self.regionManager.stopMonitoringForRegion(region)
    }
    
    private func startUpdatingLocation() {
        var isFirst = true
        self.regionManager.startUpdatingLocation() {(locationManager) in
            locationManager.locationsUpdateSuccess = {(locations) in
                self.lastLocation = locations.last
                if isFirst {
                    if let location = locations.last {
                        isFirst = false
                        for region in self.regionManager.regions {
                            if let scanneratorRegion = region as? ScanneratorRegion {
                                if scanneratorRegion.containsCoordinate(location.coordinate) {
                                    if let enterRegion = scanneratorRegion.enterRegion {
                                        enterRegion()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

}

var thisRegionScannerator : RegionScannerator?