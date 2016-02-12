//
//  BCPeripheral.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/8/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import Foundation
import CoreBluetooth

// MARK - Connection Error -
enum PeripheralConnectionError {
    case None, Timeout, Unknown
}

public enum BCConnectionEvent {
    case Connect, Timeout, Disconnect, ForceDisconnect, Failed, GiveUp
}

// MARK: - CBPeripheralInjectable -
public protocol CBPeripheralInjectable {
    var name : String?                      {get}
    var state : CBPeripheralState           {get}
    var identifier : NSUUID                 {get}
    var delegate : CBPeripheralDelegate?    {get set}
    var services : [CBService]?             {get}
    
    func discoverServices(services:[CBUUID]?)
    func discoverCharacteristics(characteristics:[CBUUID]?, forService:CBService)
    func setNotifyValue(state:Bool, forCharacteristic:CBCharacteristic)
    func readValueForCharacteristic(characteristic:CBCharacteristic)
    func writeValue(data:NSData, forCharacteristic:CBCharacteristic, type:CBCharacteristicWriteType)
}

extension CBPeripheral : CBPeripheralInjectable {}

// MARK: - BCPeripheralAdvertisements -
public struct BCPeripheralAdvertisements {
    
    let advertisements : [String: AnyObject]
    
    public var localName : String? {
        if let localname = self.advertisements[CBAdvertisementDataLocalNameKey] {
            return localname as? String
        } else {
            return nil
        }
    }
    
    public var manufactuereData : NSData? {
        if let mfgData = self.advertisements[CBAdvertisementDataManufacturerDataKey] {
            return mfgData as? NSData
        } else {
            return nil;
        }
    }
    
    public var txPower : NSNumber? {
        if let txPower = self.advertisements[CBAdvertisementDataTxPowerLevelKey] {
            return txPower as? NSNumber
        } else {
            return nil
        }
    }
    
    public var isConnectable : NSNumber? {
        if let isConnectable = self.advertisements[CBAdvertisementDataIsConnectable] {
            return isConnectable as? NSNumber
        } else {
            return nil
        }
    }
    
    public var serviceUUIDs : [CBUUID]? {
        if let serviceUUIDs = self.advertisements[CBAdvertisementDataServiceUUIDsKey] {
            return serviceUUIDs as? [CBUUID]
        } else {
            return nil
        }
    }
    
    public var serviceData : [CBUUID:NSData]? {
        if let serviceData = self.advertisements[CBAdvertisementDataServiceDataKey] {
            return serviceData as? [CBUUID:NSData]
        } else {
            return nil
        }
    }
    
    public var overflowServiceUUIDs : [CBUUID]? {
        if let serviceUUIDs = self.advertisements[CBAdvertisementDataOverflowServiceUUIDsKey] {
            return serviceUUIDs as? [CBUUID]
        } else {
            return nil
        }
    }
    
    public var solicitedServiceUUIDs : [CBUUID]? {
        if let serviceUUIDs = self.advertisements[CBAdvertisementDataSolicitedServiceUUIDsKey] {
            return serviceUUIDs as? [CBUUID]
        } else {
            return nil
        }
    }    
}

// MARK: - BCPeripheral -
public class BCPeripheral : NSObject, CBPeripheralDelegate {

    // MARK: Serialize Property IO
    static let ioQueue      = Queue("us.gnos.blueCap.peripheral.io")
    static let timeoutQueue = Queue("us.gnos.blueCap.peripheral.timeout")

    // MARK: Properties
    private var _servicesDiscoveredPromise: Promise<BCPeripheral>?
    private var _readRSSIPromise: Promise<Int>?

    private var _connectionPromise: StreamPromise<(peripheral: BCPeripheral, connectionEvent: BCConnectionEvent)>?

    private var _timeoutCount: UInt         = 0
    private var _disconnectCount: UInt      = 0
    
    private var _connectionSequence         = 0
    private var _currentError               = PeripheralConnectionError.None
    private var _forcedDisconnect           = false

    private let _discoveredAt               = NSDate()
    private var _connectedAt: NSDate?
    private var _disconnectedAt : NSDate?
    
