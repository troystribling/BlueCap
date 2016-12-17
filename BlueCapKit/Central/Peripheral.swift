//
//  Peripheral.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/8/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import Foundation
import CoreBluetooth

// MARK - PeripheralTerminationStatus -
enum PeripheralTerminationStatus {
    case connected, timeout, forcedDisconnect
}

// MARK: - PeripheralAdvertisements -

public extension CBPeripheralState {
    public var stringValue: String {
        switch self {
        case .disconnected:
            return "disconnected"
        case .connected:
            return "connected"
        case .disconnecting:
            return "disconnecting"
        case .connecting:
            return "connecting"
        }
    }
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
    
    public var serviceData: [CBUUID : Data]? {
        return self.advertisements[CBAdvertisementDataServiceDataKey] as? [CBUUID : Data]
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

    static var RECONNECT_DELAY = TimeInterval(1.0)

    fileprivate var servicesDiscoveredPromise: Promise<Peripheral>?
    fileprivate var readRSSIPromise: Promise<Int>?
    fileprivate var pollRSSIPromise: StreamPromise<Int>?
    fileprivate var connectionPromise: StreamPromise<Peripheral>?

    fileprivate let profileManager: ProfileManager?

    fileprivate var _RSSI: Int = 0
    fileprivate var _state = CBPeripheralState.disconnected

    fileprivate var _timeoutCount: UInt = 0
    fileprivate var _disconnectionCount: UInt = 0

    fileprivate var connectionSequence = 0
    fileprivate var serviceDiscoverySequence = 0
    fileprivate var terminationStatus = PeripheralTerminationStatus.connected

    fileprivate var _connectedAt: Date?
    fileprivate var _disconnectedAt : Date?
    fileprivate var _totalSecondsConnected = 0.0

    fileprivate var connectionTimeout = TimeInterval.infinity
    fileprivate var timeoutRetries = UInt.max
    fileprivate var disconnectRetries = UInt.max

    fileprivate(set) weak var centralManager: CentralManager?

    let centralQueue: Queue
    var discoveredServices = [CBUUID : Service]()
    var discoveredCharacteristics = [CBUUID : Characteristic]()

    internal fileprivate(set) var cbPeripheral: CBPeripheralInjectable
    public private(set) var advertisements: PeripheralAdvertisements
    public let discoveredAt = Date()

    // MARK: Private Properties

    fileprivate var _secondsConnected: Double {
        if let disconnectedAt = self._disconnectedAt, let connectedAt = self._connectedAt {
            return disconnectedAt.timeIntervalSince(connectedAt)
        } else if let connectedAt = self._connectedAt {
            return Date().timeIntervalSince(connectedAt)
        } else {
            return 0.0
        }
    }

    // MARK: Public Properties

    public var RSSI: Int {
        return centralQueue.sync { return self._RSSI }
    }

    public var connectedAt: Date? {
        return centralQueue.sync { return self._connectedAt }
    }

    public var disconnectedAt: Date? {
        return centralQueue.sync { return self._disconnectedAt }
    }

    public var timeoutCount: UInt {
        return centralQueue.sync  { return self._timeoutCount }
    }

    public var disconnectionCount: UInt {
        return centralQueue.sync { return self._disconnectionCount }
    }

    public var connectionCount: UInt {
        return centralQueue.sync { return UInt(self.connectionSequence) }
    }

    public var secondsConnected: TimeInterval {
        return centralQueue.sync { return self._secondsConnected }
    }

    public var totalSecondsConnected: TimeInterval {
        return centralQueue.sync { return self._totalSecondsConnected }
    }

    public var cumlativeSecondsConnected: TimeInterval {
        return self.disconnectedAt != nil ? self.totalSecondsConnected : self.totalSecondsConnected + self.secondsConnected
    }

    public var cumlativeSecondsDisconnected: TimeInterval {
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
        return centralQueue.sync  { return Array(self.discoveredServices.values) }
    }
    
    public var identifier: UUID {
        return self.cbPeripheral.identifier as UUID
    }

    public func service(_ uuid: CBUUID) -> Service? {
        return centralQueue.sync { return self.discoveredServices[uuid] }
    }

    public var state: CBPeripheralState {
        return cbPeripheral.state
    }

    // MARK: Initializers

    internal init(cbPeripheral: CBPeripheralInjectable, centralManager: CentralManager, advertisements: [String : Any], RSSI: Int, profileManager: ProfileManager? = nil) {
        self.cbPeripheral = cbPeripheral
        self.centralManager = centralManager
        self.advertisements = PeripheralAdvertisements(advertisements: advertisements)
        self.profileManager = profileManager
        self.centralQueue = centralManager.centralQueue
        super.init()
        self._RSSI = RSSI
        self.cbPeripheral.delegate = self
    }

    internal init(cbPeripheral: CBPeripheralInjectable, centralManager: CentralManager, profileManager: ProfileManager? = nil) {
        self.cbPeripheral = cbPeripheral
        self.centralManager = centralManager
        self.advertisements = PeripheralAdvertisements(advertisements: [String : AnyObject]())
        self.profileManager = profileManager
        self.centralQueue = centralManager.centralQueue
        super.init()
        self._RSSI = 0
        self.cbPeripheral.delegate = self
    }

    internal init(cbPeripheral: CBPeripheralInjectable, bcPeripheral: Peripheral, profileManager: ProfileManager? = nil) {
        self.cbPeripheral = cbPeripheral
        self.advertisements = bcPeripheral.advertisements
        self.centralManager = bcPeripheral.centralManager
        self.centralQueue = bcPeripheral.centralManager!.centralQueue
        self.profileManager = profileManager
        super.init()
        self._RSSI = bcPeripheral._RSSI
        self.cbPeripheral.delegate = self
    }

    deinit {
        self.cbPeripheral.delegate = nil
    }

    // MARK: RSSI

    public func readRSSI() -> Future<Int> {
        return centralQueue.sync {
            if let readRSSIPromise = self.readRSSIPromise, !readRSSIPromise.completed {
                return readRSSIPromise.future
            }
            Logger.debug("name = \(self.name), uuid = \(self.identifier.uuidString)")
            self.readRSSIPromise = Promise<Int>()
            self.readRSSIIfConnected()
            return self.readRSSIPromise!.future
        }
    }

    public func startPollingRSSI(period: Double = 10.0, capacity: Int = Int.max) -> FutureStream<Int> {
        return centralQueue.sync {
            if let pollRSSIPromise = self.pollRSSIPromise {
                return pollRSSIPromise.stream
            }
            Logger.debug("name = \(self.name), uuid = \(self.identifier.uuidString), period = \(period)")
            self.pollRSSIPromise = StreamPromise<Int>(capacity: capacity)
            self.readRSSIIfConnected()
            self.pollRSSI(period)
            return self.pollRSSIPromise!.stream
        }
    }

    public func stopPollingRSSI() {
        centralQueue.sync {
            Logger.debug("name = \(self.name), uuid = \(self.identifier.uuidString)")
            self.pollRSSIPromise = nil
        }
    }

    // MARK: Connection

    public func reconnect(withDelay delay: TimeInterval = 0.0) {
        centralQueue.sync {
            self.reconnectIfNotConnected(delay)
        }
    }
     
    public func connect(timeoutRetries: UInt = 0, disconnectRetries: UInt = 0, connectionTimeout: TimeInterval = TimeInterval.infinity, capacity: Int = Int.max) -> FutureStream<Peripheral> {
        return centralQueue.sync {
            self.connectionPromise = StreamPromise<Peripheral>(capacity: capacity)
            self.timeoutRetries = timeoutRetries
            self.disconnectRetries = disconnectRetries
            self.connectionTimeout = connectionTimeout
            Logger.debug("connect peripheral \(self.name)', \(self.identifier.uuidString)")
            self.reconnectIfNotConnected()
            return self.connectionPromise!.stream
        }
    }
    
    public func terminate() {
        guard let central = self.centralManager else {
            return
        }
        central.removePeripheral(withIdentifier: self.cbPeripheral.identifier)
        if self.state == .connected {
            self.disconnect()
        }
    }

    public func disconnect() {
        centralQueue.sync { self.forceDisconnect() }
    }

    fileprivate func reconnectIfNotConnected(_ delay: Double = 0.0) {
        guard let centralManager = self.centralManager , state != .connected  else {
            Logger.debug("peripheral not disconnected \(name), \(identifier.uuidString)")
            return
        }
        Logger.debug("reconnect peripheral name=\(name), uuid=\(identifier.uuidString)")
        func performConnection(_ peripheral: Peripheral) {
            centralManager.connect(peripheral)
            peripheral.connectionSequence += 1
            peripheral.terminationStatus = .connected
            peripheral.timeoutConnection(peripheral.connectionSequence)
        }
        if delay > 0.0 {
            centralManager.centralQueue.delay(delay) { [weak self] in
                self.forEach { performConnection($0) }
            }
        } else {
            performConnection(self)
        }
    }

    func forceDisconnect() {
        cancelPeripheralConnection(withTerminationStatus: .forcedDisconnect)
    }

    fileprivate func cancelPeripheralConnection(withTerminationStatus terminationStatus: PeripheralTerminationStatus) {
        guard let central = self.centralManager else {
            return
        }
        pollRSSIPromise = nil
        readRSSIPromise = nil
        self.terminationStatus = terminationStatus
        if state != .disconnected {
            Logger.debug("disconnecting name=\(self.name), uuid=\(self.identifier.uuidString)")
            central.cancelPeripheralConnection(self)
        } else {
            Logger.debug("already disconnected name=\(self.name), uuid=\(self.identifier.uuidString)")
            didDisconnectPeripheral(PeripheralError.disconnected)
        }
    }

    // MARK: Discover Services

    public func discoverAllServices(timeout: TimeInterval = TimeInterval.infinity) -> Future<Peripheral> {
        Logger.debug("uuid=\(self.identifier.uuidString), name=\(self.name)")
        return self.discoverServices(nil, timeout: timeout)
    }

    public func discoverServices(_ services: [CBUUID]?, timeout: TimeInterval = TimeInterval.infinity) -> Future<Peripheral> {
        Logger.debug(" \(self.name)")
        return self.discoverIfConnected(services, timeout: timeout)
    }
    
    // MARK: CBPeripheralDelegate

    public func peripheralDidUpdateName(_:CBPeripheral) {
        Logger.debug()
    }
    
    public func peripheral(_: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        Logger.debug()
    }

    public func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        didReadRSSI(RSSI, error:error)
    }

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = self.cbPeripheral.getServices() {
            didDiscoverServices(services, error: error)
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverIncludedServicesFor service: CBService, error: Error?) {
        Logger.debug("peripheral name \(self.name)")
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.getCharacteristics() else {
            return
        }
        didDiscoverCharacteristicsForService(service, characteristics: characteristics, error: error)
    }

    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        didUpdateNotificationStateForCharacteristic(characteristic, error: error)
    }

    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        didUpdateValueForCharacteristic(characteristic, error: error)
    }

    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        didWriteValueForCharacteristic(characteristic, error: error)
    }

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        Logger.debug()
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
        Logger.debug()
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
        Logger.debug()
    }

    // MARK: CBPeripheralDelegate Shims

    internal func didDiscoverCharacteristicsForService(_ service: CBServiceInjectable, characteristics: [CBCharacteristicInjectable], error: Error?) {
        Logger.debug("uuid=\(identifier.uuidString), name=\(name)")
        if let bcService = self.discoveredServices[service.uuid] {
            bcService.didDiscoverCharacteristics(characteristics, error: error)
            if error == nil {
                for cbCharacteristic in characteristics {
                    discoveredCharacteristics[cbCharacteristic.uuid] = bcService.discoveredCharacteristics[cbCharacteristic.uuid]
                }
            }
        }
    }
    
    internal func didDiscoverServices(_ discoveredServices: [CBServiceInjectable], error: Error?) {
        Logger.debug("uuid=\(self.identifier.uuidString), name=\(self.name)")
        self.clearAll()
        if let error = error {
            if let servicesDiscoveredPromise = self.servicesDiscoveredPromise, !servicesDiscoveredPromise.completed {
                self.servicesDiscoveredPromise?.failure(error)
            }
        } else {
            for service in discoveredServices {
                let serviceProfile = profileManager?.services[service.uuid]
                let bcService = Service(cbService: service, peripheral: self, profile: serviceProfile)
                self.discoveredServices[bcService.uuid] = bcService
                Logger.debug("uuid=\(bcService.uuid.uuidString), name=\(bcService.name)")
            }
            if let servicesDiscoveredPromise = self.servicesDiscoveredPromise, !servicesDiscoveredPromise.completed {
                self.servicesDiscoveredPromise?.success(self)
            }
        }
    }
    
    internal func didUpdateNotificationStateForCharacteristic(_ characteristic: CBCharacteristicInjectable, error: Error?) {
        guard let bcCharacteristic = self.discoveredCharacteristics[characteristic.uuid] else {
            Logger.debug("characteristic not found uuid=\(characteristic.uuid.uuidString)")
            return
        }
        Logger.debug("uuid=\(bcCharacteristic.uuid.uuidString), name=\(bcCharacteristic.name)")
        bcCharacteristic.didUpdateNotificationState(error)
    }
    
    internal func didUpdateValueForCharacteristic(_ characteristic: CBCharacteristicInjectable, error: Error?) {
        guard let bcCharacteristic = discoveredCharacteristics[characteristic.uuid] else {
            Logger.debug("characteristic not found uuid=\(characteristic.uuid.uuidString)")
            return
        }
        Logger.debug("uuid=\(bcCharacteristic.uuid.uuidString), name=\(bcCharacteristic.name)")
        bcCharacteristic.didUpdate(error)
    }

    internal func didWriteValueForCharacteristic(_ characteristic: CBCharacteristicInjectable, error: Error?) {
        guard let bcCharacteristic = self.discoveredCharacteristics[characteristic.uuid] else {
            Logger.debug("characteristic not found uuid=\(characteristic.uuid.uuidString)")
            return
        }
        Logger.debug("uuid=\(bcCharacteristic.uuid.uuidString), name=\(bcCharacteristic.name)")
        bcCharacteristic.didWrite(error)
    }

    internal func didReadRSSI(_ RSSI: NSNumber, error: Error?) {
        if let error = error {
            Logger.debug("RSSI read failed: \(error.localizedDescription)")
            if let completed = self.readRSSIPromise?.completed, !completed {
                self.readRSSIPromise?.failure(error)
            }
            self.pollRSSIPromise?.failure(error)
        } else {
            Logger.debug("RSSI = \(RSSI.stringValue), peripheral name = \(self.name), uuid=\(self.identifier.uuidString), state = \(self.state.rawValue)")
            self._RSSI = RSSI.intValue
            if let completed = self.readRSSIPromise?.completed, !completed {
                self.readRSSIPromise?.success(RSSI.intValue)
            }
            self.pollRSSIPromise?.success(RSSI.intValue)
        }
    }

    // MARK: CBCentralManagerDelegate Shims

    internal func didConnectPeripheral() {
        Logger.debug("uuid=\(self.identifier.uuidString), name=\(self.name)")
        _connectedAt = Date()
        _disconnectedAt = nil
        connectionPromise?.success(self)
    }

    internal func didDisconnectPeripheral(_ error: Swift.Error?) {
        _disconnectedAt = Date()
        _totalSecondsConnected += self._secondsConnected
        switch(terminationStatus) {
        case .connected:
            if let error = error {
                Logger.debug("disconnecting with errors uuid=\(self.identifier.uuidString), name=\(self.name), error=\(error.localizedDescription)")
                shouldFailOrReconnect(error)
            } else  {
                Logger.debug("disconnecting with no errors uuid=\(self.identifier.uuidString), name=\(self.name)")
                shouldDisconnectOrReconnect()
            }
        case .forcedDisconnect:
            Logger.debug("disconnect forced uuid=\(self.identifier.uuidString), name=\(self.name)")
            connectionPromise?.failure(PeripheralError.forcedDisconnect)
        case .timeout:
            Logger.debug("timeout uuid=\(self.identifier.uuidString), name=\(self.name)")
            shouldTimeoutOrReconnect()
        }
        for (_ , service) in self.discoveredServices {
            service.didDisconnectPeripheral(error)
        }
    }

    internal func didFailToConnectPeripheral(_ error: Swift.Error?) {
        didDisconnectPeripheral(error)
    }

    // MARK: CBPeripheral Delegation

    internal func setNotifyValue(_ state: Bool, forCharacteristic characteristic: Characteristic) {
        cbPeripheral.setNotifyValue(state, forCharacteristic:characteristic.cbCharacteristic)
    }
    
    internal func readValueForCharacteristic(_ characteristic: Characteristic) {
        cbPeripheral.readValueForCharacteristic(characteristic.cbCharacteristic)
    }
    
    internal func writeValue(_ value: Data, forCharacteristic characteristic: Characteristic, type: CBCharacteristicWriteType = .withResponse) {
        cbPeripheral.writeValue(value, forCharacteristic:characteristic.cbCharacteristic, type:type)
    }
    
    internal func discoverCharacteristics(_ characteristics: [CBUUID]?, forService service: Service) {
        cbPeripheral.discoverCharacteristics(characteristics, forService:service.cbService)
    }

    // MARK: Utilities

    fileprivate func shouldFailOrReconnect(_ error: Swift.Error) {
        Logger.debug("name = \(name), uuid = \(identifier.uuidString), disconnectCount = \(_disconnectionCount), disconnectRetries = \(disconnectRetries)")
            if _disconnectionCount < disconnectRetries {
                _disconnectionCount += 1
                reconnectIfNotConnected(Peripheral.RECONNECT_DELAY)
            } else {
                connectionPromise?.failure(error)
            }
    }

    fileprivate func shouldTimeoutOrReconnect() {
        Logger.debug("name = \(name), uuid = \(identifier.uuidString), timeoutCount = \(_timeoutCount), timeoutRetries = \(timeoutRetries)")
        if _timeoutCount < timeoutRetries {
            _timeoutCount += 1
            reconnectIfNotConnected(Peripheral.RECONNECT_DELAY)
        } else {
            connectionPromise?.failure(PeripheralError.connectionTimeout)
        }
    }

    fileprivate func shouldDisconnectOrReconnect() {
        Logger.debug("name = \(self.name), uuid = \(self.identifier.uuidString), disconnectCount = \(self._disconnectionCount), disconnectRetries = \(self.disconnectRetries)")
        if _disconnectionCount < disconnectRetries {
            _disconnectionCount += 1
            reconnectIfNotConnected(Peripheral.RECONNECT_DELAY)
        } else {
            self.connectionPromise?.failure(PeripheralError.disconnected)
        }
    }

    fileprivate func discoverIfConnected(_ services: [CBUUID]?, timeout: TimeInterval = TimeInterval.infinity)  -> Future<Peripheral> {
        return centralQueue.sync {
            if let servicesDiscoveredPromise = self.servicesDiscoveredPromise, !servicesDiscoveredPromise.completed {
                return servicesDiscoveredPromise.future
            }
            self.servicesDiscoveredPromise = Promise<Peripheral>()
            if self.state == .connected {
                self.serviceDiscoverySequence += 1
                self.discoveredServices.removeAll()
                self.discoveredCharacteristics.removeAll()
                self.timeoutServiceDiscovery(self.serviceDiscoverySequence, timeout: timeout)
                self.cbPeripheral.discoverServices(services)
            } else {
                self.servicesDiscoveredPromise?.failure(PeripheralError.disconnected)
            }
            return self.servicesDiscoveredPromise!.future
        }
    }

    fileprivate func clearAll() {
        self.discoveredServices.removeAll()
        self.discoveredCharacteristics.removeAll()
    }

    fileprivate func timeoutConnection(_ sequence: Int) {
        guard connectionTimeout < TimeInterval.infinity else {
            return
        }
        Logger.debug("name = \(self.name), uuid = \(self.identifier.uuidString), sequence = \(sequence), timeout = \(self.connectionTimeout)")
        centralQueue.delay(self.connectionTimeout) { [weak self] in
            self.forEach { strongSelf in
                if strongSelf.state != .connected && sequence == strongSelf.connectionSequence && strongSelf.terminationStatus == .connected {
                    Logger.debug("connection timing out name = \(strongSelf.name), UUID = \(strongSelf.identifier.uuidString), sequence=\(sequence), current connectionSequence=\(strongSelf.connectionSequence)")
                    strongSelf.cancelPeripheralConnection(withTerminationStatus: .timeout)
                } else {
                    Logger.debug("connection timeout expired name = \(strongSelf.name), uuid = \(strongSelf.identifier.uuidString), sequence = \(sequence), current connectionSequence=\(strongSelf.connectionSequence), state=\(strongSelf.state.rawValue)")
                }
            }
        }
    }

    fileprivate func timeoutServiceDiscovery(_ sequence: Int, timeout: TimeInterval) {
        guard timeout < TimeInterval.infinity else {
            return
        }
        Logger.debug("name = \(self.name), uuid = \(self.identifier.uuidString), sequence = \(sequence), timeout = \(timeout)")
        centralQueue.delay(timeout) { [weak self] in
            self.forEach { strongSelf in
                if let servicesDiscoveredPromise = strongSelf.servicesDiscoveredPromise, sequence == strongSelf.serviceDiscoverySequence && !servicesDiscoveredPromise.completed {
                    Logger.debug("service scan timing out name = \(strongSelf.name), UUID = \(strongSelf.identifier.uuidString), sequence=\(sequence), current sequence=\(strongSelf.serviceDiscoverySequence)")
                    strongSelf.cancelPeripheralConnection(withTerminationStatus: .connected)
                    servicesDiscoveredPromise.failure(PeripheralError.serviceDiscoveryTimeout)
                } else {
                    Logger.debug("service scan timeout expired name = \(strongSelf.name), uuid = \(strongSelf.identifier.uuidString), sequence = \(sequence), current sequence = \(strongSelf.serviceDiscoverySequence)")
                }
            }
        }
    }

    fileprivate func pollRSSI(_ period: Double) {
        Logger.debug("name = \(self.name), uuid = \(self.identifier.uuidString), period = \(period)")
        guard self.pollRSSIPromise != nil else {
            Logger.debug("exiting: name = \(self.name), uuid = \(self.identifier.uuidString)")
            return
        }
        centralQueue.delay(period) { [weak self] in
            self.forEach { strongSelf in
                Logger.debug("name = \(strongSelf.name), uuid = \(strongSelf.identifier.uuidString)")
                strongSelf.readRSSIIfConnected()
                strongSelf.pollRSSI(period)
            }
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
