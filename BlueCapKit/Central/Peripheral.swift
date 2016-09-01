//
//  Peripheral.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/8/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import Foundation
import CoreBluetooth

// MARK - Connection Error -
enum PeripheralConnectionError {
    case none, timeout
}

public enum ConnectionEvent {
    case connect, timeout, disconnect, forceDisconnect, giveUp
}

// MARK: - PeripheralAdvertisements -
public struct PeripheralAdvertisements {
    
    let advertisements: [String : Any]
    
    public var localName: String? {
        return self.advertisements[CBAdvertisementDataLocalNameKey] as? String
    }
    
    public var manufactuereData: Data? {
        return self.advertisements[CBAdvertisementDataManufacturerDataKey] as? Data
    }
    
    public var txPower: NSNumber? {
        return self.advertisements[CBAdvertisementDataTxPowerLevelKey] as? NSNumber
    }
    
    public var isConnectable: NSNumber? {
        return self.advertisements[CBAdvertisementDataIsConnectable] as? NSNumber
    }
    
    public var serviceUUIDs: [CBUUID]? {
        return self.advertisements[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID]
    }
    
    public var serviceData: [CBUUID:Data]? {
        return self.advertisements[CBAdvertisementDataServiceDataKey] as? [CBUUID:Data]
    }
    
    public var overflowServiceUUIDs: [CBUUID]? {
        return self.advertisements[CBAdvertisementDataOverflowServiceUUIDsKey] as? [CBUUID]
    }
    
    public var solicitedServiceUUIDs: [CBUUID]? {
        return self.advertisements[CBAdvertisementDataSolicitedServiceUUIDsKey] as? [CBUUID]
    }    
}

// MARK: - Peripheral -
public class Peripheral: NSObject, CBPeripheralDelegate {

    // MARK: Serialize Property IO
    static let ioQueue = Queue("us.gnos.blueCap.peripheral")
    static let pollQueue = Queue("us.gnos.blueCap.peripheral.poll")

    fileprivate var _servicesDiscoveredPromise: Promise<Peripheral>?
    fileprivate var _readRSSIPromise: Promise<Int>?
    fileprivate var _pollRSSIPromise: StreamPromise<Int>?

    fileprivate var _connectionPromise: StreamPromise<(peripheral: Peripheral, connectionEvent: ConnectionEvent)>?

    fileprivate var _RSSI: Int = 0
    fileprivate var _state = CBPeripheralState.disconnected

    fileprivate var _timeoutCount: UInt = 0
    fileprivate var _disconnectionCount: UInt = 0
    
    fileprivate var _connectionSequence = 0
    fileprivate var _RSSISequence = 0
    fileprivate var _serviceDiscoverySequence = 0

    fileprivate var _currentError = PeripheralConnectionError.none
    fileprivate var _forcedDisconnect = false
    fileprivate var _serviceDiscoveryInProgress = false

    fileprivate var _connectedAt: Date?
    fileprivate var _disconnectedAt : Date?
    fileprivate var _totalSecondsConnected = 0.0

    internal var discoveredServices = SerialIODictionary<CBUUID, Service>(Peripheral.ioQueue)
    internal var discoveredCharacteristics = SerialIODictionary<CBUUID, Characteristic>(Peripheral.ioQueue)

    fileprivate var connectionTimeout = Double.infinity
    fileprivate var timeoutRetries = UInt.max
    fileprivate var disconnectRetries = UInt.max

    internal fileprivate(set) weak var centralManager: CentralManager?
    
    internal fileprivate(set) var cbPeripheral: CBPeripheralInjectable
    public let advertisements: PeripheralAdvertisements
    public let discoveredAt = Date()

    // MARK: Serial Properties
    public var RSSI: Int {
        get {
            return Peripheral.ioQueue.sync { return self._RSSI }
        }
        set {
            Peripheral.ioQueue.sync { self._RSSI = newValue }
        }
    }

