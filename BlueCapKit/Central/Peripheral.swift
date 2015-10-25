//
//  Peripheral.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/8/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import Foundation
import CoreBluetooth

enum PeripheralConnectionError {
    case None, Timeout, Unknown
}

public enum ConnectionEvent {
    case Connect, Timeout, Disconnect, ForceDisconnect, Failed, GiveUp
}

public class Peripheral : NSObject, CBPeripheralDelegate {
    
    private var servicesDiscoveredPromise   = Promise<Peripheral>()
    private var readRSSIPromise             = Promise<Int>()
    private var connectionPromise : StreamPromise<(Peripheral, ConnectionEvent)>?

    private var timeoutCount : UInt         = 0
    private var disconnectCount : UInt      = 0
    
    private var connectionSequence          = 0
    private var currentError                = PeripheralConnectionError.None
    private var forcedDisconnect            = false
    
    private let _discoveredAt               = NSDate()
    private var _connectedAt : NSDate?
    private var _disconnectedAt : NSDate?
    
    private var discoveredServices          = [CBUUID:Service]()
    private var discoveredCharacteristics   = [CBCharacteristic:Characteristic]()
    
    internal var connectionTimeout          = 10.0
    internal var timeoutRetries : UInt?
    internal var disconnectRetries : UInt?
    internal let cbPeripheral : CBPeripheral
    internal let central : CentralManager
    
    public let advertisements : [String: AnyObject]
    public let rssi : Int

    public var discoveredAt : NSDate {
        return self._discoveredAt
    }
    
    public var connectedAt : NSDate? {
        return self._connectedAt
    }
    
    public var disconnectedAt : NSDate? {
        return self._disconnectedAt
    }
    
    public var name : String {
        if let name = self.cbPeripheral.name {
            return name
        } else {
            return "Unknown"
        }
    }

    public var state : CBPeripheralState {
        return self.cbPeripheral.state
    }
    
    public var services : [Service] {
        return Array(self.discoveredServices.values)
    }
    
    public var identifier : NSUUID {
        return self.cbPeripheral.identifier
    }
    
    // advertisements
    public var advertisedLocalName : String? {
        if let localname = self.advertisements[CBAdvertisementDataLocalNameKey] {
            return localname as? String
        } else {
            return nil
        }
    }
    
    public var advertisedManufactuereData : NSData? {
        if let mfgData = self.advertisements[CBAdvertisementDataManufacturerDataKey] {
            return mfgData as? NSData
        } else {
            return nil;
        }
    }
    
    public var advertisedTxPower : NSNumber? {
        if let txPower = self.advertisements[CBAdvertisementDataTxPowerLevelKey] {
            return txPower as? NSNumber
        } else {
            return nil
        }
    }
    
    public var advertisedIsConnectable : NSNumber? {
        if let isConnectable = self.advertisements[CBAdvertisementDataIsConnectable] {
            return isConnectable as? NSNumber
        } else {
            return nil
        }
    }
    
    public var advertisedServiceUUIDs : [CBUUID]? {
        if let serviceUUIDs = self.advertisements[CBAdvertisementDataServiceUUIDsKey] {
            return serviceUUIDs as? [CBUUID]
        } else {
            return nil
        }
    }
    
    public var advertisedServiceData : [CBUUID:NSData]? {
        if let serviceData = self.advertisements[CBAdvertisementDataServiceDataKey] {
            return serviceData as? [CBUUID:NSData]
        } else {
            return nil
        }
    }
    
    public var advertisedOverflowServiceUUIDs : [CBUUID]? {
        if let serviceUUIDs = self.advertisements[CBAdvertisementDataOverflowServiceUUIDsKey] {
            return serviceUUIDs as? [CBUUID]
        } else {
            return nil
        }
    }
    
    public var advertisedSolicitedServiceUUIDs : [CBUUID]? {
        if let serviceUUIDs = self.advertisements[CBAdvertisementDataSolicitedServiceUUIDsKey] {
            return serviceUUIDs as? [CBUUID]
        } else {
            return nil
        }
    }
    
