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
    case None
    case Timeout
}

public enum ConnectionEvent {
    case Connect, Timeout, Disconnect, ForceDisconnect, Failed, GiveUp
}

///////////////////////////////////////////
// PeripheralImpl
public protocol PeripheralWrappable {
    
    typealias WrappedService
    
    var name            : String                {get}
    var state           : CBPeripheralState     {get}
    var services        : [WrappedService]      {get}
    
    func connect()
    func reconnect()
    func cancel()
    func terminate()
    func disconnect()
    func discoverServices(services:[CBUUID]?)
    func didDiscoverServices()
}

public class PeripheralImpl<Wrapper where Wrapper:PeripheralWrappable,
                                          Wrapper.WrappedService:ServiceWrappable> {
    
    private var timeoutCount    : UInt = 0
    private var disconnectCount : UInt = 0
    
    private var connectionPromise : StreamPromise<(Wrapper, ConnectionEvent)>?
    private var servicesDiscoveredPromise   = Promise<Wrapper>()
    private var readRSSIPromise             = Promise<Int>()
    
    internal var timeoutRetries         : UInt?
    internal var disconnectRetries      : UInt?
    internal var connectionTimeout      = 10.0
    
    private var connectionSequence      = 0
    private var currentError            = PeripheralConnectionError.None
    private var forcedDisconnect        = false
    
    private let _discoveredAt           = NSDate()
    private var _connectedAt            : NSDate?
    private var _disconnectedAt         : NSDate?
    
    public var discoveredAt : NSDate {
        return self._discoveredAt
    }
    
    public var connectedAt : NSDate? {
        return self._connectedAt
    }
    
    public var disconnectedAt : NSDate? {
        return self._disconnectedAt
    }
    
    public init() {
    }
    
    // connect  (Called on User queue)
    public func reconnect(peripheral:Wrapper) {
        if peripheral.state == .Disconnected {
            Logger.debug("reconnect peripheral \(peripheral.name)")
            peripheral.connect()
            self.forcedDisconnect = false
            ++self.connectionSequence
            self.timeoutConnection(peripheral, sequence:self.connectionSequence)
        }
    }
    
    public func connect(peripheral:Wrapper, capacity:Int? = nil, timeoutRetries:UInt? = nil, disconnectRetries:UInt? = nil, connectionTimeout:Double = 10.0) -> FutureStream<(Wrapper, ConnectionEvent)> {
        self.connectionPromise = StreamPromise<(Wrapper, ConnectionEvent)>(capacity:capacity)
        self.timeoutRetries = timeoutRetries
        self.disconnectRetries = disconnectRetries
        self.connectionTimeout = connectionTimeout
        Logger.debug("connect peripheral \(peripheral.name)")
        self.reconnect(peripheral)
        return self.connectionPromise!.future
    }
    
    public func disconnect(peripheral:Wrapper) {
        self.forcedDisconnect = true
        if peripheral.state == .Connected {
            Logger.debug("disconnect peripheral \(peripheral.name)")
            peripheral.cancel()
        } else {
            self.didDisconnectPeripheral(peripheral)
        }
    }
    
    public func terminate(peripheral:Wrapper) {
        self.disconnect(peripheral)
    }
    
    // service discovery (Called on Central queue)
    public func discoverAllServices(peripheral:Wrapper) -> Future<Wrapper> {
        Logger.debug("peripheral name \(peripheral.name)")
        return self.discoverServices(peripheral, services:nil)
    }
    
    public func discoverServices(peripheral:Wrapper, services:[CBUUID]?) -> Future<Wrapper> {
        Logger.debug(" \(peripheral.name)")
        CentralQueue.sync {
            self.servicesDiscoveredPromise = Promise<Wrapper>()
            self.discoverIfConnected(peripheral, services:services)
        }
        return self.servicesDiscoveredPromise.future
    }
    
    public func discoverAllPeripheralServices(peripheral:Wrapper) -> Future<Wrapper> {
        Logger.debug("peripheral name \(peripheral.name)")
        return self.discoverPeripheralServices(peripheral, services:nil)
    }
    
    public func discoverPeripheralServices(peripheral:Wrapper, services:[CBUUID]?) -> Future<Wrapper> {
        let peripheralDiscoveredPromise = Promise<Wrapper>()
        Logger.debug("peripheral name \(peripheral.name)")
        let servicesDiscoveredFuture = self.discoverServices(peripheral, services:services)
        servicesDiscoveredFuture.onSuccess {_ in
            if peripheral.services.count > 1 {
                self.discoverService(peripheral,
                                     head:peripheral.services[0],
                                     tail:Array(peripheral.services[1..<peripheral.services.count]),
                                     promise:peripheralDiscoveredPromise)
            } else {
                if peripheral.services.count > 0 {
                    let discoveryFuture = peripheral.services[0].discoverAllCharacteristics()
                    discoveryFuture.onSuccess {_ in
                        peripheralDiscoveredPromise.success(peripheral)
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
    
    // RSSI
    public func readRSSI() -> Future<Int> {
        CentralQueue.sync {
            self.readRSSIPromise = Promise<Int>()
        }
        return self.readRSSIPromise.future
    }
    
    // CBPeripheralDelegate
    // services
    public func didDiscoverServices(peripheral:Wrapper, error:NSError?) {
        Logger.debug("peripheral name \(peripheral.name)")
        if let error = error {
            self.servicesDiscoveredPromise.failure(error)
        } else {
            peripheral.didDiscoverServices()
            self.servicesDiscoveredPromise.success(peripheral)
        }
    }
    
    public func didReadRSSI(RSSI:NSNumber, error:NSError?) {
        if let error = error {
            self.readRSSIPromise.failure(error)
        } else {
            self.readRSSIPromise.success(RSSI.integerValue)
        }
    }

    private func discoverIfConnected(peripheral:Wrapper, services:[CBUUID]?) {
        if peripheral.state == .Connected {
            peripheral.discoverServices(services)
        } else {
            self.servicesDiscoveredPromise.failure(BCError.peripheralDisconnected)
        }
    }
    
    // connection events
    private func timeoutConnection(peripheral:Wrapper, sequence:Int) {
        Logger.debug("sequence \(sequence), timeout:\(self.connectionTimeout)")
        CentralQueue.delay(self.connectionTimeout) {
            if peripheral.state != .Connected && sequence == self.connectionSequence && !self.forcedDisconnect {
                Logger.debug("timing out sequence=\(sequence), current connectionSequence=\(self.connectionSequence)")
                self.currentError = .Timeout
                peripheral.cancel()
            } else {
                Logger.debug()
            }
        }
    }
    
    public func didDisconnectPeripheral(peripheral:Wrapper) {
        Logger.debug()
        self._disconnectedAt = NSDate()
        if (self.forcedDisconnect) {
            self.forcedDisconnect = false
            Logger.debug("forced disconnect")
            self.connectionPromise?.success((peripheral, ConnectionEvent.ForceDisconnect))
        } else {
            switch(self.currentError) {
            case .None:
                Logger.debug("no errors disconnecting")
                self.callDidDisconnect(peripheral)
            case .Timeout:
                Logger.debug("timeout reconnecting")
                self.callDidTimeout(peripheral)
            }
        }
    }
    
    public func didConnectPeripheral(peripheral:Wrapper) {
        Logger.debug()
        self._connectedAt = NSDate()
        self.connectionPromise?.success((peripheral, ConnectionEvent.Connect))
    }
    
    public func didFailToConnectPeripheral(peripheral:Wrapper, error:NSError?) {
        if let error = error {
            Logger.debug("connection failed '\(error.localizedDescription)'")
            self.connectionPromise?.failure(error)
        } else {
            Logger.debug("connection success")
            self.connectionPromise?.success((peripheral, ConnectionEvent.Failed))
        }
    }
    
    internal func discoverService(peripheral:Wrapper, head:Wrapper.WrappedService, tail:[Wrapper.WrappedService], promise:Promise<Wrapper>) {
        let discoveryFuture = head.discoverAllCharacteristics()
        Logger.debug("service name \(head.name) count \(tail.count + 1)")
        if tail.count > 0 {
            discoveryFuture.onSuccess {_ in
                self.discoverService(peripheral, head:tail[0], tail:Array(tail[1..<tail.count]), promise:promise)
            }
        } else {
            discoveryFuture.onSuccess {_ in
                promise.success(peripheral)
            }
        }
        discoveryFuture.onFailure {error in
            promise.failure(error)
        }
    }

    internal func callDidTimeout(peripheral:Wrapper) {
        Logger.debug()
        if let timeoutRetries = self.timeoutRetries {
            if self.timeoutCount < timeoutRetries {
                self.connectionPromise?.success((peripheral, ConnectionEvent.Timeout))
                ++self.timeoutCount
            } else {
                self.timeoutCount = 0
                self.connectionPromise?.success((peripheral, ConnectionEvent.GiveUp))
            }
        } else {
            self.connectionPromise?.success((peripheral, ConnectionEvent.Timeout))
        }
    }
    
    internal func callDidDisconnect(peripheral:Wrapper) {
        Logger.debug()
        if let disconnectRetries = self.disconnectRetries {
            if self.disconnectCount < disconnectRetries {
                ++self.disconnectCount
                self.connectionPromise?.success((peripheral, ConnectionEvent.Disconnect))
            } else {
                self.disconnectCount = 0
                self.connectionPromise?.success((peripheral, ConnectionEvent.GiveUp))
            }
        } else {
            self.connectionPromise?.success((peripheral, ConnectionEvent.Disconnect))
        }
    }
    
}
// PeripheralImpl
///////////////////////////////////////////

public class Peripheral : NSObject, CBPeripheralDelegate, PeripheralWrappable {
    
    internal var impl = PeripheralImpl<Peripheral>()
    
    // PeripheralWrappable
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
    
    public func connect() {
        CentralManager.sharedInstance.connectPeripheral(self)
    }
    
    public func cancel() {
        CentralManager.sharedInstance.cancelPeripheralConnection(self)
    }
    
    public func disconnect() {
        CentralManager.sharedInstance.discoveredPeripherals.removeValueForKey(self.cbPeripheral)
        self.impl.disconnect(self)
    }
    
    public func discoverServices(services:[CBUUID]?) {
        self.cbPeripheral.discoverServices(services)
    }
    
    public func didDiscoverServices() {
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
    // PeripheralWrappable
    
    private var discoveredServices          = [CBUUID:Service]()
    private var discoveredCharacteristics   = [CBCharacteristic:Characteristic]()
    
    internal let cbPeripheral   : CBPeripheral
    
    public let advertisements   : [String: String]
    public let rssi             : Int
    
    public var discoveredAt : NSDate {
        return self.impl.discoveredAt
    }
    
    public var connectedAt : NSDate? {
        return self.impl.connectedAt
    }

    public var disconnectedAt : NSDate? {
        return self.impl.disconnectedAt
    }

    public var identifier : NSUUID {
        return self.cbPeripheral.identifier
    }
    
    internal init(cbPeripheral:CBPeripheral, advertisements:[String:String], rssi:Int) {
        self.cbPeripheral = cbPeripheral
        self.advertisements = advertisements
        self.rssi = rssi
        super.init()
        self.cbPeripheral.delegate = self
    }
    
    public func service(uuid:CBUUID) -> Service? {
        return self.discoveredServices[uuid]
    }

    // rssi
    func readRSSI() -> Future<Int> {
        self.cbPeripheral.readRSSI()
        return self.impl.readRSSI()
    }
    
    // connect
    public func reconnect() {
        self.impl.reconnect(self)
    }
     
    public func connect(capacity:Int? = nil, timeoutRetries:UInt? = nil, disconnectRetries:UInt? = nil, connectionTimeout:Double = 10.0) -> FutureStream<(Peripheral, ConnectionEvent)> {
        return self.impl.connect(self, capacity:capacity, timeoutRetries:timeoutRetries, disconnectRetries:disconnectRetries, connectionTimeout:connectionTimeout)
    }
    
    public func terminate() {
        self.disconnect()
    }

    // service discovery
    public func discoverAllServices() -> Future<Peripheral> {
        return self.impl.discoverAllServices(self)
    }

    public func discoverServices(services:[CBUUID]?) -> Future<Peripheral> {
        return self.impl.discoverServices(self, services:services)
    }

    public func discoverAllPeripheralServices() -> Future<Peripheral> {
        return self.impl.discoverAllPeripheralServices(self)
    }

    public func discoverPeripheralServices(services:[CBUUID]?) -> Future<Peripheral> {
        return self.impl.discoverPeripheralServices(self, services:services)
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
        self.impl.didReadRSSI(RSSI, error:error)
    }
    
    // services
    public func peripheral(peripheral:CBPeripheral, didDiscoverServices error:NSError?) {
        Logger.debug("peripheral name \(self.name)")
        self.clearAll()
        self.impl.didDiscoverServices(self, error:error)
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
    
    // utils
    private func clearAll() {
        self.discoveredServices.removeAll()
        self.discoveredCharacteristics.removeAll()
    }
    
    internal func didDisconnectPeripheral() {
        self.impl.didDisconnectPeripheral(self)
    }

    internal func didConnectPeripheral() {
        self.impl.didConnectPeripheral(self)
    }
    
    internal func didFailToConnectPeripheral(error:NSError?) {
        self.impl.didFailToConnectPeripheral(self, error:error)
    }
    
}