    private var discoveredServices          = BCSerialIODictionary<CBUUID, BCService>(BCPeripheral.ioQueue)
    private var discoveredCharacteristics   = BCSerialIODictionary<CBUUID, BCCharacteristic>(BCPeripheral.ioQueue)

    internal var connectionTimeout          = 10.0
    internal var timeoutRetries: UInt?
    internal var disconnectRetries: UInt?
    internal weak var centralManager: BCCentralManager?
    
    public let cbPeripheral: CBPeripheralInjectable
    public let advertisements: BCPeripheralAdvertisements?
    public let rssi: Int

    // MARK: Serial Properties
    private var servicesDiscoveredPromise: Promise<BCPeripheral>? {
        get {
            return BCPeripheral.ioQueue.sync { return self._servicesDiscoveredPromise }
        }
        set {
            self._servicesDiscoveredPromise = newValue
        }
    }

    private var readRSSIPromise: Promise<Int>? {
        get {
            return BCPeripheral.ioQueue.sync { return self._readRSSIPromise }
        }
        set {
            BCPeripheral.ioQueue.sync { self._readRSSIPromise = newValue }
        }
    }

    private var connectionPromise: StreamPromise<(peripheral: BCPeripheral, connectionEvent: BCConnectionEvent)>? {
        get {
            return BCPeripheral.ioQueue.sync { return self._connectionPromise }
        }
        set {
            BCPeripheral.ioQueue.sync { self._connectionPromise = newValue }
        }
    }

    private var timeoutCount: UInt {
        get {
            return BCPeripheral.ioQueue.sync  { return self._timeoutCount }
        }
        set {
            BCPeripheral.ioQueue.sync { self._timeoutCount = newValue }
        }
    }

    private var disconnectCount: UInt {
        get {
            return BCPeripheral.ioQueue.sync { return self._disconnectCount }
        }
        set {
            BCPeripheral.ioQueue.sync { self._disconnectCount = newValue }
        }
    }

    private var connectionSequence: Int {
        get {
            return BCPeripheral.ioQueue.sync { return self._connectionSequence }
        }
        set {
            BCPeripheral.ioQueue.sync { self._connectionSequence = newValue }
        }
    }

    private var currentError: PeripheralConnectionError {
        get {
            return BCPeripheral.ioQueue.sync { return self._currentError }
        }
        set {
            BCPeripheral.ioQueue.sync { self._currentError = newValue }
        }
    }

    private var forcedDisconnect: Bool {
        get {
            return BCPeripheral.ioQueue.sync { return self._forcedDisconnect }
        }
        set {
            BCPeripheral.ioQueue.sync { self._forcedDisconnect = newValue }
        }
    }

    // MARK: Public Properties
    public var discoveredAt: NSDate {
        return self._discoveredAt
    }
    
    public var connectedAt: NSDate? {
        return self._connectedAt
    }
    
    public var disconnectedAt: NSDate? {
        return self._disconnectedAt
    }
    
    public var name: String {
        if let name = self.cbPeripheral.name {
            return name
        } else {
            return "Unknown"
        }
    }

    public var state: CBPeripheralState {
        return self.cbPeripheral.state
    }
    
    public var services: [BCService] {
        return Array(self.discoveredServices.values)
    }
    
    public var identifier: NSUUID {
        return self.cbPeripheral.identifier
    }

    public func service(uuid: CBUUID) -> BCService? {
        return self.discoveredServices[uuid]
    }

    // MARK: Initializers
    public init(cbPeripheral: CBPeripheralInjectable, centralManager: BCCentralManager, advertisements: [String:AnyObject], rssi: Int) {
        self.cbPeripheral = cbPeripheral
        self.advertisements = BCPeripheralAdvertisements(advertisements: advertisements)
        self.centralManager = centralManager
        self.rssi = rssi
        super.init()
        self.cbPeripheral.delegate = self
    }

    public init(cbPeripheral: CBPeripheralInjectable, centralManager: BCCentralManager) {
        self.cbPeripheral = cbPeripheral
        self.centralManager = centralManager
        self.rssi = 0
        super.init()
        self.cbPeripheral.delegate = self
    }

