//
//  CentralManager.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/4/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation
import CoreBluetooth

///////////////////////////////////////////
// ServiceImpl
public protocol CentralManagerWrappable {
    
    typealias WrappedPeripheral
    
    var poweredOn   : Bool                  {get}
    var poweredOff  : Bool                  {get}
    var peripherals : [WrappedPeripheral]   {get}
    var state: CBCentralManagerState        {get}
    
    func scanForPeripheralsWithServices(uuids:[CBUUID]!)
    func stopScan()
}

public final class CentralManagerImpl<Wrapper where Wrapper:CentralManagerWrappable,
                                                    Wrapper.WrappedPeripheral:PeripheralWrappable> {
  
    let central : Wrapper
    
    private var afterPowerOnPromise                 = Promise<Void>()
    private var afterPowerOffPromise                = Promise<Void>()
    internal var afterPeripheralDiscoveredPromise   = StreamPromise<Wrapper.WrappedPeripheral>()

    private var _isScanning         = false
    
    public var isScanning : Bool {
        return self._isScanning
    }
    
    public func startScanning(capacity:Int? = nil) -> FutureStream<Wrapper.WrappedPeripheral> {
        return self.startScanningForServiceUUIDs(nil, capacity:capacity)
    }
    
    public func startScanningForServiceUUIDs(uuids:[CBUUID]!, capacity:Int? = nil) -> FutureStream<Wrapper.WrappedPeripheral> {
        if !self._isScanning {
            Logger.debug("CentralManagerImpl#startScanningForServiceUUIDs: \(uuids)")
            self._isScanning = true
            if let capacity = capacity {
                self.afterPeripheralDiscoveredPromise = StreamPromise<Wrapper.WrappedPeripheral>(capacity:capacity)
            } else {
                self.afterPeripheralDiscoveredPromise = StreamPromise<Wrapper.WrappedPeripheral>()
            }
            self.central.scanForPeripheralsWithServices(uuids)
        }
        return self.afterPeripheralDiscoveredPromise.future
    }
    
    public func stopScanning() {
        if self._isScanning {
            Logger.debug("CentralManagerImpl#stopScanning")
            self._isScanning = false
            self.central.stopScan()
        }
    }
    
    // connection
    public func disconnectAllPeripherals() {
        Logger.debug("CentralManagerImpl#disconnectAllPeripherals")
        for peripheral in self.central.peripherals {
            peripheral.disconnect()
        }
    }
    
    
    // power up
    public func powerOn() -> Future<Void> {
        Logger.debug("CentralManagerImpl#powerOn")
        let future = self.afterPowerOnPromise.future
        self.afterPowerOnPromise = Promise<Void>()
        if self.central.poweredOn {
            self.afterPowerOnPromise.success()
        }
        return future
    }
    
    public func powerOff() -> Future<Void> {
        Logger.debug("CentralManagerImpl#powerOff")
        let future = self.afterPowerOffPromise.future
        self.afterPowerOffPromise = Promise<Void>()
        if self.central.poweredOff {
            self.afterPowerOnPromise.success()
        }
        return future
    }
    
    public func didDiscoverPeripheral(peripheral:Wrapper.WrappedPeripheral) {
        self.afterPeripheralDiscoveredPromise.success(peripheral)
    }
    
    // central manager state
    public func centralManagerDidUpdateState() {
        switch(self.central.state) {
        case .Unauthorized:
            Logger.debug("CentralManagerImpl#centralManagerDidUpdateState: Unauthorized")
            break
        case .Unknown:
            Logger.debug("CentralManagerImpl#centralManagerDidUpdateState: Unknown")
            break
        case .Unsupported:
            Logger.debug("CentralManagerImpl#centralManagerDidUpdateState: Unsupported")
            break
        case .Resetting:
            Logger.debug("CentralManagerImpl#centralManagerDidUpdateState: Resetting")
            break
        case .PoweredOff:
            Logger.debug("CentralManagerImpl#centralManagerDidUpdateState: PoweredOff")
            self.afterPowerOffPromise.success()
            break
        case .PoweredOn:
            Logger.debug("CentralManager#centralManagerDidUpdateState: PoweredOn")
            self.afterPowerOnPromise.success()
            break
        }
    }
    
    public init(central:Wrapper) {
        self.central = central
    }
    
}
// ServiceImpl
///////////////////////////////////////////