    fileprivate var servicesDiscoveredPromise: Promise<Peripheral>? {
        get {
            return Peripheral.ioQueue.sync { return self._servicesDiscoveredPromise }
        }
        set {
            Peripheral.ioQueue.sync { self._servicesDiscoveredPromise = newValue }
        }
    }

    fileprivate var readRSSIPromise: Promise<Int>? {
        get {
            return Peripheral.ioQueue.sync { return self._readRSSIPromise }
        }
        set {
            Peripheral.ioQueue.sync { self._readRSSIPromise = newValue }
        }
    }

    fileprivate var pollRSSIPromise: StreamPromise<Int>? {
        get {
            return Peripheral.ioQueue.sync { return self._pollRSSIPromise }
        }
        set {
            Peripheral.ioQueue.sync { self._pollRSSIPromise = newValue }
        }
    }

    fileprivate var connectionPromise: StreamPromise<(peripheral: Peripheral, connectionEvent: ConnectionEvent)>? {
        get {
            return Peripheral.ioQueue.sync { return self._connectionPromise }
        }
        set {
            Peripheral.ioQueue.sync { self._connectionPromise = newValue }
        }
    }

    fileprivate var connectionSequence: Int {
        get {
            return Peripheral.ioQueue.sync { return self._connectionSequence }
        }
        set {
            Peripheral.ioQueue.sync { self._connectionSequence = newValue }
        }
    }

    fileprivate var RSSISequence: Int {
        get {
            return Peripheral.ioQueue.sync { return self._RSSISequence }
        }
        set {
            Peripheral.ioQueue.sync { self._RSSISequence = newValue }
        }
    }

    fileprivate var serviceDiscoverySequence: Int {
        get {
            return Peripheral.ioQueue.sync { return self._serviceDiscoverySequence }
        }
        set {
            Peripheral.ioQueue.sync { self._serviceDiscoverySequence = newValue }
        }
    }

    fileprivate var currentError: PeripheralConnectionError {
        get {
            return Peripheral.ioQueue.sync { return self._currentError }
        }
        set {
            Peripheral.ioQueue.sync { self._currentError = newValue }
        }
    }

    fileprivate var forcedDisconnect: Bool {
        get {
            return Peripheral.ioQueue.sync { return self._forcedDisconnect }
        }
        set {
            Peripheral.ioQueue.sync { self._forcedDisconnect = newValue }
        }
    }

    fileprivate var serviceDiscoveryInProgress: Bool {
        get {
            return Peripheral.ioQueue.sync { return self._serviceDiscoveryInProgress }
        }
        set {
            Peripheral.ioQueue.sync { self._serviceDiscoveryInProgress = newValue }
        }
    }

    fileprivate fileprivate(set) var totalSecondsConnected: Double {
        get {
            return Peripheral.ioQueue.sync { return self._totalSecondsConnected }
        }
        set {
            Peripheral.ioQueue.sync { self._totalSecondsConnected = newValue }
        }
    }

    // MARK: Public Properties
    public fileprivate(set) var connectedAt: Date? {
        get {
            return Peripheral.ioQueue.sync { return self._connectedAt }
        }
        set {
            Peripheral.ioQueue.sync { self._connectedAt = newValue }
        }
    }

    public fileprivate(set) var disconnectedAt: Date? {
        get {
            return Peripheral.ioQueue.sync { return self._disconnectedAt }
        }
        set {
            Peripheral.ioQueue.sync { self._disconnectedAt = newValue }
        }
    }

    public fileprivate(set) var timeoutCount: UInt {
        get {
            return Peripheral.ioQueue.sync  { return self._timeoutCount }
        }
        set {
            Peripheral.ioQueue.sync { self._timeoutCount = newValue }
        }
    }

    public fileprivate(set) var disconnectionCount: UInt {
        get {
            return Peripheral.ioQueue.sync { return self._disconnectionCount }
        }
        set {
            Peripheral.ioQueue.sync { self._disconnectionCount = newValue }
        }
    }

