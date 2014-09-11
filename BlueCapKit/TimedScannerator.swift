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
    
    class func sharedInstance() -> TimedScannerator {
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
        self.timeoutScan()
    }
    
    public func startScanningForServiceUUIDds(timeoutSeconds:Float, uuids:[CBUUID]!, afterPeripheralDiscoveredCallback:(peripheral:Peripheral, rssi:Int)->(), afterTimeout:(()->())? = nil) {
        CentralManager.sharedInstance().startScanningForServiceUUIDds(uuids, afterPeripheralDiscoveredCallback)
        self.afterTimeout = afterTimeout
        self.timeoutSeconds = timeoutSeconds
        self.timeoutScan()
    }
    
    public func stopScanning() {
        CentralManager.sharedInstance().stopScanning()
    }

    internal func timeoutScan() {
        Logger.debug("Scannerator#timeoutScan: \(self.timeoutSeconds)s")
        let central = CentralManager.sharedInstance()
        central.delayCallback(self.timeoutSeconds) {
            if central.peripherals.count == 0 {
                Logger.debug("Scannerator#timeoutScan: timing out")
                central.stopScanning()
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