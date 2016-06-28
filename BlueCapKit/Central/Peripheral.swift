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
    case None, Timeout
}

public enum ConnectionEvent {
    case Connect, Timeout, Disconnect, ForceDisconnect, GiveUp
}

// MARK: - PeripheralAdvertisements -
public struct PeripheralAdvertisements {
    
    let advertisements: [String: AnyObject]
    
    public var localName: String? {
        return self.advertisements[CBAdvertisementDataLocalNameKey].flatMap { $0 as? String }
    }
    
    public var manufactuereData: NSData? {
        return self.advertisements[CBAdvertisementDataManufacturerDataKey].flatMap { $0 as? NSData }
    }
    
    public var txPower: NSNumber? {
        return self.advertisements[CBAdvertisementDataTxPowerLevelKey].flatMap { $0 as? NSNumber }
    }
    
    public var isConnectable: NSNumber? {
        return self.advertisements[CBAdvertisementDataIsConnectable].flatMap { $0 as? NSNumber }
    }
    
    public var serviceUUIDs: [CBUUID]? {
        return self.advertisements[CBAdvertisementDataServiceUUIDsKey].flatMap { $0 as? [CBUUID] }
    }
    
    public var serviceData: [CBUUID:NSData]? {
        return self.advertisements[CBAdvertisementDataServiceDataKey].flatMap { $0 as? [CBUUID:NSData] }
    }
    
    public var overflowServiceUUIDs: [CBUUID]? {
        return self.advertisements[CBAdvertisementDataOverflowServiceUUIDsKey].flatMap { $0 as? [CBUUID] }
    }
    
    public var solicitedServiceUUIDs: [CBUUID]? {
        return self.advertisements[CBAdvertisementDataSolicitedServiceUUIDsKey].flatMap { $0 as? [CBUUID] }
    }    
}

// MARK: - Peripheral -
public class Peripheral: NSObject, CBPeripheralDelegate {

    internal static var CBPeripheralStateKVOContext = UInt8()
    internal static let DefaultServiceScanTimeout: Double = 10.0

    // MARK: Serialize Property IO
    static let ioQueue = Queue("us.gnos.blueCap.peripheral")
    static let pollQueue = Queue("us.gnos.blueCap.peripheral.poll")

    private var _servicesDiscoveredPromise: Promise<Peripheral>?
    private var _readRSSIPromise: Promise<Int>?
    private var _pollRSSIPromise: StreamPromise<Int>?

    private var _connectionPromise: StreamPromise<(peripheral: Peripheral, connectionEvent: ConnectionEvent)>?

    private var _RSSI: Int = 0
    private var _state = CBPeripheralState.Disconnected

    private var _timeoutCount: UInt = 0
    private var _disconnectionCount: UInt = 0
    
    private var _connectionSequence = 0
    private var _RSSISequence = 0
    private var _serviceDiscoverySequence = 0

    private var _currentError = PeripheralConnectionError.None
    private var _forcedDisconnect = false
    private var _serviceDiscoveryInProgress = false

    private var _connectedAt: NSDate?
    private var _disconnectedAt : NSDate?
    private var _totalSecondsConnected = 0.0

    internal var discoveredServices = SerialIODictionary<CBUUID, Service>(Peripheral.ioQueue)
    internal var discoveredCharacteristics = SerialIODictionary<CBUUID, Characteristic>(Peripheral.ioQueue)

    private var connectionTimeout = 10.0
    private var timeoutRetries: UInt?
    private var disconnectRetries: UInt?
    
    internal private(set) weak var centralManager: CentralManager?
    
    internal private(set) var cbPeripheral: CBPeripheralInjectable
    public let advertisements: PeripheralAdvertisements?
    public let discoveredAt = NSDate()

    // MARK: Serial Properties
    public var RSSI: Int {
        get {
            return Peripheral.ioQueue.sync { return self._RSSI }
        }
        set {
            Peripheral.ioQueue.sync { self._RSSI = newValue }
        }
    }

