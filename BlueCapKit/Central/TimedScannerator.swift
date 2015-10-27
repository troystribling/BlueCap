//
//  TimedScannerator.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/24/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import Foundation
import CoreBluetooth

public class TimedScannerator {
    
    private let central : CentralManager

    internal var timeoutSeconds     = 10.0
    internal var _isScanning        = false

    public var peripherals : [Peripheral] {
        return self.central.peripherals
    }
    
    public var isScanning : Bool {
        return self._isScanning
    }

    public init(centralManager:CentralManager) {
        self.central = centralManager
    }
    
    public func startScanning(timeoutSeconds:Double, capacity:Int? = nil) -> FutureStream<Peripheral> {
        self.timeoutSeconds = timeoutSeconds
        self._isScanning = true
        self.timeoutScan()
        return self.central.startScanning(capacity)

    }
    
    public func startScanningForServiceUUIDs(timeoutSeconds:Double, uuids:[CBUUID]!, capacity:Int? = nil) -> FutureStream<Peripheral> {
        self.timeoutSeconds = timeoutSeconds
        self._isScanning = true
        self.timeoutScan()
        return self.central.startScanningForServiceUUIDs(uuids, capacity:capacity)
    }
    
    public func stopScanning() {
        self._isScanning = false
        self.central.stopScanning()
    }

    internal func timeoutScan() {
        Logger.debug("timeout in \(self.timeoutSeconds)s")
        CentralQueue.delay(self.timeoutSeconds) {
            if self.peripherals.count == 0 {
                self.central.afterPeripheralDiscoveredPromise.failure(BCError.peripheralDiscoveryTimeout)
            }
        }
    }

}
