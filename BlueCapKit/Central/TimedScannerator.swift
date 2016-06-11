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
    
    private let centralManager: CentralManager

    internal var timeoutSeconds     = 10.0
    internal var _isScanning        = false

    public var peripherals: [Peripheral] {
        return self.centralManager.peripherals
    }
    
    public var isScanning: Bool {
        return self._isScanning
    }

    public init(centralManager: CentralManager) {
        self.centralManager = centralManager
    }
    
    public func startScanning(timeoutSeconds: Double, capacity: Int? = nil) -> FutureStream<Peripheral> {
        self.timeoutSeconds = timeoutSeconds
        self._isScanning = true
        self.timeoutScan()
        return self.centralManager.startScanning(capacity)

    }
    
    public func startScanningForServiceUUIDs(timeoutSeconds: Double, uuids: [CBUUID]!, capacity: Int? = nil) -> FutureStream<Peripheral> {
        self.timeoutSeconds = timeoutSeconds
        self._isScanning = true
        self.timeoutScan()
        return self.centralManager.startScanningForServiceUUIDs(uuids, capacity:capacity)
    }
    
    public func stopScanning() {
        self._isScanning = false
        self.centralManager.stopScanning()
    }

    internal func timeoutScan() {
        Logger.debug("timeout in \(self.timeoutSeconds)s")
        self.centralManager.centralQueue.delay(self.timeoutSeconds) {
            if self._isScanning {
                if self.peripherals.count == 0 {
                    self.centralManager.afterPeripheralDiscoveredPromise.failure(BCError.centralPeripheralScanTimeout)
                }
                self.stopScanning()
            }
        }
    }

}