    private var servicesDiscoveredPromise: Promise<Peripheral>? {
        get {
            return Peripheral.ioQueue.sync { return self._servicesDiscoveredPromise }
        }
        set {
            Peripheral.ioQueue.sync { self._servicesDiscoveredPromise = newValue }
        }
    }

    private var readRSSIPromise: Promise<Int>? {
        get {
            return Peripheral.ioQueue.sync { return self._readRSSIPromise }
        }
        set {
            Peripheral.ioQueue.sync { self._readRSSIPromise = newValue }
        }
    }

    private var pollRSSIPromise: StreamPromise<Int>? {
        get {
            return Peripheral.ioQueue.sync { return self._pollRSSIPromise }
        }
        set {
            Peripheral.ioQueue.sync { self._pollRSSIPromise = newValue }
        }
    }

    private var connectionPromise: StreamPromise<(peripheral: Peripheral, connectionEvent: ConnectionEvent)>? {
        get {
            return Peripheral.ioQueue.sync { return self._connectionPromise }
        }
        set {
            Peripheral.ioQueue.sync { self._connectionPromise = newValue }
        }
    }

    private var connectionSequence: Int {
        get {
            return Peripheral.ioQueue.sync { return self._connectionSequence }
        }
        set {
            Peripheral.ioQueue.sync { self._connectionSequence = newValue }
        }
    }

    private var RSSISequence: Int {
        get {
            return Peripheral.ioQueue.sync { return self._RSSISequence }
        }
        set {
            Peripheral.ioQueue.sync { self._RSSISequence = newValue }
        }
    }

    private var serviceDiscoverySequence: Int {
        get {
            return Peripheral.ioQueue.sync { return self._serviceDiscoverySequence }
        }
        set {
            Peripheral.ioQueue.sync { self._serviceDiscoverySequence = newValue }
        }
    }

    private var currentError: PeripheralConnectionError {
        get {
            return Peripheral.ioQueue.sync { return self._currentError }
        }
        set {
            Peripheral.ioQueue.sync { self._currentError = newValue }
        }
    }

    private var forcedDisconnect: Bool {
        get {
            return Peripheral.ioQueue.sync { return self._forcedDisconnect }
        }
        set {
            Peripheral.ioQueue.sync { self._forcedDisconnect = newValue }
        }
    }

    private var serviceDiscoveryInProgress: Bool {
        get {
            return Peripheral.ioQueue.sync { return self._serviceDiscoveryInProgress }
        }
        set {
            Peripheral.ioQueue.sync { self._serviceDiscoveryInProgress = newValue }
        }
    }

    private private(set) var totalSecondsConnected: Double {
        get {
            return Peripheral.ioQueue.sync { return self._totalSecondsConnected }
        }
        set {
            Peripheral.ioQueue.sync { self._totalSecondsConnected = newValue }
        }
    }

    // MARK: Public Properties
    public private(set) var connectedAt: NSDate? {
        get {
            return Peripheral.ioQueue.sync { return self._connectedAt }
        }
        set {
            Peripheral.ioQueue.sync { self._connectedAt = newValue }
        }
    }

    public private(set) var disconnectedAt: NSDate? {
        get {
            return Peripheral.ioQueue.sync { return self._disconnectedAt }
        }
        set {
            Peripheral.ioQueue.sync { self._disconnectedAt = newValue }
        }
    }

    public private(set) var timeoutCount: UInt {
        get {
            return Peripheral.ioQueue.sync  { return self._timeoutCount }
        }
        set {
            Peripheral.ioQueue.sync { self._timeoutCount = newValue }
        }
    }

