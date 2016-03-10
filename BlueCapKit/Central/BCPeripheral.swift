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
    var name: String?                      { get }
    var state: CBPeripheralState           { get }
    var identifier: NSUUID                 { get }
    var delegate: CBPeripheralDelegate?    { get set }
    var services: [CBService]?             { get }

    func readRSSI()
    func discoverServices(services:[CBUUID]?)
    func discoverCharacteristics(characteristics:[CBUUID]?, forService:CBService)
    func setNotifyValue(state:Bool, forCharacteristic:CBCharacteristic)
    func readValueForCharacteristic(characteristic:CBCharacteristic)
    func writeValue(data:NSData, forCharacteristic:CBCharacteristic, type:CBCharacteristicWriteType)
}

extension CBPeripheral : CBPeripheralInjectable {}

// MARK: - BCPeripheralAdvertisements -
public struct BCPeripheralAdvertisements {
    
    let advertisements: [String: AnyObject]
    
    public var localName: String? {
        if let localname = self.advertisements[CBAdvertisementDataLocalNameKey] {
            return localname as? String
        } else {
            return nil
        }
    }
    
    public var manufactuereData: NSData? {
        if let mfgData = self.advertisements[CBAdvertisementDataManufacturerDataKey] {
            return mfgData as? NSData
        } else {
            return nil;
        }
    }
    
    public var txPower: NSNumber? {
        if let txPower = self.advertisements[CBAdvertisementDataTxPowerLevelKey] {
            return txPower as? NSNumber
        } else {
            return nil
        }
    }
    
    public var isConnectable: NSNumber? {
        if let isConnectable = self.advertisements[CBAdvertisementDataIsConnectable] {
            return isConnectable as? NSNumber
        } else {
            return nil
        }
    }
    
    public var serviceUUIDs: [CBUUID]? {
        if let serviceUUIDs = self.advertisements[CBAdvertisementDataServiceUUIDsKey] {
            return serviceUUIDs as? [CBUUID]
        } else {
            return nil
        }
    }
    
    public var serviceData: [CBUUID:NSData]? {
        if let serviceData = self.advertisements[CBAdvertisementDataServiceDataKey] {
            return serviceData as? [CBUUID:NSData]
        } else {
            return nil
        }
    }
    
    public var overflowServiceUUIDs: [CBUUID]? {
        if let serviceUUIDs = self.advertisements[CBAdvertisementDataOverflowServiceUUIDsKey] {
            return serviceUUIDs as? [CBUUID]
        } else {
            return nil
        }
    }
    
    public var solicitedServiceUUIDs: [CBUUID]? {
        if let serviceUUIDs = self.advertisements[CBAdvertisementDataSolicitedServiceUUIDsKey] {
            return serviceUUIDs as? [CBUUID]
        } else {
            return nil
        }
    }    
}

// MARK: - BCPeripheral -
public class BCPeripheral: NSObject, CBPeripheralDelegate {

    // MARK: Serialize Property IO
    static let ioQueue = Queue("us.gnos.blueCap.peripheral.io")
    static let timeoutQueue = Queue("us.gnos.blueCap.peripheral.timeout")
    static let rssiQueue = Queue("us.gnos.blueCap.peripheral.rssi")

    // MARK: Properties
    private var _servicesDiscoveredPromise: Promise<BCPeripheral>?
    private var _readRSSIPromise: Promise<Int>?
    private var _pollRSSIPromise: StreamPromise<Int>?

    private var _connectionPromise: StreamPromise<(peripheral: BCPeripheral, connectionEvent: BCConnectionEvent)>?

    private var _RSSI: Int = 0

    private var _timeoutCount: UInt = 0
    private var _disconnectCount: UInt = 0
    
    private var _connectionSequence = 0
    private var _secondsConnected = 0.0
    private var _numberOfConnections = 0
    private var _currentError = PeripheralConnectionError.None
    private var _forcedDisconnect = false

    private var _connectedAt: NSDate?
    private var _disconnectedAt : NSDate?
    
    internal var discoveredServices = BCSerialIODictionary<CBUUID, BCService>(BCPeripheral.ioQueue)
    internal var discoveredCharacteristics = BCSerialIODictionary<CBUUID, BCCharacteristic>(BCPeripheral.ioQueue)

