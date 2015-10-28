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

public protocol CBCentralManagerWrappable {
    var state : CBCentralManagerState {get}
    func scanForPeripheralsWithServices(uuids:[CBUUID]?, options:[String:AnyObject]?)
    func stopScan()
    func connectPeripheral(peripheral:CBPeripheral, options:[String:AnyObject]?)
    func cancelPeripheralConnection(peripheral:CBPeripheral)
}

extension CBCentralManager : CBCentralManagerWrappable {}

public class CentralManager : NSObject, CBCentralManagerDelegate {
    
    private var afterPowerOnPromise                             = Promise<Void>()
    private var afterPowerOffPromise                            = Promise<Void>()
    
    private var _isScanning                                     = false
    private var cbCentralManager : CBCentralManagerWrappable!   = nil

    internal var afterPeripheralDiscoveredPromise               = StreamPromise<Peripheral>()
    internal var discoveredPeripherals                          = [NSUUID: Peripheral]()

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
    
    public var isScanning : Bool {
        return self._isScanning
    }

    public override init() {
        super.init()
        self.cbCentralManager = CBCentralManager(delegate:self, queue:CentralQueue.queue)
    }
    
    public init(options:[String:AnyObject]?) {
        super.init()
        self.cbCentralManager = CBCentralManager(delegate:self, queue:CentralQueue.queue, options:options)
    }

    public init(centralManager:CBCentralManagerWrappable) {
        super.init()
        self.cbCentralManager = centralManager
    }
    
    public init(centralManager:CBCentralManagerWrappable, options:[String:AnyObject]?) {
        super.init()
        self.cbCentralManager = centralManager
    }

    internal func connectPeripheral(peripheral:Peripheral, options:[String:AnyObject]? = nil) {
        if let cbPeripheral = peripheral.cbPeripheral as? CBPeripheral {
            self.cbCentralManager.connectPeripheral(cbPeripheral, options:options)
        }
    }
    
    internal func cancelPeripheralConnection(peripheral:Peripheral) {
        if let cbPeripheral = peripheral.cbPeripheral as? CBPeripheral {
            self.cbCentralManager.cancelPeripheralConnection(cbPeripheral)
        }
    }

    // scanning
    public func startScanning(capacity:Int? = nil, options:[String:AnyObject]? = nil) -> FutureStream<Peripheral> {
        return self.startScanningForServiceUUIDs(nil, capacity:capacity)
    }
    
    public func startScanningForServiceUUIDs(uuids:[CBUUID]?, capacity:Int? = nil, options:[String:AnyObject]? = nil) -> FutureStream<Peripheral> {
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
        self.didConnectPeripheral(peripheral)
    }

    public func centralManager(_:CBCentralManager, didDisconnectPeripheral peripheral:CBPeripheral, error:NSError?) {
        self.didDisconnectPeripheral(peripheral, error:error)
    }

    public func centralManager(_:CBCentralManager, didDiscoverPeripheral peripheral:CBPeripheral, advertisementData:[String:AnyObject], RSSI:NSNumber) {
        self.didDiscoverPeripheral(peripheral, advertisementData:advertisementData, RSSI:RSSI)
    }

    public func centralManager(_:CBCentralManager, didFailToConnectPeripheral peripheral:CBPeripheral, error:NSError?) {
        self.didFailToConnectPeripheral(peripheral, error:error)
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
        self.didUpdateState()
    }
    
    public func didConnectPeripheral(peripheral:CBPeripheralWrappable) {
        Logger.debug("peripheral name \(peripheral.name)")
        if let bcPeripheral = self.discoveredPeripherals[peripheral.identifier] {
            bcPeripheral.didConnectPeripheral()
        }
    }
    
    public func didDisconnectPeripheral(peripheral:CBPeripheralWrappable, error:NSError?) {
        Logger.debug("peripheral name \(peripheral.name)")
        if let bcPeripheral = self.discoveredPeripherals[peripheral.identifier] {
            bcPeripheral.didDisconnectPeripheral()
        }
    }
    
    public func didDiscoverPeripheral(peripheral:CBPeripheralWrappable, advertisementData:[String:AnyObject], RSSI:NSNumber) {
        if self.discoveredPeripherals[peripheral.identifier] == nil {
            let bcPeripheral = Peripheral(cbPeripheral:peripheral, centralManager:self, advertisements:advertisementData, rssi:RSSI.integerValue)
            Logger.debug("peripheral name \(bcPeripheral.name)")
            self.discoveredPeripherals[peripheral.identifier] = bcPeripheral
            self.afterPeripheralDiscoveredPromise.success(bcPeripheral)
        }
    }
    
    public func didFailToConnectPeripheral(peripheral:CBPeripheralWrappable, error:NSError?) {
        Logger.debug()
        if let bcPeripheral = self.discoveredPeripherals[peripheral.identifier] {
            bcPeripheral.didFailToConnectPeripheral(error)
        }
    }
    
    public func didUpdateState() {
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
    
}
