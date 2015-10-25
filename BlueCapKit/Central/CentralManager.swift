//
//  CentralManager.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/4/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import Foundation
import CoreBluetooth

public struct CentralQueue {
    
    private static let queue = dispatch_queue_create("com.gnos.us.central.main", DISPATCH_QUEUE_SERIAL)
    
    public static func sync(request:()->()) {
        dispatch_sync(self.queue, request)
    }
    
    public static func async(request:()->()) {
        dispatch_async(self.queue, request)
    }
    
    public static func delay(delay:Double, request:()->()) {
        let popTime = dispatch_time(DISPATCH_TIME_NOW, Int64(Float(delay)*Float(NSEC_PER_SEC)))
        dispatch_after(popTime, self.queue, request)
    }
    
}

public class CentralManager : NSObject, CBCentralManagerDelegate {
    
    private var afterPowerOnPromise                 = Promise<Void>()
    private var afterPowerOffPromise                = Promise<Void>()
    internal var afterPeripheralDiscoveredPromise   = StreamPromise<Peripheral>()
    
    private var _isScanning         = false
    private var cbCentralManager    : CBCentralManager! = nil
    private static var instance     : CentralManager!
    
    public var poweredOn : Bool {
        return self.cbCentralManager.state == CBCentralManagerState.PoweredOn
    }
    
    public var poweredOff : Bool {
        return self.cbCentralManager.state == CBCentralManagerState.PoweredOff
    }
    
    public var peripherals : [Peripheral] {
        return Array(self.discoveredPeripherals.values).sort() {(p1:Peripheral, p2:Peripheral) -> Bool in
            switch p1.discoveredAt.compare(p2.discoveredAt) {
            case .OrderedSame:
                return true
            case .OrderedDescending:
                return false
            case .OrderedAscending:
                return true
            }
        }
    }
    
    public var state: CBCentralManagerState {
        return self.cbCentralManager.state
    }
    
    internal var discoveredPeripherals   = [CBPeripheral: Peripheral]()
    
    public class var sharedInstance : CentralManager {
        self.instance = self.instance ?? CentralManager()
        return self.instance
    }

    public class func sharedInstance(options:[String:AnyObject]) -> CentralManager {
        self.instance = self.instance ?? CentralManager(options:options)
        return self.instance
    }

    public var isScanning : Bool {
        return self._isScanning
    }

    // scanning
    public func startScanning(capacity:Int? = nil, options:[String:AnyObject]? = nil) -> FutureStream<Peripheral> {
        return self.startScanningForServiceUUIDs(nil, capacity:capacity)
    }
    
    public func startScanningForServiceUUIDs(uuids:[CBUUID]!, capacity:Int? = nil, options:[String:AnyObject]? = nil) -> FutureStream<Peripheral> {
        if !self._isScanning {
            Logger.debug("UUIDs \(uuids)")
            self._isScanning = true
            if let capacity = capacity {
                self.afterPeripheralDiscoveredPromise = StreamPromise<Peripheral>(capacity:capacity)
            } else {
                self.afterPeripheralDiscoveredPromise = StreamPromise<Peripheral>()
            }
            self.cbCentralManager.scanForPeripheralsWithServices(uuids, options:options)
        }
        return self.afterPeripheralDiscoveredPromise.future
    }
    
    public func stopScanning() {
        if self._isScanning {
            self._isScanning = false
            self.cbCentralManager.stopScan()
        }
    }
    
    public func removeAllPeripherals() {
        self.discoveredPeripherals.removeAll(keepCapacity:false)
    }
    
    // connection
    public func disconnectAllPeripherals() {
        for peripheral in self.discoveredPeripherals.values {
            peripheral.disconnect()
        }
    }
    
    public func connectPeripheral(peripheral:Peripheral, options:[String:AnyObject]?=nil) {
        self.cbCentralManager.connectPeripheral(peripheral.cbPeripheral, options:options)
    }
    