    public var connectionCount: Int {
        get {
            return Peripheral.ioQueue.sync { return self._connectionSequence }
        }
    }

    public var secondsConnected: Double {
        if let disconnectedAt = self.disconnectedAt, let connectedAt = self.connectedAt {
            return disconnectedAt.timeIntervalSince(connectedAt)
        } else if let connectedAt = self.connectedAt {
            return Date().timeIntervalSince(connectedAt)
        } else {
            return 0.0
        }
    }

    public var cumlativeSecondsConnected: Double {
        if self.disconnectedAt != nil {
            return self.totalSecondsConnected
        } else {
            return self.totalSecondsConnected + self.secondsConnected
        }
    }

    public var cumlativeSecondsDisconnected: Double {
        return Date().timeIntervalSince(self.discoveredAt) - self.cumlativeSecondsConnected
    }

    public var name: String {
        if let name = self.cbPeripheral.name {
            return name
        } else {
            return "Unknown"
        }
    }

    public var services: [Service] {
        return Array(self.discoveredServices.values)
    }
    
    public var identifier: UUID {
        return self.cbPeripheral.identifier as UUID
    }

    public func service(_ uuid: CBUUID) -> Service? {
        return self.discoveredServices[uuid]
    }

    public var state: CBPeripheralState {
        get {
            return cbPeripheral.state
        }
    }

    // MARK: Initializers
    internal init(cbPeripheral: CBPeripheralInjectable, centralManager: CentralManager, advertisements: [String : Any], RSSI: Int) {
        self.cbPeripheral = cbPeripheral
        self.centralManager = centralManager
        self.advertisements = PeripheralAdvertisements(advertisements: advertisements)
        super.init()
        self.RSSI = RSSI
        self.cbPeripheral.delegate = self
    }

    internal init(cbPeripheral: CBPeripheralInjectable, centralManager: CentralManager) {
        self.cbPeripheral = cbPeripheral
        self.centralManager = centralManager
        self.advertisements = PeripheralAdvertisements(advertisements: [String : AnyObject]())
        super.init()
        self.RSSI = 0
        self.cbPeripheral.delegate = self
    }

    internal init(cbPeripheral: CBPeripheralInjectable, bcPeripheral: Peripheral) {
        self.cbPeripheral = cbPeripheral
        self.advertisements = bcPeripheral.advertisements
        self.centralManager = bcPeripheral.centralManager
        super.init()
        self.RSSI = bcPeripheral.RSSI
        self.cbPeripheral.delegate = self
    }

    deinit {
        self.cbPeripheral.delegate = nil
    }

    // MARK: RSSI
    public func readRSSI() -> Future<Int> {
        Logger.debug("name = \(self.name), uuid = \(self.identifier.uuidString)")
        self.readRSSIPromise = Promise<Int>()
        self.readRSSIIfConnected()
        return self.readRSSIPromise!.future
    }

    public func startPollingRSSI(_ period: Double = 10.0, capacity: Int = Int.max) -> FutureStream<Int> {
        Logger.debug("name = \(self.name), uuid = \(self.identifier.uuidString), period = \(period)")
        self.pollRSSIPromise = StreamPromise<Int>(capacity: capacity)
        self.readRSSIIfConnected()
        self.RSSISequence += 1
        self.pollRSSI(period, sequence: self.RSSISequence)
        return pollRSSIPromise!.stream
    }

    public func stopPollingRSSI() {
        Logger.debug("name = \(self.name), uuid = \(self.identifier.uuidString)")
        self.pollRSSIPromise = nil
    }

    // MARK: Connection
    public func reconnect(_ reconnectDelay: Double = 0.0) {
        guard let centralManager = self.centralManager , self.state == .disconnected  else {
            Logger.debug("peripheral not disconnected \(self.name), \(self.identifier.uuidString)")
            return
        }
        Logger.debug("reconnect peripheral name=\(self.name), uuid=\(self.identifier.uuidString)")
        centralManager.centralQueue.delay(reconnectDelay) {
            centralManager.connect(self)
            self.forcedDisconnect = false
            self.connectionSequence += 1
            self.currentError = .none
            self.timeoutConnection(self.connectionSequence)
        }
    }
     
