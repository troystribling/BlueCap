//
//  CentralManager.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/4/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import Foundation
import CoreBluetooth

///////////////////////////////////////////
// CentralManagerImpl
public protocol CentralManagerWrappable {
    
    typealias WrappedPeripheral
    
    var poweredOn   : Bool                  {get}
    var poweredOff  : Bool                  {get}
    var peripherals : [WrappedPeripheral]   {get}
    var state: CBCentralManagerState        {get}
    
    func scanForPeripheralsWithServices(uuids:[CBUUID]?)
    func stopScan()
}

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

public class CentralManagerImpl<Wrapper where Wrapper:CentralManagerWrappable,
                                                    Wrapper.WrappedPeripheral:PeripheralWrappable> {
    
    private var afterPowerOnPromise                 = Promise<Void>()
    private var afterPowerOffPromise                = Promise<Void>()
    internal var afterPeripheralDiscoveredPromise   = StreamPromise<Wrapper.WrappedPeripheral>()

    private var _isScanning      = false
    
    public var isScanning : Bool {
        return self._isScanning
    }
    
    public init() {
    }

    public func startScanning(central:Wrapper, capacity:Int? = nil) -> FutureStream<Wrapper.WrappedPeripheral> {
        return self.startScanningForServiceUUIDs(central, uuids:nil, capacity:capacity)
    }
    
    public func startScanningForServiceUUIDs(central:Wrapper, uuids:[CBUUID]!, capacity:Int? = nil) -> FutureStream<Wrapper.WrappedPeripheral> {
        if !self._isScanning {
            Logger.debug("UUIDs \(uuids)")
            self._isScanning = true
            if let capacity = capacity {
                self.afterPeripheralDiscoveredPromise = StreamPromise<Wrapper.WrappedPeripheral>(capacity:capacity)
            } else {
                self.afterPeripheralDiscoveredPromise = StreamPromise<Wrapper.WrappedPeripheral>()
            }
            central.scanForPeripheralsWithServices(uuids)
        }
        return self.afterPeripheralDiscoveredPromise.future
    }
    
    public func stopScanning(central:Wrapper) {
        if self._isScanning {
            Logger.debug()
            self._isScanning = false
            central.stopScan()
        }
    }
    
    // connection
    public func disconnectAllPeripherals(central:Wrapper) {
        Logger.debug()
        for peripheral in central.peripherals {
            peripheral.disconnect()
        }
    }
    
    
    // power up
    public func powerOn(central:Wrapper) -> Future<Void> {
        Logger.debug()
        CentralQueue.sync {
            self.afterPowerOnPromise = Promise<Void>()
            if central.poweredOn {
                self.afterPowerOnPromise.success()
            }
        }
        return self.afterPowerOnPromise.future
    }
    
    public func powerOff(central:Wrapper) -> Future<Void> {
        Logger.debug()
        CentralQueue.sync {
            self.afterPowerOffPromise = Promise<Void>()
            if central.poweredOff {
                self.afterPowerOffPromise.success()
            }
        }
        return self.afterPowerOffPromise.future
    }
    
    public func didDiscoverPeripheral(peripheral:Wrapper.WrappedPeripheral) {
        self.afterPeripheralDiscoveredPromise.success(peripheral)
    }
    
    // central manager state
    public func didUpdateState(central:Wrapper) {
        switch(central.state) {
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
// CentralManagerImpl
///////////////////////////////////////////

public class CentralManager : NSObject, CBCentralManagerDelegate, CentralManagerWrappable {
    
    private static var instance : CentralManager!
    
    internal let impl = CentralManagerImpl<CentralManager>()

    // CentralManagerWrappable
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
    
    public func scanForPeripheralsWithServices(uuids:[CBUUID]?) {
        self.cbCentralManager.scanForPeripheralsWithServices(uuids,options:nil)
    }
    
    public func stopScan() {
        self.cbCentralManager.stopScan()
    }
    // CentralManagerWrappable
    
    private var cbCentralManager : CBCentralManager! = nil
    
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
        return self.impl.isScanning
    }

    // scanning
    public func startScanning(capacity:Int? = nil) -> FutureStream<Peripheral> {
        return self.impl.startScanning(self, capacity:capacity)
    }
    
    public func startScanningForServiceUUIDs(uuids:[CBUUID]!, capacity:Int? = nil) -> FutureStream<Peripheral> {
        return self.impl.startScanningForServiceUUIDs(self, uuids:uuids, capacity:capacity)
    }
    
    public func stopScanning() {
        self.impl.stopScanning(self)
    }
    
    public func removeAllPeripherals() {
        self.discoveredPeripherals.removeAll(keepCapacity:false)
    }
    
    // connection
    public func disconnectAllPeripherals() {
        self.impl.disconnectAllPeripherals(self)
    }
    
    public func connectPeripheral(peripheral:Peripheral, options:[String:AnyObject]?=nil) {
        Logger.debug()
        self.cbCentralManager.connectPeripheral(peripheral.cbPeripheral, options:options)
    }
    
    internal func cancelPeripheralConnection(peripheral:Peripheral) {
        Logger.debug()
        self.cbCentralManager.cancelPeripheralConnection(peripheral.cbPeripheral)
    }
    
    // power up
    public func powerOn() -> Future<Void> {
        return self.impl.powerOn(self)
    }
    
    public func powerOff() -> Future<Void> {
        return self.impl.powerOff(self)
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
            let bcPeripheral = Peripheral(cbPeripheral:peripheral, advertisements:self.unpackAdvertisements(advertisementData), rssi:RSSI.integerValue)
            Logger.debug("peripheral name \(bcPeripheral.name)")
            self.discoveredPeripherals[peripheral] = bcPeripheral
            self.impl.didDiscoverPeripheral(bcPeripheral)
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
        self.impl.didUpdateState(self)
    }
    
    private override init() {
        super.init()
        self.cbCentralManager = CBCentralManager(delegate:self, queue:CentralQueue.queue)
    }

    private init(options:[String:AnyObject]?) {
        super.init()
        self.cbCentralManager = CBCentralManager(delegate:self, queue:CentralQueue.queue, options:options)
    }

    internal func unpackAdvertisements(advertDictionary:[String:AnyObject]) -> [String:String] {
        Logger.debug("number of advertisements found \(advertDictionary.count)")
        var advertisements = [String:String]()
        func addKey(key:String, andValue value:AnyObject) -> () {
            if value is NSString {
                advertisements[key] = (value as? String)
            } else {
                advertisements[key] = value.stringValue
            }
            Logger.debug("advertisement key=\(key), value=\(advertisements[key])")
        }
        for key in advertDictionary.keys {
            if let value : AnyObject = advertDictionary[key] {
                if value is NSArray {
                    for valueItem : AnyObject in (value as! NSArray) {
                        addKey(key, andValue:valueItem)
                    }
                } else {
                    addKey(key, andValue:value)
                }
            }
        }
        return advertisements
    }
    
}