    public private(set) var disconnectionCount: UInt {
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
        if let disconnectedAt = self.disconnectedAt, connectedAt = self.connectedAt {
            return disconnectedAt.timeIntervalSinceDate(connectedAt)
        } else if let connectedAt = self.connectedAt {
            return NSDate().timeIntervalSinceDate(connectedAt)
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
        return NSDate().timeIntervalSinceDate(self.discoveredAt) - self.cumlativeSecondsConnected
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
    
    public var identifier: NSUUID {
        return self.cbPeripheral.identifier
    }

    public func service(uuid: CBUUID) -> Service? {
        return self.discoveredServices[uuid]
    }

    public internal(set) var state: CBPeripheralState {
        get {
            return Peripheral.ioQueue.sync { return self._state }
        }
        set {
            Peripheral.ioQueue.sync { self._state = newValue }
        }
    }

    // MARK: Initializers
    internal init(cbPeripheral: CBPeripheralInjectable, centralManager: CentralManager, advertisements: [String:AnyObject], RSSI: Int) {
        self.cbPeripheral = cbPeripheral
        self.centralManager = centralManager
        self.advertisements = PeripheralAdvertisements(advertisements: advertisements)
        super.init()
        self.RSSI = RSSI
        self.state = cbPeripheral.state
        self.cbPeripheral.delegate = self
        self.startObserving()
    }

    internal init(cbPeripheral: CBPeripheralInjectable, centralManager: CentralManager) {
        self.cbPeripheral = cbPeripheral
        self.centralManager = centralManager
        self.advertisements = nil
        super.init()
        self.RSSI = 0
        self.state = cbPeripheral.state
        self.cbPeripheral.delegate = self
        self.startObserving()
    }

    internal init(cbPeripheral: CBPeripheralInjectable, bcPeripheral: Peripheral) {
        self.cbPeripheral = cbPeripheral
        self.advertisements = bcPeripheral.advertisements
        self.centralManager = bcPeripheral.centralManager
        super.init()
        self.RSSI = bcPeripheral.RSSI
        self.state = cbPeripheral.state
        self.cbPeripheral.delegate = self
        self.startObserving()
    }

    deinit {
        self.cbPeripheral.delegate = nil
        self.stopObserving()
    }

    // MARK: KVO
    internal func startObserving() {
        guard let cbPeripheral = self.cbPeripheral as? CBPeripheral else {
            return
        }
        let options = NSKeyValueObservingOptions([.New, .Old])
        cbPeripheral.addObserver(self, forKeyPath: "state", options: options, context: &Peripheral.CBPeripheralStateKVOContext)
    }

    internal func stopObserving() {
        guard let cbPeripheral = self.cbPeripheral as? CBPeripheral else {
            return
        }
        cbPeripheral.removeObserver(self, forKeyPath: "state", context: &Peripheral.CBPeripheralStateKVOContext)
    }
    
    override public func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String: AnyObject]?, context: UnsafeMutablePointer<Void>) {
        guard keyPath != nil else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
            return
        }
        switch (keyPath!, context) {
        case("state", &Peripheral.CBPeripheralStateKVOContext):
            if let change = change, newValue = change[NSKeyValueChangeNewKey], oldValue = change[NSKeyValueChangeOldKey], newRawState = newValue as? Int, oldRawState = oldValue as? Int, newState = CBPeripheralState(rawValue: newRawState) {
                if newRawState != oldRawState {
                    self.willChangeValueForKey("state")
                    self.state = newState
                    self.didChangeValueForKey("state")
                }
            }
        default:
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }

    // MARK: RSSI
    public func readRSSI() -> Future<Int> {
        Logger.debug("name = \(self.name), uuid = \(self.identifier.UUIDString)")
        self.readRSSIPromise = Promise<Int>()
        self.readRSSIIfConnected()
        return self.readRSSIPromise!.future
    }

    public func startPollingRSSI(period: Double = 10.0, capacity: Int? = nil) -> FutureStream<Int> {
        Logger.debug("name = \(self.name), uuid = \(self.identifier.UUIDString), period = \(period)")
        self.pollRSSIPromise = StreamPromise<Int>(capacity: capacity)
        self.readRSSIIfConnected()
        self.RSSISequence += 1
        self.pollRSSI(period, sequence: self.RSSISequence)
        return pollRSSIPromise!.future
    }

    public func stopPollingRSSI() {
        Logger.debug("name = \(self.name), uuid = \(self.identifier.UUIDString)")
        self.pollRSSIPromise = nil
    }