    internal var connectionTimeout = 10.0
    internal var timeoutRetries: UInt?
    internal var disconnectRetries: UInt?
    internal weak var centralManager: BCCentralManager?
    
    public let discoveredAt = NSDate()
    public let cbPeripheral: CBPeripheralInjectable
    public let advertisements: BCPeripheralAdvertisements?

    // MARK: Serial Properties
    public var RSSI: Int {
        get {
            return BCPeripheral.ioQueue.sync { return self._RSSI }
        }
        set {
            BCPeripheral.ioQueue.sync { self._RSSI = newValue }
        }
    }

    private var servicesDiscoveredPromise: Promise<BCPeripheral>? {
        get {
            return BCPeripheral.ioQueue.sync { return self._servicesDiscoveredPromise }
        }
        set {
            BCPeripheral.ioQueue.sync { self._servicesDiscoveredPromise = newValue }
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

    private var pollRSSIPromise: StreamPromise<Int>? {
        get {
            return BCPeripheral.ioQueue.sync { return self._pollRSSIPromise }
        }
        set {
            BCPeripheral.ioQueue.sync { self._pollRSSIPromise = newValue }
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
    public var connectedAt: NSDate? {
        get {
            return BCPeripheral.ioQueue.sync { return self._connectedAt }
        }
        set {
            BCPeripheral.ioQueue.sync { self._connectedAt = newValue }
        }
    }
    
    public var disconnectedAt: NSDate? {
        get {
            return BCPeripheral.ioQueue.sync { return self._disconnectedAt }
        }
        set {
            BCPeripheral.ioQueue.sync { self._disconnectedAt = newValue }
        }
    }

    public var numberOfConnections: Int {
        get {
            return BCPeripheral.ioQueue.sync { return self._numberOfConnections }
        }
        set {
            BCPeripheral.ioQueue.sync { self._numberOfConnections = newValue }
        }
    }

    public var secondsConnected: Double {
        get {
            return BCPeripheral.ioQueue.sync { return self._secondsConnected }
        }
        set {
            BCPeripheral.ioQueue.sync { self._secondsConnected = newValue }
        }
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
    public init(cbPeripheral: CBPeripheralInjectable, centralManager: BCCentralManager, advertisements: [String:AnyObject], RSSI: Int) {
        self.cbPeripheral = cbPeripheral
        self.advertisements = BCPeripheralAdvertisements(advertisements: advertisements)
        self.centralManager = centralManager
        super.init()
        self.RSSI = RSSI
        self.cbPeripheral.delegate = self
    }

    public init(cbPeripheral: CBPeripheralInjectable, centralManager: BCCentralManager) {
        self.cbPeripheral = cbPeripheral
        self.centralManager = centralManager
        self.advertisements = nil
        super.init()
        self.RSSI = 0
        self.cbPeripheral.delegate = self
    }

    // MARK: RSSI
    public func readRSSI() -> Future<Int> {
        self.readRSSIPromise = Promise<Int>()
        self.cbPeripheral.readRSSI()
        return self.readRSSIPromise!.future
    }

    public func startPollingRSSI(period: NSTimeInterval = 10.0, capacity: Int? = nil) -> FutureStream<Int> {
        self.pollRSSIPromise = StreamPromise<Int>(capacity: capacity)
        self.cbPeripheral.readRSSI()
        self.pollRSSI(period)
        return pollRSSIPromise!.future
    }

    public func stopPollingRSSI() {
        self.pollRSSIPromise = nil
    }

    // MARK: Connection
    public func reconnect() {
        if let centralManager = self.centralManager where self.state == .Disconnected {
            BCLogger.debug("reconnect peripheral \(self.name)")
            centralManager.connectPeripheral(self)
            self.forcedDisconnect = false
            self.connectionSequence += 1
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
        guard let central = self.centralManager else {
            return
        }
        self.forcedDisconnect = true
        if self.state == .Connected {
            BCLogger.debug("uuid=\(self.identifier.UUIDString), name=\(self.name)")
            central.cancelPeripheralConnection(self)
        } else {
            self.didDisconnectPeripheral()
        }
    }
    
    public func terminate() {
        guard let central = self.centralManager else {
            return
        }
        central.discoveredPeripherals.removeValueForKey(self.cbPeripheral.identifier)
        self.didConnectPeripheral()
    }

    // MARK: Discover Services
    public func discoverServices(services: [CBUUID]?) -> Future<BCPeripheral> {
        BCLogger.debug(" \(self.name)")
        self.servicesDiscoveredPromise = Promise<BCPeripheral>()
        self.discoverIfConnected(services)
        return self.servicesDiscoveredPromise!.future
    }
    
    public func discoverAllServices() -> Future<BCPeripheral> {
        BCLogger.debug("uuid=\(self.identifier.UUIDString), name=\(self.name)")
        return self.discoverServices(nil)
    }

    public func discoverAllPeripheralServices() -> Future<BCPeripheral> {
        return self.discoverPeripheralServices(nil)
    }

    public func discoverPeripheralServices(services: [CBUUID]?) -> Future<BCPeripheral> {
        let peripheralDiscoveredPromise = Promise<BCPeripheral>()
        BCLogger.debug("uuid=\(self.identifier.UUIDString), name=\(self.name)")
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

    // MARK: CBPeripheralDelegate Shims
    internal func didDiscoverCharacteristicsForService(service: CBService, characteristics: [CBCharacteristic], error: NSError?) {
        BCLogger.debug("uuid=\(self.identifier.UUIDString), name=\(self.name)")
        if let bcService = self.discoveredServices[service.UUID] {
            bcService.didDiscoverCharacteristics(characteristics, error:error)
            if error == nil {
                for cbCharacteristic in characteristics {
                    self.discoveredCharacteristics[cbCharacteristic.UUID] = bcService.discoveredCharacteristics[cbCharacteristic.UUID]
                }
            }
        }
    }
    
    internal func didDiscoverServices(discoveredServices: [CBService], error: NSError?) {
        BCLogger.debug("uuid=\(self.identifier.UUIDString), name=\(self.name)")
        self.clearAll()
        if let error = error {
            self.servicesDiscoveredPromise?.failure(error)
        } else {
            for service in discoveredServices {
                let bcService = BCService(cbService:service, peripheral:self)
                self.discoveredServices[bcService.UUID] = bcService
                BCLogger.debug("uuid=\(bcService.UUID.UUIDString), name=\(bcService.name)")
            }
            self.servicesDiscoveredPromise?.success(self)
        }
    }
    
    internal func didUpdateNotificationStateForCharacteristic(characteristic: CBCharacteristic, error: NSError?) {
        BCLogger.debug()
        if let bcCharacteristic = self.discoveredCharacteristics[characteristic.UUID] {
            BCLogger.debug("uuid=\(bcCharacteristic.UUID.UUIDString), name=\(bcCharacteristic.name)")
            bcCharacteristic.didUpdateNotificationState(error)
        }
    }
    
    internal func didUpdateValueForCharacteristic(characteristic: CBCharacteristic, error: NSError?) {
        BCLogger.debug()
        if let bcCharacteristic = self.discoveredCharacteristics[characteristic.UUID] {
            BCLogger.debug("uuid=\(bcCharacteristic.UUID.UUIDString), name=\(bcCharacteristic.name)")
            bcCharacteristic.didUpdate(error)
        }
    }
    
    internal func didWriteValueForCharacteristic(characteristic: CBCharacteristic, error: NSError?) {
        BCLogger.debug()
        if let bcCharacteristic = self.discoveredCharacteristics[characteristic.UUID] {
            BCLogger.debug("uuid=\(bcCharacteristic.UUID.UUIDString), name=\(bcCharacteristic.name)")
            bcCharacteristic.didWrite(error)
        }
    }

    internal func didReadRSSI(RSSI: NSNumber, error: NSError?) {
        if let error = error {
            BCLogger.debug("RSSI read failed: \(error.localizedDescription)")
            self.readRSSIPromise?.failure(error)
            self.pollRSSIPromise?.failure(error)
        } else {
            BCLogger.debug("RSSI = \(RSSI.stringValue), peripheral name = \(self.name), state = \(self.state.rawValue)")
            self.RSSI = RSSI.integerValue
            self.readRSSIPromise?.success(RSSI.integerValue)
            self.pollRSSIPromise?.success(RSSI.integerValue)
        }
    }

    // MARK: CBCentralManagerDelegate Shims
    internal func didDisconnectPeripheral() {
        BCLogger.debug("uuid=\(self.identifier.UUIDString), name=\(self.name)")
        self.disconnectedAt = NSDate()
        if (self.forcedDisconnect) {
            self.forcedDisconnect = false
            BCLogger.debug("forced disconnect")
            self.connectionPromise?.success((self, .ForceDisconnect))
        } else {
            switch(self.currentError) {
            case .None:
                BCLogger.debug("no errors disconnecting")
                self.shouldDisconnectOrGiveup()
            case .Timeout:
                BCLogger.debug("timeout reconnecting")
                self.shouldTimeoutOrGiveup()
            case .Unknown:
                BCLogger.debug("unknown error")
            }
        }
    }

    internal func didConnectPeripheral() {
        BCLogger.debug("uuid=\(self.identifier.UUIDString), name=\(self.name)")
        self.connectedAt = NSDate()
        self.connectionPromise?.success((self, .Connect))
    }
    
    internal func didFailToConnectPeripheral(error: NSError?) {
        if let error = error {
            BCLogger.debug("connection failed for \(self.name) with error:'\(error.localizedDescription)'")
            self.currentError = .Unknown
            self.connectionPromise?.failure(error)
            if let disconnectRetries = self.disconnectRetries {
                if self.disconnectCount < disconnectRetries {
                    self.disconnectCount += 1
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
    private func shouldTimeoutOrGiveup() {
        BCLogger.debug("name=\(self.name), uuid=\(self.identifier.UUIDString), timeoutCount=\(self.timeoutCount)")
        if let timeoutRetries = self.timeoutRetries {
            if self.timeoutCount < timeoutRetries {
                self.connectionPromise?.success((self, .Timeout))
                self.timeoutCount += 1
            } else {
                self.timeoutCount = 0
                self.connectionPromise?.success((self, .GiveUp))
            }
        } else {
            self.connectionPromise?.success((self, .Timeout))
        }
    }

    private func shouldDisconnectOrGiveup() {
        BCLogger.debug("name=\(self.name), uuid=\(self.identifier.UUIDString)")
        if let disconnectRetries = self.disconnectRetries {
            if self.disconnectCount < disconnectRetries {
                self.disconnectCount += 1
                self.connectionPromise?.success((self, .Disconnect))
            } else {
                self.disconnectCount = 0
                self.connectionPromise?.success((self, .GiveUp))
            }
        } else {
            self.connectionPromise?.success((self, .Disconnect))
        }
    }

    private func discoverIfConnected(services: [CBUUID]?) {
        if self.state == .Connected {
            self.cbPeripheral.discoverServices(services)
        } else {
            self.servicesDiscoveredPromise?.failure(BCError.peripheralDisconnected)
        }
    }

    private func timeoutConnection(sequence: Int) {
        guard let centralManager = self.centralManager else {
            return
        }
        BCLogger.debug("name = \(self.name), UUID = \(self.identifier.UUIDString), sequence = \(sequence), timeout = \(self.connectionTimeout)")
        BCPeripheral.timeoutQueue.delay(self.connectionTimeout) {
            if self.state != .Connected && sequence == self.connectionSequence && !self.forcedDisconnect {
                BCLogger.debug("timing out name = \(self.name), UUID = \(self.identifier.UUIDString), sequence=\(sequence), current connectionSequence=\(self.connectionSequence)")
                self.currentError = .Timeout
                centralManager.cancelPeripheralConnection(self)
            } else {
                BCLogger.debug("expired")
            }
        }
    }

    private func clearAll() {
        self.discoveredServices.removeAll()
        self.discoveredCharacteristics.removeAll()
    }

    private func pollRSSI(period: NSTimeInterval) {
        guard self.pollRSSIPromise != nil else {
            return
        }
        BCLogger.debug("period = \(period)")
        BCPeripheral.rssiQueue.delay(period) {
            self.cbPeripheral.readRSSI()
            self.pollRSSI(period)
        }
    }
    
}
