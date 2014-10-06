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
    
    internal var timeoutSeconds : Float = 10.0

    internal var _isScanning = false
    
    public var afterTimeout : (() -> ())?
    
    public var isScanning : Bool {
        return self._isScanning
    }
    
    public class func sharedInstance() -> TimedScannerator {
        if thisTimedScannerator == nil {
            thisTimedScannerator = TimedScannerator()
        }
        return thisTimedScannerator!
    }

    public init() {
    }
    
    public func startScanning(timeoutSeconds:Float, afterPeripheralDiscovered:(peripheral:Peripheral, rssi:Int)->(), afterTimeout:(()->())? = nil) {
        CentralManager.sharedInstance().startScanning(afterPeripheralDiscovered)
        self.timeoutSeconds = timeoutSeconds
        self.afterTimeout = afterTimeout
        self._isScanning = true
        self.timeoutScan()
    }
    
    public func startScanningForServiceUUIDs(timeoutSeconds:Float, uuids:[CBUUID]!, afterPeripheralDiscoveredCallback:(peripheral:Peripheral, rssi:Int)->(), afterTimeout:(()->())? = nil) {
        CentralManager.sharedInstance().startScanningForServiceUUIDs(uuids, afterPeripheralDiscoveredCallback)
        self.afterTimeout = afterTimeout
        self.timeoutSeconds = timeoutSeconds
        self._isScanning = true
        self.timeoutScan()
    }
    
    public func stopScanning() {
        self._isScanning = false
        CentralManager.sharedInstance().stopScanning()
    }

    internal func timeoutScan() {
        Logger.debug("Scannerator#timeoutScan: \(self.timeoutSeconds)s")
        let central = CentralManager.sharedInstance()
        central.delayCallback(self.timeoutSeconds) {
            if central.peripherals.count == 0 {
                Logger.debug("Scannerator#timeoutScan: timing out")
                self.stopScanning()
                if let afterTimeout = self.afterTimeout {
                    afterTimeout()
                }
            } else {
                Logger.debug("Scannerator#timeoutScan: expired")
            }
        }
    }

}

var thisTimedScannerator : TimedScannerator?