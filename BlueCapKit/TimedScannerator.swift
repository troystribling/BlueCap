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
    
    internal var timeoutSeconds : Float?
    
    public var onTimeout : (() -> ())?
    
    public init() {
    }
    
    public init(timeoutSeconds:Float, initializer:((scannerator:TimedScannerator) -> ())? = nil) {
        self.timeoutSeconds = timeoutSeconds
        if let initializer = initializer {
            initializer(scannerator:self)
        }
    }
    
    public func startScanning(afterPeripheralDiscovered:(peripheral:Peripheral, rssi:Int)->()) {
        CentralManager.sharedInstance().startScanning(afterPeripheralDiscovered)
        self.timeoutScan()
    }
    
    public func startScanningForServiceUUIDds(uuids:[CBUUID]!, afterPeripheralDiscoveredCallback:(peripheral:Peripheral, rssi:Int)->()) {
        CentralManager.sharedInstance().startScanningForServiceUUIDds(uuids, afterPeripheralDiscoveredCallback)
        self.timeoutScan()
    }
    
    public func stopScanning() {
        CentralManager.sharedInstance().stopScanning()
    }

    private func timeoutScan() {
        if let timeoutSeconds = self.timeoutSeconds {
            if let onTimeout = self.onTimeout {
                Logger.debug("Scannerator#timeoutScan: \(timeoutSeconds)s")
                let central = CentralManager.sharedInstance()
                central.delayCallback(timeoutSeconds) {
                    if central.peripherals.count == 0 {
                        Logger.debug("Scannerator#timeoutScan: timing out")
                        onTimeout()
                    } else {
                        Logger.debug("Scannerator#timeoutScan: expired")
                    }
                }
            }
        }
    }

}