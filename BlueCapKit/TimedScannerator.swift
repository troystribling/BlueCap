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
    
    public var onTimeout : (() -> ())?
    
    class func sharedInstance() -> TimedScannerator {
        if thisTimedScannerator == nil {
            thisTimedScannerator = TimedScannerator()
        }
        return thisTimedScannerator!
    }

    public init() {
    }
    
    public func startScanning(timeoutSeconds:Float, afterPeripheralDiscovered:(peripheral:Peripheral, rssi:Int)->()) {
        CentralManager.sharedInstance().startScanning(afterPeripheralDiscovered)
        self.timeoutSeconds = timeoutSeconds
        self.timeoutScan()
    }
    
    public func startScanningForServiceUUIDds(timeoutSeconds:Float, uuids:[CBUUID]!, afterPeripheralDiscoveredCallback:(peripheral:Peripheral, rssi:Int)->()) {
        CentralManager.sharedInstance().startScanningForServiceUUIDds(uuids, afterPeripheralDiscoveredCallback)
        self.timeoutSeconds = timeoutSeconds
        self.timeoutScan()
    }
    
    public func stopScanning() {
        CentralManager.sharedInstance().stopScanning()
    }

    private func timeoutScan() {
        Logger.debug("Scannerator#timeoutScan: \(self.timeoutSeconds)s")
        let central = CentralManager.sharedInstance()
        central.delayCallback(self.timeoutSeconds) {
            if central.peripherals.count == 0 {
                Logger.debug("Scannerator#timeoutScan: timing out")
                central.stopScanning()
            } else {
                Logger.debug("Scannerator#timeoutScan: expired")
            }
        }
    }

}

var thisTimedScannerator : TimedScannerator?