    // PeripheralWrappable
    
    // peripheral services
    public func service(uuid:CBUUID) -> Service? {
        return self.discoveredServices[uuid]
    }
    
    // rssi
    func readRSSI() -> Future<Int> {
        CentralQueue.sync {
            self.readRSSIPromise = Promise<Int>()
        }
        return self.readRSSIPromise.future
    }
    
    // connect
    public func reconnect() {
        if self.state == .Disconnected {
            Logger.debug("reconnect peripheral \(self.name)")
            self.central.connectPeripheral(self)
            self.forcedDisconnect = false
            ++self.connectionSequence
            self.timeoutConnection(self.connectionSequence)
        }
    }
     
    public func connect(capacity:Int? = nil, timeoutRetries:UInt? = nil, disconnectRetries:UInt? = nil, connectionTimeout:Double = 10.0) -> FutureStream<(Peripheral, ConnectionEvent)> {
        self.connectionPromise = StreamPromise<(Peripheral, ConnectionEvent)>(capacity:capacity)
        self.timeoutRetries = timeoutRetries
        self.disconnectRetries = disconnectRetries
        self.connectionTimeout = connectionTimeout
        Logger.debug("connect peripheral \(self.name)")
        self.reconnect()
        return self.connectionPromise!.future
    }
    
    public func disconnect() {
        self.central.discoveredPeripherals.removeValueForKey(self.cbPeripheral)
        self.forcedDisconnect = true
        if self.state == .Connected {
            Logger.debug("disconnect peripheral \(self.name)")
            self.central.cancelPeripheralConnection(self)
        } else {
            self.didDisconnectPeripheral()
        }
    }
    
    public func terminate() {
        self.disconnect()
    }

    // service discovery
    public func discoverServices(services:[CBUUID]?) -> Future<Peripheral> {
        Logger.debug(" \(self.name)")
        CentralQueue.sync {
            self.servicesDiscoveredPromise = Promise<Peripheral>()
            self.discoverIfConnected(services)
        }
        return self.servicesDiscoveredPromise.future
    }
    
    public func discoverAllServices() -> Future<Peripheral> {
        Logger.debug("peripheral name \(self.name)")
        return self.discoverServices(nil)
    }

    public func discoverAllPeripheralServices() -> Future<Peripheral> {
        return self.discoverPeripheralServices(nil)
    }

    public func discoverPeripheralServices(services:[CBUUID]?) -> Future<Peripheral> {
        let peripheralDiscoveredPromise = Promise<Peripheral>()
        Logger.debug("peripheral name \(self.name)")
        let servicesDiscoveredFuture = self.discoverServices(services)
        servicesDiscoveredFuture.onSuccess {_ in
            if self.services.count > 1 {
                self.discoverService(self.services[0],tail:Array(self.services[1..<self.services.count]), promise:peripheralDiscoveredPromise)
            } else {
                if self.services.count > 0 {
                    let discoveryFuture = self.services[0].discoverAllCharacteristics()
                    discoveryFuture.onSuccess {_ in
                        peripheralDiscoveredPromise.success(self)
                    }
                    discoveryFuture.onFailure {error in
                        peripheralDiscoveredPromise.failure(error)
                    }
                } else {
                    peripheralDiscoveredPromise.failure(BCError.peripheralNoServices)
                }
            }
        }
        servicesDiscoveredFuture.onFailure{(error) in
            peripheralDiscoveredPromise.failure(error)
        }
        return peripheralDiscoveredPromise.future
    }

    // CBPeripheralDelegate
    // peripheral
    public func peripheralDidUpdateName(_:CBPeripheral) {
        Logger.debug()
    }
    
    public func peripheral(_:CBPeripheral, didModifyServices invalidatedServices:[CBService]) {
        Logger.debug()
    }
    
    public func peripheral(_:CBPeripheral, didReadRSSI RSSI:NSNumber, error:NSError?) {
        Logger.debug()
        if let error = error {
            self.readRSSIPromise.failure(error)
        } else {
            self.readRSSIPromise.success(RSSI.integerValue)
        }
    }
    