    // MARK: Connection
    func readRSSI() -> Future<Int> {
        self.readRSSIPromise = Promise<Int>()
        return self.readRSSIPromise!.future
    }
    
    public func reconnect() {
        if let centralManager = self.centralManager where self.state == .Disconnected {
            BCLogger.debug("reconnect peripheral \(self.name)")
            centralManager.connectPeripheral(self)
            self.forcedDisconnect = false
            ++self.connectionSequence
            self.timeoutConnection(self.connectionSequence)
        }
    }
     
    public func connect(capacity: Int? = nil, timeoutRetries: UInt? = nil, disconnectRetries: UInt? = nil, connectionTimeout: Double = 10.0) -> FutureStream<(peripheral: BCPeripheral, connectionEvent: BCConnectionEvent)> {
        self.connectionPromise = StreamPromise<(peripheral: BCPeripheral, connectionEvent: BCConnectionEvent)>(capacity:capacity)
        self.timeoutRetries = timeoutRetries
        self.disconnectRetries = disconnectRetries
        self.connectionTimeout = connectionTimeout
        BCLogger.debug("connect peripheral \(self.name)")
        self.reconnect()
        return self.connectionPromise!.future
    }
    
    public func disconnect() {
        if let central = self.centralManager {
            central.discoveredPeripherals.removeValueForKey(self.cbPeripheral.identifier)
            self.forcedDisconnect = true
            if self.state == .Connected {
                BCLogger.debug("disconnect peripheral \(self.name)")
                central.cancelPeripheralConnection(self)
            } else {
                self.didDisconnectPeripheral()
            }
        }
    }
    
    public func terminate() {
        self.disconnect()
    }

    // MARK: Discover Services
    public func discoverServices(services: [CBUUID]?) -> Future<BCPeripheral> {
        BCLogger.debug(" \(self.name)")
        self.servicesDiscoveredPromise = Promise<BCPeripheral>()
        self.discoverIfConnected(services)
        return self.servicesDiscoveredPromise!.future
    }
    
    public func discoverAllServices() -> Future<BCPeripheral> {
        BCLogger.debug("peripheral name \(self.name)")
        return self.discoverServices(nil)
    }

    public func discoverAllPeripheralServices() -> Future<BCPeripheral> {
        return self.discoverPeripheralServices(nil)
    }