    // MARK: Connection
    public func reconnect() {
        guard let centralManager = self.centralManager where self.state == .Disconnected  else {
            Logger.debug("peripheral not disconnected \(self.name), \(self.identifier.UUIDString)")
            return
        }
        Logger.debug("reconnect peripheral name=\(self.name), uuid=\(self.identifier.UUIDString)")
        centralManager.connectPeripheral(self)
        self.forcedDisconnect = false
        self.connectionSequence += 1
        self.currentError = .None
        self.timeoutConnection(self.connectionSequence)
    }
     
    public func connect(capacity: Int? = nil, timeoutRetries: UInt? = nil, disconnectRetries: UInt? = nil, connectionTimeout: Double = 10.0) -> FutureStream<(peripheral: Peripheral, connectionEvent: ConnectionEvent)> {
        if self.connectionPromise == nil {
            self.connectionPromise = StreamPromise<(peripheral: Peripheral, connectionEvent: ConnectionEvent)>(capacity:capacity)
        }
        self.timeoutRetries = timeoutRetries
        self.disconnectRetries = disconnectRetries
        self.connectionTimeout = connectionTimeout
        Logger.debug("connect peripheral \(self.name)', \(self.identifier.UUIDString)")
        self.reconnect()
        return self.connectionPromise!.future
    }
    
    public func disconnect() {
        guard let central = self.centralManager else {
            return
        }
        self.forcedDisconnect = true
        self.stopPollingRSSI()
        if self.state == .Connected {
            Logger.debug("disconnecting name=\(self.name), uuid=\(self.identifier.UUIDString)")
            central.cancelPeripheralConnection(self)
        } else {
            Logger.debug("already disconnected name=\(self.name), uuid=\(self.identifier.UUIDString)")
            self.didDisconnectPeripheral(BCError.peripheralDisconnected)
        }
    }
    
    public func terminate() {
        guard let central = self.centralManager else {
            return
        }
        central.discoveredPeripherals.removeValueForKey(self.cbPeripheral.identifier)
        self.disconnect()
    }

    // MARK: Discover Services
    public func discoverAllServices(timeout: Double = Peripheral.DefaultServiceScanTimeout) -> Future<Peripheral> {
        Logger.debug("uuid=\(self.identifier.UUIDString), name=\(self.name)")
        return self.discoverServices(nil, timeout: timeout)
    }

    public func discoverServices(services: [CBUUID]?, timeout: Double? = nil) -> Future<Peripheral> {
        Logger.debug(" \(self.name)")
        return self.discoverIfConnected(services, timeout: timeout)
    }
    
    public func discoverAllPeripheralServices(timeout: Double = Peripheral.DefaultServiceScanTimeout) -> Future<Peripheral> {
        return self.discoverPeripheralServices(nil)
    }