public class CentralManager : NSObject, CBCentralManagerDelegate, CentralManagerWrappable {
    
    internal var impl : CentralManagerImpl<CentralManager>!

    // ServiceImpl
    public var poweredOn : Bool {
        return self.cbCentralManager.state == CBCentralManagerState.PoweredOn
    }
    
    public var poweredOff : Bool {
        return self.cbCentralManager.state == CBCentralManagerState.PoweredOff
    }
    
    public var peripherals : [Peripheral] {
        return sorted(self.discoveredPeripherals.values.array, {(p1:Peripheral, p2:Peripheral) -> Bool in
            switch p1.discoveredAt.compare(p2.discoveredAt) {
            case .OrderedSame:
                return true
            case .OrderedDescending:
                return false
            case .OrderedAscending:
                return true
            }
        })
    }
    
    public var state: CBCentralManagerState {
        return self.cbCentralManager.state
    }
    
    public func scanForPeripheralsWithServices(uuids:[CBUUID]!) {
        self.cbCentralManager.scanForPeripheralsWithServices(uuids,options:nil)
    }
    
    public func stopScan() {
        self.cbCentralManager.stopScan()
    }

    // ServiceImpl
    
    private var cbCentralManager : CBCentralManager! = nil
    private let centralQueue     = dispatch_queue_create("com.gnos.us.central.main", DISPATCH_QUEUE_SERIAL)
    
    internal var discoveredPeripherals   = [CBPeripheral: Peripheral]()
    
    public class var sharedInstance : CentralManager {
        struct Static {
            static let instance = CentralManager()
        }
        return Static.instance
    }
    
    public var isScanning : Bool {
        return self.impl.isScanning
    }

    // scanning
    public func startScanning(capacity:Int? = nil) -> FutureStream<Peripheral> {
        return self.impl.startScanning(capacity:capacity)
    }
    
    public func startScanningForServiceUUIDs(uuids:[CBUUID]!, capacity:Int? = nil) -> FutureStream<Peripheral> {
        return self.impl.startScanningForServiceUUIDs(uuids, capacity:capacity)
    }
    
    public func stopScanning() {
        self.impl.stopScanning()
    }
    
    public func removeAllPeripherals() {
        self.discoveredPeripherals.removeAll(keepCapacity:false)
    }
    
    // connection
    public func disconnectAllPeripherals() {
        self.impl.disconnectAllPeripherals()
    }
    
    // power up
    public func powerOn() -> Future<Void> {
        return self.impl.powerOn()
    }
    
    public func powerOff() -> Future<Void> {
        return self.impl.powerOff()
    }
    
    // CBCentralManagerDelegate
    public func centralManager(_:CBCentralManager!, didConnectPeripheral peripheral:CBPeripheral!) {
        Logger.debug("CentralManager#didConnectPeripheral: \(peripheral.name)")
        if let bcPeripheral = self.discoveredPeripherals[peripheral] {
            bcPeripheral.didConnectPeripheral()
        }
    }
    
    public func centralManager(_:CBCentralManager!, didDisconnectPeripheral peripheral:CBPeripheral!, error:NSError!) {
        Logger.debug("CentralManager#didDisconnectPeripheral: \(peripheral.name)")
        if let bcPeripheral = self.discoveredPeripherals[peripheral] {
            bcPeripheral.didDisconnectPeripheral()
        }
    }
    
    public func centralManager(_:CBCentralManager!, didDiscoverPeripheral peripheral:CBPeripheral!, advertisementData:[NSObject:AnyObject]!, RSSI:NSNumber!) {
        if self.discoveredPeripherals[peripheral] == nil {
            let bcPeripheral = Peripheral(cbPeripheral:peripheral, advertisements:self.unpackAdvertisements(advertisementData), rssi:RSSI.integerValue)
            Logger.debug("CentralManager#didDiscoverPeripheral: \(bcPeripheral.name)")
            self.discoveredPeripherals[peripheral] = bcPeripheral
            self.impl.didDiscoverPeripheral(bcPeripheral)
        }
    }
    
