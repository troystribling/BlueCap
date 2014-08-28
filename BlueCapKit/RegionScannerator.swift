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
    
    private let _regionManager : RegionManager
    
    public var regions : [CLRegion] {
        return self._regionManager.regions
    }

    public var regionManager : RegionManager {
        return self._regionManager
    }
    
    public init(initializer:((scannerator:RegionScannerator) -> ())? = nil) {
        self._regionManager = RegionManager()
        if let initializer = initializer {
            initializer(scannerator:self)
        }
    }
    
    public func startScanning(afterPeripheralDiscovered:(peripheral:Peripheral, rssi:Int)->()) {
        CentralManager.sharedInstance().startScanning(afterPeripheralDiscovered)
    }
    
    public func startScanningForServiceUUIDds(uuids:[CBUUID]!, afterPeripheralDiscoveredCallback:(peripheral:Peripheral, rssi:Int)->()) {
        CentralManager.sharedInstance().startScanningForServiceUUIDds(uuids, afterPeripheralDiscoveredCallback)
    }
    
    public func stopScanning() {
        CentralManager.sharedInstance().stopScanning()
    }
    
    public func addRegion(regionMonitor:RegionMonitor) {
        let scanneratorMonitor = RegionScanneratorMonitor(regionMonitor:regionMonitor) {(regionMonitor) in
            regionMonitor.exitRegion            = {
                if let exitRegion = regionMonitor.regionMonitor.exitRegion {
                    exitRegion()
                } else {
                }
            }
            regionMonitor.enterRegion           = {
                if let enterRegion = regionMonitor.regionMonitor.enterRegion {
                    enterRegion()
                } else {                    
                }
            }
            regionMonitor.startMonitoringRegion = {
                if let startMonitoringRegion = regionMonitor.regionMonitor.startMonitoringRegion {
                    startMonitoringRegion()
                }
            }
            regionMonitor.regionStateChanged    = {(state) in
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
    
    public func removeRegion(regionMonitor:RegionMonitor) {
        self.regionManager.stopMonitoringForRegion(regionMonitor)
    }

}