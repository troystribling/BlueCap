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
 
    private let _regions : [CLRegion]
    
    public var regions : [CLRegion] {
        return self._regions
    }
    
    public init(regions:[CLRegion], initializer:((scannerator:RegionScannerator) -> ())? = nil) {
        self._regions = regions
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

}