    public func discoverPeripheralServices(services: [CBUUID]?) -> Future<BCPeripheral> {
        let peripheralDiscoveredPromise = Promise<BCPeripheral>()
        BCLogger.debug("peripheral name \(self.name)")
        let servicesDiscoveredFuture = self.discoverServices(services)
        servicesDiscoveredFuture.onSuccess {_ in
            if self.services.count > 1 {
                self.discoverService(self.services[0], tail:Array(self.services[1..<self.services.count]), promise: peripheralDiscoveredPromise)
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
        servicesDiscoveredFuture.onFailure {(error) in
            peripheralDiscoveredPromise.failure(error)
        }
        return peripheralDiscoveredPromise.future
    }
    
    public func discoverService(head: BCService, tail: [BCService], promise: Promise<BCPeripheral>) {
        let discoveryFuture = head.discoverAllCharacteristics()
        BCLogger.debug("service name \(head.name) count \(tail.count + 1)")
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

    // MARK: CBPeripheralDelegate
    public func peripheralDidUpdateName(_:CBPeripheral) {
        BCLogger.debug()
    }
    
    public func peripheral(_: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        BCLogger.debug()
    }
    
    public func peripheral(_: CBPeripheral, didReadRSSI RSSI: NSNumber, error: NSError?) {
        self.didReadRSSI(RSSI, error:error)
    }
    
    public func peripheral(_: CBPeripheral, didDiscoverServices error: NSError?) {
        if let services = self.cbPeripheral.services {
            self.didDiscoverServices(services, error:error)
        }
    }
    
    public func peripheral(_: CBPeripheral, didDiscoverIncludedServicesForService service: CBService, error: NSError?) {
        BCLogger.debug("peripheral name \(self.name)")
    }
    
    public func peripheral(_: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        guard let characteristics = service.characteristics else {
            return
        }
        self.didDiscoverCharacteristicsForService(service, characteristics: characteristics, error: error)
    }

    public func peripheral(_: CBPeripheral, didUpdateNotificationStateForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        self.didUpdateNotificationStateForCharacteristic(characteristic, error:error)
    }

    public func peripheral(_: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        self.didUpdateValueForCharacteristic(characteristic, error:error)
    }

    public func peripheral(_: CBPeripheral, didWriteValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        self.didWriteValueForCharacteristic(characteristic, error:error)
    }

    public func peripheral(_: CBPeripheral, didDiscoverDescriptorsForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        BCLogger.debug()
    }
    
    public func peripheral(_: CBPeripheral, didUpdateValueForDescriptor descriptor: CBDescriptor, error: NSError?) {
        BCLogger.debug()
    }
    
    public func peripheral(_: CBPeripheral, didWriteValueForDescriptor descriptor: CBDescriptor, error: NSError?) {
        BCLogger.debug()
    }
    
    public func didDiscoverCharacteristicsForService(service: CBService, characteristics: [CBCharacteristic], error: NSError?) {
        BCLogger.debug("peripheral name \(self.name)")
        if let bcService = self.discoveredServices[service.UUID] {
            bcService.didDiscoverCharacteristics(characteristics, error:error)
            if error == nil {
                for cbCharacteristic in characteristics {
                    self.discoveredCharacteristics[cbCharacteristic.UUID] = bcService.discoveredCharacteristics[cbCharacteristic.UUID]
                }
            }
        }
    }
    
    public func didDiscoverServices(discoveredServices: [CBService], error: NSError?) {
        BCLogger.debug("peripheral name \(self.name)")
        self.clearAll()
        if let error = error {
            self.servicesDiscoveredPromise?.failure(error)
        } else {
            for service in discoveredServices {
                let bcService = BCService(cbService:service, peripheral:self)
                self.discoveredServices[bcService.uuid] = bcService
                BCLogger.debug("uuid=\(bcService.uuid.UUIDString), name=\(bcService.name)")
            }
            self.servicesDiscoveredPromise?.success(self)
        }
    }
    
    public func didUpdateNotificationStateForCharacteristic(characteristic: CBCharacteristic, error: NSError?) {
        BCLogger.debug()
        if let bcCharacteristic = self.discoveredCharacteristics[characteristic.UUID] {
            BCLogger.debug("uuid=\(bcCharacteristic.uuid.UUIDString), name=\(bcCharacteristic.name)")
            bcCharacteristic.didUpdateNotificationState(error)
        }
    }
    
    public func didUpdateValueForCharacteristic(characteristic: CBCharacteristic, error: NSError?) {
        BCLogger.debug()
        if let bcCharacteristic = self.discoveredCharacteristics[characteristic.UUID] {
            BCLogger.debug("uuid=\(bcCharacteristic.uuid.UUIDString), name=\(bcCharacteristic.name)")
            bcCharacteristic.didUpdate(error)
        }
    }
    
    public func didWriteValueForCharacteristic(characteristic: CBCharacteristic, error: NSError?) {
        BCLogger.debug()
        if let bcCharacteristic = self.discoveredCharacteristics[characteristic.UUID] {
            BCLogger.debug("uuid=\(bcCharacteristic.uuid.UUIDString), name=\(bcCharacteristic.name)")
            bcCharacteristic.didWrite(error)
        }
    }
    
    public func didDisconnectPeripheral() {
        BCLogger.debug()
        self._disconnectedAt = NSDate()
        if (self.forcedDisconnect) {
            self.forcedDisconnect = false
            BCLogger.debug("forced disconnect")
            self.connectionPromise?.success((self, .ForceDisconnect))
        } else {
            switch(self.currentError) {
            case .None:
                BCLogger.debug("no errors disconnecting")
                self.callDidDisconnect()
            case .Timeout:
                BCLogger.debug("timeout reconnecting")
                self.callDidTimeout()
            case .Unknown:
                BCLogger.debug("unknown error")
            }
        }
    }

    public func didConnectPeripheral() {
        BCLogger.debug()
        self._connectedAt = NSDate()
        self.connectionPromise?.success((self, .Connect))
    }
    
    public func didFailToConnectPeripheral(error: NSError?) {
        if let error = error {
            BCLogger.debug("connection failed for \(self.name) with error:'\(error.localizedDescription)'")
            self.currentError = .Unknown
            self.connectionPromise?.failure(error)
            if let disconnectRetries = self.disconnectRetries {
                if self.disconnectCount < disconnectRetries {
                    ++self.disconnectCount
                } else {
                    self.disconnectCount = 0
                    self.connectionPromise?.success((self, BCConnectionEvent.GiveUp))
                }
            }
        } else {
            BCLogger.debug("connection success")
            self.connectionPromise?.success((self, .Failed))
        }
    }
    
    internal func callDidTimeout() {
        BCLogger.debug()
        if let timeoutRetries = self.timeoutRetries {
            if self.timeoutCount < timeoutRetries {
                self.connectionPromise?.success((self, .Timeout))
                ++self.timeoutCount
            } else {
                self.timeoutCount = 0
                self.connectionPromise?.success((self, .GiveUp))
            }
        } else {
            self.connectionPromise?.success((self, .Timeout))
        }
    }
    
    internal func callDidDisconnect() {
        BCLogger.debug()
        if let disconnectRetries = self.disconnectRetries {
            if self.disconnectCount < disconnectRetries {
                ++self.disconnectCount
                self.connectionPromise?.success((self, .Disconnect))
            } else {
                self.disconnectCount = 0
                self.connectionPromise?.success((self, .GiveUp))
            }
        } else {
            self.connectionPromise?.success((self, .Disconnect))
        }
    }

    private func didReadRSSI(RSSI: NSNumber, error: NSError?) {
        BCLogger.debug()
        if let error = error {
            self.readRSSIPromise?.failure(error)
        } else {
            self.readRSSIPromise?.success(RSSI.integerValue)
        }
    }

    // MARK: CBPeripheral Delegation
    internal func setNotifyValue(state: Bool, forCharacteristic characteristic: BCCharacteristic) {
        self.cbPeripheral.setNotifyValue(state, forCharacteristic:characteristic.cbCharacteristic)
    }
    
    internal func readValueForCharacteristic(characteristic: BCCharacteristic) {
        self.cbPeripheral.readValueForCharacteristic(characteristic.cbCharacteristic)
    }
    
    internal func writeValue(value: NSData, forCharacteristic characteristic: BCCharacteristic, type: CBCharacteristicWriteType = .WithResponse) {
            self.cbPeripheral.writeValue(value, forCharacteristic:characteristic.cbCharacteristic, type:type)
    }
    
    internal func discoverCharacteristics(characteristics: [CBUUID]?, forService service: BCService) {
        self.cbPeripheral.discoverCharacteristics(characteristics, forService:service.cbService)
    }

    // MARK: Utilities
    private func discoverIfConnected(services: [CBUUID]?) {
        if self.state == .Connected {
            self.cbPeripheral.discoverServices(services)
        } else {
            self.servicesDiscoveredPromise?.failure(BCError.peripheralDisconnected)
        }
    }

    private func timeoutConnection(sequence: Int) {
        if let centralManager = self.centralManager {
            BCLogger.debug("sequence \(sequence), timeout:\(self.connectionTimeout)")
            BCPeripheral.timeoutQueue.delay(self.connectionTimeout) {
                if self.state != .Connected && sequence == self.connectionSequence && !self.forcedDisconnect {
                    BCLogger.debug("timing out sequence=\(sequence), current connectionSequence=\(self.connectionSequence)")
                    self.currentError = .Timeout
                    centralManager.cancelPeripheralConnection(self)
                } else {
                    BCLogger.debug()
                }
            }
        }
    }

    private func clearAll() {
        self.discoveredServices.removeAll()
        self.discoveredCharacteristics.removeAll()
    }
    
}