    // services
    public func peripheral(peripheral:CBPeripheral, didDiscoverServices error:NSError?) {
        Logger.debug("peripheral name \(self.name)")
        self.clearAll()
        if let error = error {
            self.servicesDiscoveredPromise.failure(error)
        } else {
            self.didDiscoverServices()
            self.servicesDiscoveredPromise.success(self)
        }
    }
    
    public func peripheral(_:CBPeripheral, didDiscoverIncludedServicesForService service:CBService, error:NSError?) {
        Logger.debug("peripheral name \(self.name)")
    }
    
    // characteristics
    public func peripheral(_:CBPeripheral, didDiscoverCharacteristicsForService service:CBService, error:NSError?) {
        Logger.debug("peripheral name \(self.name)")
        if let bcService = self.discoveredServices[service.UUID], cbCharacteristics = service.characteristics {
            bcService.didDiscoverCharacteristics(error)
            if error == nil {
                for characteristic : AnyObject in cbCharacteristics {
                    if let cbCharacteristic = characteristic as? CBCharacteristic {
                        self.discoveredCharacteristics[cbCharacteristic] = bcService.discoveredCharacteristics[characteristic.UUID]
                    }
                }
            }
        }
    }
    
    public func peripheral(_:CBPeripheral, didUpdateNotificationStateForCharacteristic characteristic:CBCharacteristic, error:NSError?) {
        Logger.debug()
        if let bcCharacteristic = self.discoveredCharacteristics[characteristic] {
            Logger.debug("uuid=\(bcCharacteristic.uuid.UUIDString), name=\(bcCharacteristic.name)")
            bcCharacteristic.didUpdateNotificationState(error)
        }
    }

    public func peripheral(_:CBPeripheral, didUpdateValueForCharacteristic characteristic:CBCharacteristic, error:NSError?) {
        Logger.debug()
        if let bcCharacteristic = self.discoveredCharacteristics[characteristic] {
            Logger.debug("uuid=\(bcCharacteristic.uuid.UUIDString), name=\(bcCharacteristic.name)")
            bcCharacteristic.didUpdate(error)
        }
    }

    public func peripheral(_:CBPeripheral, didWriteValueForCharacteristic characteristic:CBCharacteristic, error: NSError?) {
        Logger.debug()
        if let bcCharacteristic = self.discoveredCharacteristics[characteristic] {
            Logger.debug("uuid=\(bcCharacteristic.uuid.UUIDString), name=\(bcCharacteristic.name)")
            bcCharacteristic.didWrite(error)
        }
    }
    
    // descriptors
    public func peripheral(_:CBPeripheral, didDiscoverDescriptorsForCharacteristic characteristic:CBCharacteristic, error:NSError?) {
        Logger.debug()
    }
    
    public func peripheral(_:CBPeripheral, didUpdateValueForDescriptor descriptor:CBDescriptor, error:NSError?) {
        Logger.debug()
    }
    
    public func peripheral(_:CBPeripheral, didWriteValueForDescriptor descriptor:CBDescriptor, error:NSError?) {
        Logger.debug()
    }
    
    internal init(cbPeripheral:CBPeripheral, central:CentralManager, advertisements:[String:AnyObject], rssi:Int) {
        self.cbPeripheral = cbPeripheral
        self.advertisements = advertisements
        self.central = central
        self.rssi = rssi
        super.init()
        self.cbPeripheral.delegate = self
    }    
    
    internal func didDiscoverServices() {
        if let cbServices = self.cbPeripheral.services {
            for cbService : AnyObject in cbServices {
                if let cbService = cbService as? CBService {
                    let bcService = Service(cbService:cbService, peripheral:self)
                    self.discoveredServices[bcService.uuid] = bcService
                    Logger.debug("uuid=\(bcService.uuid.UUIDString), name=\(bcService.name)")
                }
            }
        }
    }