    public func discoverPeripheralServices(services: [CBUUID]?, timeout: Double = Peripheral.DefaultServiceScanTimeout) -> Future<Peripheral> {
        let peripheralDiscoveredPromise = Promise<Peripheral>()
        Logger.debug("uuid=\(self.identifier.UUIDString), name=\(self.name)")
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
                    peripheralDiscoveredPromise.failure(BCError.peripheralNoServices)
                }
            }
        }
        servicesDiscoveredFuture.onFailure {(error) in
            peripheralDiscoveredPromise.failure(error)
        }
        return peripheralDiscoveredPromise.future
    }
    
    public func discoverService(head: Service, tail: [Service], promise: Promise<Peripheral>) {
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
    
    public func peripheral(_: CBPeripheral, didReadRSSI RSSI: NSNumber, error: NSError?) {
        self.didReadRSSI(RSSI, error:error)
    }
    
    public func peripheral(_: CBPeripheral, didDiscoverServices error: NSError?) {
        if let services = self.cbPeripheral.getServices() {
            self.didDiscoverServices(services, error:error)
        }
    }
    
    public func peripheral(_: CBPeripheral, didDiscoverIncludedServicesForService service: CBService, error: NSError?) {
        Logger.debug("peripheral name \(self.name)")
    }
    
    public func peripheral(_: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        guard let characteristics = service.getCharacteristics() else {
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
        Logger.debug()
    }
    
    public func peripheral(_: CBPeripheral, didUpdateValueForDescriptor descriptor: CBDescriptor, error: NSError?) {
        Logger.debug()
    }
    
    public func peripheral(_: CBPeripheral, didWriteValueForDescriptor descriptor: CBDescriptor, error: NSError?) {
        Logger.debug()
    }

    // MARK: CBPeripheralDelegate Shims
    internal func didDiscoverCharacteristicsForService(service: CBServiceInjectable, characteristics: [CBCharacteristicInjectable], error: NSError?) {
        Logger.debug("uuid=\(self.identifier.UUIDString), name=\(self.name)")
        if let bcService = self.discoveredServices[service.UUID] {
            bcService.didDiscoverCharacteristics(characteristics, error:error)
            if error == nil {
                for cbCharacteristic in characteristics {
                    self.discoveredCharacteristics[cbCharacteristic.UUID] = bcService.discoveredCharacteristics[cbCharacteristic.UUID]
                }
            }
        }
    }
    
    internal func didDiscoverServices(discoveredServices: [CBServiceInjectable], error: NSError?) {
        Logger.debug("uuid=\(self.identifier.UUIDString), name=\(self.name)")
        self.clearAll()
        self.serviceDiscoveryInProgress = false
        if let error = error {
            self.servicesDiscoveredPromise?.failure(error)
        } else {
            for service in discoveredServices {
                let bcService = Service(cbService:service, peripheral:self)
                self.discoveredServices[bcService.UUID] = bcService
                Logger.debug("uuid=\(bcService.UUID.UUIDString), name=\(bcService.name)")
            }
            self.servicesDiscoveredPromise?.success(self)
        }
    }
    
    internal func didUpdateNotificationStateForCharacteristic(characteristic: CBCharacteristicInjectable, error: NSError?) {
        Logger.debug()
        if let bcCharacteristic = self.discoveredCharacteristics[characteristic.UUID] {
            Logger.debug("uuid=\(bcCharacteristic.UUID.UUIDString), name=\(bcCharacteristic.name)")
            bcCharacteristic.didUpdateNotificationState(error)
        }
    }
    
    internal func didUpdateValueForCharacteristic(characteristic: CBCharacteristicInjectable, error: NSError?) {
        Logger.debug()
        if let bcCharacteristic = self.discoveredCharacteristics[characteristic.UUID] {
            Logger.debug("uuid=\(bcCharacteristic.UUID.UUIDString), name=\(bcCharacteristic.name)")
            bcCharacteristic.didUpdate(error)
        }
    }
    
    internal func didWriteValueForCharacteristic(characteristic: CBCharacteristicInjectable, error: NSError?) {
        Logger.debug()
        if let bcCharacteristic = self.discoveredCharacteristics[characteristic.UUID] {
            Logger.debug("uuid=\(bcCharacteristic.UUID.UUIDString), name=\(bcCharacteristic.name)")
            bcCharacteristic.didWrite(error)
        }
    }

    internal func didReadRSSI(RSSI: NSNumber, error: NSError?) {
        if let error = error {
            Logger.debug("RSSI read failed: \(error.localizedDescription)")
            self.readRSSIPromise?.failure(error)
            self.pollRSSIPromise?.failure(error)
        } else {
            Logger.debug("RSSI = \(RSSI.stringValue), peripheral name = \(self.name), uuid=\(self.identifier.UUIDString), state = \(self.state.rawValue)")
            self.RSSI = RSSI.integerValue
            self.readRSSIPromise?.success(RSSI.integerValue)
            self.pollRSSIPromise?.success(RSSI.integerValue)
        }
    }

    // MARK: CBCentralManagerDelegate Shims
    internal func didConnectPeripheral() {
        Logger.debug("uuid=\(self.identifier.UUIDString), name=\(self.name)")
        self.connectedAt = NSDate()
        self.disconnectedAt = nil
        self.connectionPromise?.success((self, .Connect))
    }

    internal func didDisconnectPeripheral(error: NSError?) {
        self.disconnectedAt = NSDate()
        self.totalSecondsConnected += self.secondsConnected
        self.serviceDiscoveryInProgress = false
        switch(self.currentError) {
        case .None:
            if let error = error {
                Logger.debug("disconnecting with errors uuid=\(self.identifier.UUIDString), name=\(self.name), error=\(error.localizedDescription)")
                self.shouldFailOrGiveUp(error)
            } else if (self.forcedDisconnect) {
                Logger.debug("disconnect forced uuid=\(self.identifier.UUIDString), name=\(self.name)")
                self.forcedDisconnect = false
                self.connectionPromise?.success((self, .ForceDisconnect))
            } else  {
                Logger.debug("disconnecting with no errors uuid=\(self.identifier.UUIDString), name=\(self.name)")
                self.shouldDisconnectOrGiveup()
            }
        case .Timeout:
            Logger.debug("timeout uuid=\(self.identifier.UUIDString), name=\(self.name)")
            self.shouldTimeoutOrGiveup()
        }
        for service in self.services {
            service.didDisconnectPeripheral(error)
        }
    }

    internal func didFailToConnectPeripheral(error: NSError?) {
        self.didDisconnectPeripheral(error)
    }

    // MARK: CBPeripheral Delegation
    internal func setNotifyValue(state: Bool, forCharacteristic characteristic: Characteristic) {
        self.cbPeripheral.setNotifyValue(state, forCharacteristic:characteristic.cbCharacteristic)
    }
    
    internal func readValueForCharacteristic(characteristic: Characteristic) {
        self.cbPeripheral.readValueForCharacteristic(characteristic.cbCharacteristic)
    }
    
    internal func writeValue(value: NSData, forCharacteristic characteristic: Characteristic, type: CBCharacteristicWriteType = .WithResponse) {
            self.cbPeripheral.writeValue(value, forCharacteristic:characteristic.cbCharacteristic, type:type)
    }
    
    internal func discoverCharacteristics(characteristics: [CBUUID]?, forService service: Service) {
        self.cbPeripheral.discoverCharacteristics(characteristics, forService:service.cbService)
    }

    // MARK: Utilities
    private func shouldFailOrGiveUp(error: NSError) {
        Logger.debug("name=\(self.name), uuid=\(self.identifier.UUIDString), disconnectCount=\(self.disconnectionCount), disconnectRetries=\(self.disconnectRetries)")
        if let disconnectRetries = self.disconnectRetries {
            if self.disconnectionCount < disconnectRetries {
                self.disconnectionCount += 1
                self.connectionPromise?.failure(error)
            } else {
                self.disconnectionCount = 0
                self.connectionPromise?.success((self, ConnectionEvent.GiveUp))
            }
        } else {
            self.connectionPromise?.failure(error)
        }
    }

    private func shouldTimeoutOrGiveup() {
        Logger.debug("name=\(self.name), uuid=\(self.identifier.UUIDString), timeoutCount=\(self.timeoutCount), timeoutRetries=\(self.timeoutRetries)")
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
        Logger.debug("name=\(self.name), uuid=\(self.identifier.UUIDString), disconnectCount=\(self.disconnectionCount), disconnectRetries=\(self.disconnectRetries)")
        if let disconnectRetries = self.disconnectRetries {
            if self.disconnectionCount < disconnectRetries {
                self.disconnectionCount += 1
                self.connectionPromise?.success((self, .Disconnect))
            } else {
                self.disconnectionCount = 0
                self.connectionPromise?.success((self, .GiveUp))
            }
        } else {
            self.connectionPromise?.success((self, .Disconnect))
        }
    }

    private func discoverIfConnected(services: [CBUUID]?, timeout: Double? = nil)  -> Future<Peripheral> {
        if !self.serviceDiscoveryInProgress {
            self.servicesDiscoveredPromise = Promise<Peripheral>()
            if self.state == .Connected {
                self.serviceDiscoveryInProgress = true
                self.serviceDiscoverySequence += 1
                self.timeoutServiceDiscovery(self.serviceDiscoverySequence, timeout: timeout)
                self.cbPeripheral.discoverServices(services)
            } else {
                self.servicesDiscoveredPromise?.failure(BCError.peripheralDisconnected)
            }
            return self.servicesDiscoveredPromise!.future
        } else {
            let promise = Promise<Peripheral>()
            promise.failure(BCError.peripheralServiceDiscoveryInProgress)
            return promise.future
        }
    }

    private func clearAll() {
        self.discoveredServices.removeAll()
        self.discoveredCharacteristics.removeAll()
    }

    private func timeoutConnection(sequence: Int) {
        guard let centralManager = self.centralManager else {
            return
        }
        Logger.debug("name = \(self.name), uuid = \(self.identifier.UUIDString), sequence = \(sequence), timeout = \(self.connectionTimeout)")
        Peripheral.pollQueue.delay(self.connectionTimeout) {
            if self.state != .Connected && sequence == self.connectionSequence && !self.forcedDisconnect {
                Logger.debug("connection timing out name = \(self.name), UUID = \(self.identifier.UUIDString), sequence=\(sequence), current connectionSequence=\(self.connectionSequence)")
                self.currentError = .Timeout
                centralManager.cancelPeripheralConnection(self)
            } else {
                Logger.debug("connection timeout expired name = \(self.name), uuid = \(self.identifier.UUIDString), sequence = \(sequence), current connectionSequence=\(self.connectionSequence), state=\(self.state.rawValue)")
            }
        }
    }

    private func timeoutServiceDiscovery(sequence: Int, timeout: Double?) {
        guard let centralManager = self.centralManager, timeout = timeout else {
            return
        }
        Logger.debug("name = \(self.name), uuid = \(self.identifier.UUIDString), sequence = \(sequence), timeout = \(timeout)")
        Peripheral.pollQueue.delay(timeout) {
            if sequence == self.serviceDiscoverySequence && self.serviceDiscoveryInProgress {
                Logger.debug("service scan timing out name = \(self.name), UUID = \(self.identifier.UUIDString), sequence=\(sequence), current sequence=\(self.serviceDiscoverySequence)")
                centralManager.cancelPeripheralConnection(self)
                self.serviceDiscoveryInProgress = false
                self.servicesDiscoveredPromise?.failure(BCError.peripheralServiceDiscoveryTimeout)
            } else {
                Logger.debug("service scan timeout expired name = \(self.name), uuid = \(self.identifier.UUIDString), sequence = \(sequence), current sequence = \(self.serviceDiscoverySequence)")
            }
        }
    }

    private func pollRSSI(period: Double, sequence: Int) {
        Logger.debug("name = \(self.name), uuid = \(self.identifier.UUIDString), period = \(period), sequence = \(sequence), current sequence = \(self.RSSISequence)")
        guard self.pollRSSIPromise != nil && sequence == self.RSSISequence else {
            Logger.debug("exiting: name = \(self.name), uuid = \(self.identifier.UUIDString), sequence = \(sequence), current sequence = \(self.RSSISequence)")
            return
        }
        Peripheral.pollQueue.delay(period) {
            Logger.debug("trigger: name = \(self.name), uuid = \(self.identifier.UUIDString), sequence = \(sequence), current sequence = \(self.RSSISequence)")
            self.readRSSIIfConnected()
            self.pollRSSI(period, sequence: sequence)
        }
    }

    private func readRSSIIfConnected() {
        if self.state == .Connected {
            self.cbPeripheral.readRSSI()
        } else {
            self.readRSSIPromise?.failure(BCError.peripheralDisconnected)
            self.pollRSSIPromise?.failure(BCError.peripheralDisconnected)
        }
    }


}
