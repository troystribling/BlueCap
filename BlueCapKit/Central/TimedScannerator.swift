//
//  TimedScannerator.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/24/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation
import CoreBluetooth

public class TimedScannerator {
    
    internal var timeoutSeconds = 10.0

    internal var _isScanning = false
    
    public var isScanning : Bool {
        return self._isScanning
    }
    
    public class var sharedInstance : TimedScannerator {
        struct Static {
            static let instance = TimedScannerator()
        }
        return Static.instance
    }

    public init() {
    }
    
    public func startScanning(timeoutSeconds:Double) -> FutureStream<(Peripheral, Int)> {
        self.timeoutSeconds = timeoutSeconds
        self._isScanning = true
        self.timeoutScan()
        return CentralManager.sharedInstance.startScanning()
    }
    
    public func startScanningForServiceUUIDs(timeoutSeconds:Double, uuids:[CBUUID]!) -> FutureStream<(Peripheral, Int)> {
        self.timeoutSeconds = timeoutSeconds
        self._isScanning = true
        self.timeoutScan()
        return CentralManager.sharedInstance.startScanningForServiceUUIDs(uuids)
    }
    
    public func stopScanning() {
        self._isScanning = false
        CentralManager.sharedInstance.stopScanning()
    }

    internal func timeoutScan() {
        Logger.debug("Scannerator#timeoutScan: \(self.timeoutSeconds)s")
        CentralManager.sharedInstance.delay(self.timeoutSeconds) {
            CentralManager.sharedInstance.afterPeripheralDiscoveredPromise.failure(BCError.peripheralDiscoveryTimeout)
        }
    }

}