    internal func didDisconnectPeripheral() {
        Logger.debug()
        self._disconnectedAt = NSDate()
        if (self.forcedDisconnect) {
            self.forcedDisconnect = false
            Logger.debug("forced disconnect")
            self.connectionPromise?.success((self, ConnectionEvent.ForceDisconnect))
        } else {
            switch(self.currentError) {
            case .None:
                Logger.debug("no errors disconnecting")
                self.callDidDisconnect()
            case .Timeout:
                Logger.debug("timeout reconnecting")
                self.callDidTimeout()
            case .Unknown:
                Logger.debug("unknown error")
            }
        }
    }

    internal func didConnectPeripheral() {
        Logger.debug()
        self._connectedAt = NSDate()
        self.connectionPromise?.success((self, ConnectionEvent.Connect))
    }
    
    internal func didFailToConnectPeripheral(error:NSError?) {
        if let error = error {
            Logger.debug("connection failed for \(self.name) with error:'\(error.localizedDescription)'")
            self.currentError = .Unknown
            self.connectionPromise?.failure(error)
            if let disconnectRetries = self.disconnectRetries {
                if self.disconnectCount < disconnectRetries {
                    ++self.disconnectCount
                } else {
                    self.disconnectCount = 0
                    self.connectionPromise?.success((self, ConnectionEvent.GiveUp))
                }
            }
        } else {
            Logger.debug("connection success")
            self.connectionPromise?.success((self, ConnectionEvent.Failed))
        }
    }
    
    internal func callDidTimeout() {
        Logger.debug()
        if let timeoutRetries = self.timeoutRetries {
            if self.timeoutCount < timeoutRetries {
                self.connectionPromise?.success((self, ConnectionEvent.Timeout))
                ++self.timeoutCount
            } else {
                self.timeoutCount = 0
                self.connectionPromise?.success((self, ConnectionEvent.GiveUp))
            }
        } else {
            self.connectionPromise?.success((self, ConnectionEvent.Timeout))
        }
    }
    
    internal func callDidDisconnect() {
        Logger.debug()
        if let disconnectRetries = self.disconnectRetries {
            if self.disconnectCount < disconnectRetries {
                ++self.disconnectCount
                self.connectionPromise?.success((self, ConnectionEvent.Disconnect))
            } else {
                self.disconnectCount = 0
                self.connectionPromise?.success((self, ConnectionEvent.GiveUp))
            }
        } else {
            self.connectionPromise?.success((self, ConnectionEvent.Disconnect))
        }
    }
    
    private func discoverIfConnected(services:[CBUUID]?) {
        if self.state == .Connected {
            self.cbPeripheral.discoverServices(services)
        } else {
            self.servicesDiscoveredPromise.failure(BCError.peripheralDisconnected)
        }
    }

    private func discoverService(head:Service, tail:[Service], promise:Promise<Peripheral>) {
        let discoveryFuture = head.discoverAllCharacteristics()
        Logger.debug("service name \(head.name) count \(tail.count + 1)")
        if tail.count > 0 {
            discoveryFuture.onSuccess {_ in
                self.discoverService(tail[0], tail:Array(tail[1..<tail.count]), promise:promise)
            }
        } else {
            discoveryFuture.onSuccess {_ in
                promise.success(self)
            }
        }
        discoveryFuture.onFailure {error in
            promise.failure(error)
        }
    }

    private func timeoutConnection(sequence:Int) {
        Logger.debug("sequence \(sequence), timeout:\(self.connectionTimeout)")
        CentralQueue.delay(self.connectionTimeout) {
            if self.state != .Connected && sequence == self.connectionSequence && !self.forcedDisconnect {
                Logger.debug("timing out sequence=\(sequence), current connectionSequence=\(self.connectionSequence)")
                self.currentError = .Timeout
                self.central.cancelPeripheralConnection(self)
            } else {
                Logger.debug()
            }
        }
    }

    private func clearAll() {
        self.discoveredServices.removeAll()
        self.discoveredCharacteristics.removeAll()
    }
    
}