    internal func cancelPeripheralConnection(peripheral:Peripheral) {
        self.cbCentralManager.cancelPeripheralConnection(peripheral.cbPeripheral)
    }
    
    // power up
    public func powerOn() -> Future<Void> {
        CentralQueue.sync {
            self.afterPowerOnPromise = Promise<Void>()
            if self.poweredOn {
                self.afterPowerOnPromise.success()
            }
        }
        return self.afterPowerOnPromise.future
    }
    
    public func powerOff() -> Future<Void> {
        CentralQueue.sync {
            self.afterPowerOffPromise = Promise<Void>()
            if self.poweredOff {
                self.afterPowerOffPromise.success()
            }
        }
        return self.afterPowerOffPromise.future
    }
    
    // CBCentralManagerDelegate
    public func centralManager(_:CBCentralManager, didConnectPeripheral peripheral:CBPeripheral) {
        Logger.debug("peripheral name \(peripheral.name)")
        if let bcPeripheral = self.discoveredPeripherals[peripheral] {
            bcPeripheral.didConnectPeripheral()
        }
    }
    
    public func centralManager(_:CBCentralManager, didDisconnectPeripheral peripheral:CBPeripheral, error:NSError?) {
        Logger.debug("peripheral name \(peripheral.name)")
        if let bcPeripheral = self.discoveredPeripherals[peripheral] {
            bcPeripheral.didDisconnectPeripheral()
        }
    }
    
    public func centralManager(_:CBCentralManager, didDiscoverPeripheral peripheral:CBPeripheral, advertisementData:[String:AnyObject], RSSI:NSNumber) {
        if self.discoveredPeripherals[peripheral] == nil {
            let bcPeripheral = Peripheral(cbPeripheral:peripheral, central:self, advertisements:advertisementData, rssi:RSSI.integerValue)
            Logger.debug("peripheral name \(bcPeripheral.name)")
            self.discoveredPeripherals[peripheral] = bcPeripheral
            self.afterPeripheralDiscoveredPromise.success(bcPeripheral)
        }
    }
    
    public func centralManager(_:CBCentralManager, didFailToConnectPeripheral peripheral:CBPeripheral, error:NSError?) {
        Logger.debug()
        if let bcPeripheral = self.discoveredPeripherals[peripheral] {
            bcPeripheral.didFailToConnectPeripheral(error)
        }
    }
    
    public func centralManager(_:CBCentralManager!, didRetrieveConnectedPeripherals peripherals:[AnyObject]!) {
        Logger.debug()
    }
    
    public func centralManager(_:CBCentralManager!, didRetrievePeripherals peripherals:[AnyObject]!) {
        Logger.debug()
    }
    
    // central manager state
    public func centralManager(_:CBCentralManager, willRestoreState dict:[String:AnyObject]) {
        Logger.debug()
    }
    
    public func centralManagerDidUpdateState(_:CBCentralManager) {
        switch(self.cbCentralManager.state) {
        case .Unauthorized:
            Logger.debug("Unauthorized")
            break
        case .Unknown:
            Logger.debug("Unknown")
            break
        case .Unsupported:
            Logger.debug("Unsupported")
            break
        case .Resetting:
            Logger.debug("Resetting")
            break
        case .PoweredOff:
            Logger.debug("PoweredOff")
            if !self.afterPowerOffPromise.completed {
                self.afterPowerOffPromise.success()
            }
            break
        case .PoweredOn:
            Logger.debug("PoweredOn")
            if !self.afterPowerOnPromise.completed {
                self.afterPowerOnPromise.success()
            }
            break
        }
    }
    
    private override init() {
        super.init()
        self.cbCentralManager = CBCentralManager(delegate:self, queue:CentralQueue.queue)
    }

    private init(options:[String:AnyObject]?) {
        super.init()
        self.cbCentralManager = CBCentralManager(delegate:self, queue:CentralQueue.queue, options:options)
    }
    
}