    public func connect(_ capacity: Int = Int.max, timeoutRetries: UInt = UInt.max, disconnectRetries: UInt = UInt.max, connectionTimeout: Double = Double.infinity) -> FutureStream<(peripheral: Peripheral, connectionEvent: ConnectionEvent)> {
        if self.connectionPromise == nil {
            self.connectionPromise = StreamPromise<(peripheral: Peripheral, connectionEvent: ConnectionEvent)>(capacity: capacity)
        }
        self.timeoutRetries = timeoutRetries
        self.disconnectRetries = disconnectRetries
        self.connectionTimeout = connectionTimeout
        Logger.debug("connect peripheral \(self.name)', \(self.identifier.uuidString)")
        self.reconnect()
        return self.connectionPromise!.stream
    }
    
    public func disconnect() {
        guard let central = self.centralManager else {
            return
        }
        self.forcedDisconnect = true
        self.stopPollingRSSI()
        if self.state == .connected {
            Logger.debug("disconnecting name=\(self.name), uuid=\(self.identifier.uuidString)")
            central.cancelPeripheralConnection(self)
        } else {
            Logger.debug("already disconnected name=\(self.name), uuid=\(self.identifier.uuidString)")
            self.didDisconnectPeripheral(PeripheralError.disconnected)
        }
    }
    
    public func terminate() {
        guard let central = self.centralManager else {
            return
        }
        central.discoveredPeripherals.removeValueForKey(self.cbPeripheral.identifier)
        if self.state == .connected {
            self.disconnect()
        }
    }

    // MARK: Discover Services
    public func discoverAllServices(_ timeout: Double = Double.infinity) -> Future<Peripheral> {
        Logger.debug("uuid=\(self.identifier.uuidString), name=\(self.name)")
        return self.discoverServices(nil, timeout: timeout)
    }

    public func discoverServices(_ services: [CBUUID]?, timeout: Double = Double.infinity) -> Future<Peripheral> {
        Logger.debug(" \(self.name)")
        return self.discoverIfConnected(services, timeout: timeout)
    }
    
    public func discoverAllPeripheralServices(_ timeout: Double = Double.infinity) -> Future<Peripheral> {
        return self.discoverPeripheralServices(nil)
    }