    public func centralManager(_:CBCentralManager!, didFailToConnectPeripheral peripheral:CBPeripheral!, error:NSError!) {
        Logger.debug("CentralManager#didFailToConnectPeripheral")
        if let bcPeripheral = self.discoveredPeripherals[peripheral] {
            bcPeripheral.didFailToConnectPeripheral(error)
        }
    }
    
    public func centralManager(_:CBCentralManager!, didRetrieveConnectedPeripherals peripherals:[AnyObject]!) {
        Logger.debug("CentralManager#didRetrieveConnectedPeripherals")
    }
    
    public func centralManager(_:CBCentralManager!, didRetrievePeripherals peripherals:[AnyObject]!) {
        Logger.debug("CentralManager#didRetrievePeripherals")
    }
    
    // central manager state
    public func centralManager(_:CBCentralManager!, willRestoreState dict:[NSObject:AnyObject]!!) {
        Logger.debug("CentralManager#willRestoreState")
    }
    
    public func centralManagerDidUpdateState(_:CBCentralManager!) {
        self.impl.centralManagerDidUpdateState()
    }
    
    internal class func sync(request:()->()) {
        CentralManager.sharedInstance.sync(request)
    }
    
    internal class func async(request:()->()) {
        CentralManager.sharedInstance.async(request)
    }
    
    internal class func delay(delay:Double, request:()->()) {
        CentralManager.sharedInstance.delay(delay, request:request)
    }
    
    internal func sync(request:()->()) {
        dispatch_sync(self.centralQueue, request)
    }
    
    internal func async(request:()->()) {
        dispatch_async(self.centralQueue, request)
    }
    
    internal func delay(delay:Double, request:()->()) {
        let popTime = dispatch_time(DISPATCH_TIME_NOW, Int64(Float(delay)*Float(NSEC_PER_SEC)))
        dispatch_after(popTime, self.centralQueue, request)
    }
    
    internal func connectPeripheral(peripheral:Peripheral) {
        Logger.debug("CentralManager#connectPeripheral")
        self.cbCentralManager.connectPeripheral(peripheral.cbPeripheral, options:nil)
    }
    
    internal func cancelPeripheralConnection(peripheral:Peripheral) {
        Logger.debug("CentralManager#cancelPeripheralConnection")
        self.cbCentralManager.cancelPeripheralConnection(peripheral.cbPeripheral)
    }
    
    private override init() {
        super.init()
        self.impl = CentralManagerImpl<CentralManager>(central:self)
        self.cbCentralManager = CBCentralManager(delegate:self, queue:self.centralQueue)
    }
    
    internal func unpackAdvertisements(advertDictionary:[NSObject:AnyObject]!) -> [String:String] {
        Logger.debug("CentralManager#unpackAdvertisements found \(advertDictionary.count) advertisements")
        var advertisements = [String:String]()
        func addKey(key:String, andValue value:AnyObject) -> () {
            if value is NSString {
                advertisements[key] = (value as? String)
            } else {
                advertisements[key] = value.stringValue
            }
            Logger.debug("CentralManager#unpackAdvertisements key:\(key), value:\(advertisements[key])")
        }
        if advertDictionary != nil {
            for keyObject : NSObject in advertDictionary.keys {
                if let key = keyObject as? String {
                    if let value : AnyObject = advertDictionary[keyObject] {
                        if value is NSArray {
                            for v : AnyObject in (value as! NSArray) {
                                addKey(key, andValue:value)
                            }
                        } else {
                            addKey(key, andValue:value)
                        }
                    }
                }
            }
        }
        Logger.debug("CentralManager#unpackAdvertisements unpacked \(advertisements.count) advertisements")
        return advertisements
    }
    
}
