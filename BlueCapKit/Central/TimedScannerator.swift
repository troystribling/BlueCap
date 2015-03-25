//
//  TimedScannerator.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/24/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation
import CoreBluetooth

///////////////////////////////////////////
// TimedScanneratorImpl
public protocol TimedScanneratorWrappable {
    
    typealias WrappedPeripheral
    
    var peripherals : [WrappedPeripheral] {get}
    
    func startScanning(capacity:Int?) -> FutureStream<WrappedPeripheral>
    func startScanningForServiceUUIDs(uuids:[CBUUID]!, capacity:Int?) -> FutureStream<WrappedPeripheral>
    func stopScanning()
    func timeout()
    
}

public class TimedScanneratorImpl<Wrapper where Wrapper:TimedScanneratorWrappable,
                                                Wrapper.WrappedPeripheral:PeripheralWrappable> {
    
    internal var timeoutSeconds = 10.0
    
    internal var _isScanning = false
    
    public var isScanning : Bool {
        return self._isScanning
    }
    
    public init() {
    }
    
    public func startScanning(scanner:Wrapper, timeoutSeconds:Double, capacity:Int? = nil) -> FutureStream<Wrapper.WrappedPeripheral> {
        self.timeoutSeconds = timeoutSeconds
        self._isScanning = true
        self.timeoutScan(scanner)
        return scanner.startScanning(capacity)
    }
    
    public func startScanningForServiceUUIDs(scanner:Wrapper, timeoutSeconds:Double, uuids:[CBUUID]!, capacity:Int? = nil) -> FutureStream<Wrapper.WrappedPeripheral> {
        self.timeoutSeconds = timeoutSeconds
        self._isScanning = true
        self.timeoutScan(scanner)
        return scanner.startScanningForServiceUUIDs(uuids, capacity:capacity)
    }
    
    public func stopScanning(scanner:Wrapper) {
        self._isScanning = false
        scanner.stopScanning()
    }
    
    internal func timeoutScan(scanner:Wrapper) {
        Logger.debug("Scannerator#timeoutScan: \(self.timeoutSeconds)s")
        CentralQueue.delay(self.timeoutSeconds) {
            if scanner.peripherals.count == 0 {
                scanner.timeout()
            }
        }
    }

}

// TimedScanneratorImpl
///////////////////////////////////////////

public class TimedScannerator : TimedScanneratorWrappable {
    
    private let impl = TimedScanneratorImpl<TimedScannerator>()

    // TimedScanneratorWrappable
    public var peripherals : [Peripheral] {
        return CentralManager.sharedInstance.peripherals
    }
    
    public func startScanning(capacity:Int?) -> FutureStream<Peripheral> {
        return CentralManager.sharedInstance.startScanning(capacity:capacity)
    }
    
    public func startScanningForServiceUUIDs(uuids:[CBUUID]!, capacity:Int?) -> FutureStream<Peripheral> {
        return CentralManager.sharedInstance.startScanningForServiceUUIDs(uuids, capacity:capacity)
    }
    
    public func timeout() {
        CentralManager.sharedInstance.impl.afterPeripheralDiscoveredPromise.failure(BCError.peripheralDiscoveryTimeout)
    }
    // TimedScanneratorWrappable
    
    public var isScanning : Bool {
        return self.impl.isScanning
    }

    public class var sharedInstance : TimedScannerator {
        struct Static {
            static let instance = TimedScannerator()
        }
        return Static.instance
    }

    public init() {
    }
    
    public func startScanning(timeoutSeconds:Double, capacity:Int? = nil) -> FutureStream<Peripheral> {
        return self.impl.startScanning(self, timeoutSeconds:timeoutSeconds, capacity:capacity)
    }
    
    public func startScanningForServiceUUIDs(timeoutSeconds:Double, uuids:[CBUUID]!, capacity:Int? = nil) -> FutureStream<Peripheral> {
        return self.impl.startScanningForServiceUUIDs(self, timeoutSeconds:timeoutSeconds, uuids:uuids, capacity:capacity)
    }
    
    public func stopScanning() {
        self.impl.stopScanning(self)
    }

    internal func timeoutScan() {
        self.impl.timeoutScan(self)
    }

}