    public func discoverPeripheralServices(_ services: [CBUUID]?, timeout: Double = Double.infinity) -> Future<Peripheral> {
        let peripheralDiscoveredPromise = Promise<Peripheral>()
        Logger.debug("uuid=\(self.identifier.uuidString), name=\(self.name)")
        let servicesDiscoveredFuture = self.discoverServices(services, timeout: timeout)
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
                    peripheralDiscoveredPromise.failure(PeripheralError.noServices)
                }
            }
        }
        servicesDiscoveredFuture.onFailure {(error) in
            peripheralDiscoveredPromise.failure(error)
        }
        return peripheralDiscoveredPromise.future
    }
    
    public func discoverService(_ head: Service, tail: [Service], promise: Promise<Peripheral>) {
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

    // MARK: CBPeripheralDelegate
    public func peripheralDidUpdateName(_:CBPeripheral) {
        Logger.debug()
    }
    
    public func peripheral(_: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        Logger.debug()
    }

    @nonobjc public func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        didReadRSSI(RSSI, error:error)
    }

    @nonobjc public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = self.cbPeripheral.getServices() {
            didDiscoverServices(services, error: error)
        }
    }
    
    @nonobjc public func peripheral(_ peripheral: CBPeripheral, didDiscoverIncludedServicesFor service: CBService, error: Error?) {
        Logger.debug("peripheral name \(self.name)")
    }
    
    @nonobjc public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.getCharacteristics() else {
            return
        }
        didDiscoverCharacteristicsForService(service, characteristics: characteristics, error: error)
    }

    @nonobjc public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        didUpdateNotificationStateForCharacteristic(characteristic, error: error)
    }

    @nonobjc public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        didUpdateValueForCharacteristic(characteristic, error: error)
    }

    @nonobjc public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        didWriteValueForCharacteristic(characteristic, error: error)
    }

    @nonobjc public func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        Logger.debug()
    }
    
    @nonobjc public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
        Logger.debug()
    }
    
    @nonobjc public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
        Logger.debug()
    }

    // MARK: CBPeripheralDelegate Shims
    internal func didDiscoverCharacteristicsForService(_ service: CBServiceInjectable, characteristics: [CBCharacteristicInjectable], error: Error?) {
        Logger.debug("uuid=\(self.identifier.uuidString), name=\(self.name)")
        if let bcService = self.discoveredServices[service.UUID] {
            bcService.didDiscoverCharacteristics(characteristics, error: error)
            if error == nil {
                for cbCharacteristic in characteristics {
                    self.discoveredCharacteristics[cbCharacteristic.UUID] = bcService.discoveredCharacteristics[cbCharacteristic.UUID]
                }
            }
        }
    }
    
    internal func didDiscoverServices(_ discoveredServices: [CBServiceInjectable], error: Error?) {
        Logger.debug("uuid=\(self.identifier.uuidString), name=\(self.name)")
        self.clearAll()
        self.serviceDiscoveryInProgress = false
        if let error = error {
            self.servicesDiscoveredPromise?.failure(error)
        } else {
            for service in discoveredServices {
                let bcService = Service(cbService:service, peripheral:self)
                self.discoveredServices[bcService.UUID] = bcService
                Logger.debug("uuid=\(bcService.UUID.uuidString), name=\(bcService.name)")
            }
            self.servicesDiscoveredPromise?.success(self)
        }
    }
    
    internal func didUpdateNotificationStateForCharacteristic(_ characteristic: CBCharacteristicInjectable, error: Error?) {
        Logger.debug()
        if let bcCharacteristic = self.discoveredCharacteristics[characteristic.UUID] {
            Logger.debug("uuid=\(bcCharacteristic.UUID.uuidString), name=\(bcCharacteristic.name)")
            bcCharacteristic.didUpdateNotificationState(error)
        }
    }
    
    internal func didUpdateValueForCharacteristic(_ characteristic: CBCharacteristicInjectable, error: Error?) {
        Logger.debug()
        if let bcCharacteristic = self.discoveredCharacteristics[characteristic.UUID] {
            Logger.debug("uuid=\(bcCharacteristic.UUID.uuidString), name=\(bcCharacteristic.name)")
            bcCharacteristic.didUpdate(error)
        }
    }
    
    internal func didWriteValueForCharacteristic(_ characteristic: CBCharacteristicInjectable, error: Error?) {
        Logger.debug()
        if let bcCharacteristic = self.discoveredCharacteristics[characteristic.UUID] {
            Logger.debug("uuid=\(bcCharacteristic.UUID.uuidString), name=\(bcCharacteristic.name)")
            bcCharacteristic.didWrite(error)
        }
    }

    internal func didReadRSSI(_ RSSI: NSNumber, error: Error?) {
        if let error = error {
            Logger.debug("RSSI read failed: \(error.localizedDescription)")
            self.readRSSIPromise?.failure(error)
            self.pollRSSIPromise?.failure(error)
        } else {
            Logger.debug("RSSI = \(RSSI.stringValue), peripheral name = \(self.name), uuid=\(self.identifier.uuidString), state = \(self.state.rawValue)")
            self.RSSI = RSSI.intValue
            self.readRSSIPromise?.success(RSSI.intValue)
            self.pollRSSIPromise?.success(RSSI.intValue)
        }
    }

    // MARK: CBCentralManagerDelegate Shims
    internal func didConnectPeripheral() {
        Logger.debug("uuid=\(self.identifier.uuidString), name=\(self.name)")
        self.connectedAt = Date()
        self.disconnectedAt = nil
        self.connectionPromise?.success((self, .connect))
    }

    internal func didDisconnectPeripheral(_ error: Swift.Error?) {
        self.disconnectedAt = Date()
        self.totalSecondsConnected += self.secondsConnected
        self.serviceDiscoveryInProgress = false
        switch(self.currentError) {
        case .none:
            if let error = error {
                Logger.debug("disconnecting with errors uuid=\(self.identifier.uuidString), name=\(self.name), error=\(error.localizedDescription)")
                self.shouldFailOrGiveUp(error)
            } else if (self.forcedDisconnect) {
                Logger.debug("disconnect forced uuid=\(self.identifier.uuidString), name=\(self.name)")
                self.forcedDisconnect = false
                self.connectionPromise?.success((self, .forceDisconnect))
            } else  {
                Logger.debug("disconnecting with no errors uuid=\(self.identifier.uuidString), name=\(self.name)")
                self.shouldDisconnectOrGiveup()
            }
        case .timeout:
            Logger.debug("timeout uuid=\(self.identifier.uuidString), name=\(self.name)")
            self.shouldTimeoutOrGiveup()
        }
        for service in self.services {
            service.didDisconnectPeripheral(error)
        }
    }

    internal func didFailToConnectPeripheral(_ error: Swift.Error?) {
        self.didDisconnectPeripheral(error)
    }

    // MARK: CBPeripheral Delegation
    internal func setNotifyValue(_ state: Bool, forCharacteristic characteristic: Characteristic) {
        self.cbPeripheral.setNotifyValue(state, forCharacteristic:characteristic.cbCharacteristic)
    }
    
    internal func readValueForCharacteristic(_ characteristic: Characteristic) {
        self.cbPeripheral.readValueForCharacteristic(characteristic.cbCharacteristic)
    }
    
    internal func writeValue(_ value: Data, forCharacteristic characteristic: Characteristic, type: CBCharacteristicWriteType = .withResponse) {
            self.cbPeripheral.writeValue(value, forCharacteristic:characteristic.cbCharacteristic, type:type)
    }
    
    internal func discoverCharacteristics(_ characteristics: [CBUUID]?, forService service: Service) {
        self.cbPeripheral.discoverCharacteristics(characteristics, forService:service.cbService)
    }

    // MARK: Utilities
    fileprivate func shouldFailOrGiveUp(_ error: Swift.Error) {
        Logger.debug("name=\(self.name), uuid=\(self.identifier.uuidString), disconnectCount=\(self.disconnectionCount), disconnectRetries=\(self.disconnectRetries)")
            if self.disconnectionCount < disconnectRetries {
                self.disconnectionCount += 1
                self.connectionPromise?.failure(error)
            } else {
                self.connectionPromise?.success((self, ConnectionEvent.giveUp))
            }
    }

    fileprivate func shouldTimeoutOrGiveup() {
        Logger.debug("name=\(self.name), uuid=\(self.identifier.uuidString), timeoutCount=\(self.timeoutCount), timeoutRetries=\(self.timeoutRetries)")
        if self.timeoutCount < timeoutRetries {
            self.connectionPromise?.success((self, .timeout))
            self.timeoutCount += 1
        } else {
            self.connectionPromise?.success((self, .giveUp))
        }
    }

    fileprivate func shouldDisconnectOrGiveup() {
        Logger.debug("name=\(self.name), uuid=\(self.identifier.uuidString), disconnectCount=\(self.disconnectionCount), disconnectRetries=\(self.disconnectRetries)")
        if self.disconnectionCount < disconnectRetries {
            self.disconnectionCount += 1
            self.connectionPromise?.success((self, .disconnect))
        } else {
            self.connectionPromise?.success((self, .giveUp))
        }
    }

    fileprivate func discoverIfConnected(_ services: [CBUUID]?, timeout: Double = Double.infinity)  -> Future<Peripheral> {
        if !self.serviceDiscoveryInProgress {
            self.servicesDiscoveredPromise = Promise<Peripheral>()
            if self.state == .connected {
                self.serviceDiscoveryInProgress = true
                self.serviceDiscoverySequence += 1
                self.timeoutServiceDiscovery(self.serviceDiscoverySequence, timeout: timeout)
                self.cbPeripheral.discoverServices(services)
            } else {
                self.servicesDiscoveredPromise?.failure(PeripheralError.disconnected)
            }
            return self.servicesDiscoveredPromise!.future
        } else {
            let promise = Promise<Peripheral>()
            promise.failure(PeripheralError.serviceDiscoveryInProgress)
            return promise.future
        }
    }

    fileprivate func clearAll() {
        self.discoveredServices.removeAll()
        self.discoveredCharacteristics.removeAll()
    }

    fileprivate func timeoutConnection(_ sequence: Int) {
        guard let centralManager = self.centralManager , connectionTimeout < Double.infinity else {
            return
        }
        Logger.debug("name = \(self.name), uuid = \(self.identifier.uuidString), sequence = \(sequence), timeout = \(self.connectionTimeout)")
        Peripheral.pollQueue.delay(self.connectionTimeout) {
            if self.state != .connected && sequence == self.connectionSequence && !self.forcedDisconnect {
                Logger.debug("connection timing out name = \(self.name), UUID = \(self.identifier.uuidString), sequence=\(sequence), current connectionSequence=\(self.connectionSequence)")
                self.currentError = .timeout
                centralManager.cancelPeripheralConnection(self)
            } else {
                Logger.debug("connection timeout expired name = \(self.name), uuid = \(self.identifier.uuidString), sequence = \(sequence), current connectionSequence=\(self.connectionSequence), state=\(self.state.rawValue)")
            }
        }
    }

    fileprivate func timeoutServiceDiscovery(_ sequence: Int, timeout: Double) {
        guard let centralManager = self.centralManager , timeout < Double.infinity else {
            return
        }
        Logger.debug("name = \(self.name), uuid = \(self.identifier.uuidString), sequence = \(sequence), timeout = \(timeout)")
        Peripheral.pollQueue.delay(timeout) {
            if sequence == self.serviceDiscoverySequence && self.serviceDiscoveryInProgress {
                Logger.debug("service scan timing out name = \(self.name), UUID = \(self.identifier.uuidString), sequence=\(sequence), current sequence=\(self.serviceDiscoverySequence)")
                centralManager.cancelPeripheralConnection(self)
                self.serviceDiscoveryInProgress = false
                self.servicesDiscoveredPromise?.failure(PeripheralError.serviceDiscoveryTimeout)
            } else {
                Logger.debug("service scan timeout expired name = \(self.name), uuid = \(self.identifier.uuidString), sequence = \(sequence), current sequence = \(self.serviceDiscoverySequence)")
            }
        }
    }

    fileprivate func pollRSSI(_ period: Double, sequence: Int) {
        Logger.debug("name = \(self.name), uuid = \(self.identifier.uuidString), period = \(period), sequence = \(sequence), current sequence = \(self.RSSISequence)")
        guard self.pollRSSIPromise != nil && sequence == self.RSSISequence else {
            Logger.debug("exiting: name = \(self.name), uuid = \(self.identifier.uuidString), sequence = \(sequence), current sequence = \(self.RSSISequence)")
            return
        }
        Peripheral.pollQueue.delay(period) {
            Logger.debug("trigger: name = \(self.name), uuid = \(self.identifier.uuidString), sequence = \(sequence), current sequence = \(self.RSSISequence)")
            self.readRSSIIfConnected()
            self.pollRSSI(period, sequence: sequence)
        }
    }

    fileprivate func readRSSIIfConnected() {
        if self.state == .connected {
            self.cbPeripheral.readRSSI()
        } else {
            self.readRSSIPromise?.failure(PeripheralError.disconnected)
            self.pollRSSIPromise?.failure(PeripheralError.disconnected)
        }
    }

}
