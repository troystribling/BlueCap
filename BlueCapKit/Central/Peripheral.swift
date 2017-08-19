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

public struct PeripheralAdvertisements {
    
    let advertisements: [String : Any]
    
    public var localName: String? {
        return self.advertisements[CBAdvertisementDataLocalNameKey] as? String
    }
    
    public var manufacturerData: Data? {
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

    fileprivate var servicesDiscoveredPromise: Promise<Void>?
    fileprivate var readRSSIPromise: Promise<Int>?
    fileprivate var pollRSSIPromise: StreamPromise<Int>?
    fileprivate var connectionPromise: StreamPromise<Void>?

    fileprivate let profileManager: ProfileManager?

    var _RSSI: Int = 0
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

    var centralQueue: Queue {
        return centralManager!.centralQueue
    }

    var discoveredServices = [CBUUID : [Service]]()

    let cbPeripheral: CBPeripheralInjectable
    
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
        return cbPeripheral.name ?? "Unknown"
    }

    public var services: [Service] {
        return centralQueue.sync  { return Array(self.discoveredServices.values).flatMap { $0 } }
    }
    
    public var identifier: UUID {
        return cbPeripheral.identifier
    }

    public func services(withUUID uuid: CBUUID) -> [Service]? {
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
        super.init()
        self._RSSI = RSSI
        self.cbPeripheral.delegate = self
    }

    internal init(cbPeripheral: CBPeripheralInjectable, centralManager: CentralManager, profileManager: ProfileManager? = nil) {
        self.cbPeripheral = cbPeripheral
        self.centralManager = centralManager
        self.advertisements = PeripheralAdvertisements(advertisements: [String : AnyObject]())
        self.profileManager = profileManager
        super.init()
        self._RSSI = 0
        self.cbPeripheral.delegate = self
    }

    internal init(cbPeripheral: CBPeripheralInjectable, bcPeripheral: Peripheral, profileManager: ProfileManager? = nil) {
        self.cbPeripheral = cbPeripheral
        self.advertisements = bcPeripheral.advertisements
        self.centralManager = bcPeripheral.centralManager
        self.profileManager = profileManager
        super.init()
        self._RSSI = bcPeripheral._RSSI
        self.cbPeripheral.delegate = self
    }

    deinit {
        if cbPeripheral.delegate === self {
            cbPeripheral.delegate = nil
        }
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
     
    public func connect(connectionTimeout: TimeInterval = TimeInterval.infinity, capacity: Int = Int.max) -> FutureStream<Void> {
        return centralQueue.sync {
            self.connectionPromise = StreamPromise<Void>(capacity: capacity)
            self.connectionTimeout = connectionTimeout
            Logger.debug("connect peripheral \(self.name)', \(self.identifier.uuidString)")
            self.reconnectIfNotConnected()
            return self.connectionPromise!.stream
        }
    }
    
    public func terminate() {
        guard let centralManager = centralManager else {
            return
        }
        centralManager.removePeripheral(withIdentifier: identifier)
        self.disconnect()
    }

    public func disconnect() {
        centralQueue.sync { self.forceDisconnect() }
    }

    fileprivate func reconnectIfNotConnected(_ delay: Double = 0.0) {
        guard let centralManager = centralManager, state != .connected  else {
            Logger.debug("peripheral not disconnected \(name), \(identifier.uuidString)")
            return
        }
        Logger.debug("reconnect peripheral name=\(name), uuid=\(identifier.uuidString)")
        func performConnection(_ peripheral: Peripheral) {
            centralManager.connect(cbPeripheral)
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

    func cancelPeripheralConnection(withTerminationStatus terminationStatus: PeripheralTerminationStatus) {
        guard let central = self.centralManager else {
            return
        }
        pollRSSIPromise = nil
        readRSSIPromise = nil
        self.terminationStatus = terminationStatus
        Logger.debug("disconnecting name=\(self.name), uuid=\(identifier.uuidString)")
        central.cancelPeripheralConnection(cbPeripheral)
    }

    // MARK: Discover Services

    public func discoverAllServices(timeout: TimeInterval = TimeInterval.infinity) -> Future<Void> {
        Logger.debug("uuid=\(identifier.uuidString), name=\(self.name)")
        return self.discoverServices(nil, timeout: timeout)
    }

    public func discoverServices(_ services: [CBUUID]?, timeout: TimeInterval = TimeInterval.infinity) -> Future<Void> {
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
        guard let services = cbPeripheral.getServices() else {
            return
        }
        didDiscoverServices(services, error: error)
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
        guard let bcService = self.serviceWithCBService(service) else {
            Logger.debug("service not found peripheral name=\(self.name), peripheral uuid=\(identifier.uuidString), service uuid \(service.uuid)")
            return
        }
        Logger.debug("peripheral name=\(self.name), peripheral uuid=\(identifier.uuidString), service name \(bcService.name), characteristic count \(characteristics.count)")
        bcService.didDiscoverCharacteristics(characteristics, error: error)
    }
    
    internal func didDiscoverServices(_ services: [CBServiceInjectable], error: Error?) {
        Logger.debug("peripheral name=\(self.name), peripheral uuid=\(identifier.uuidString), service count \(discoveredServices.count)")
        discoveredServices.removeAll()
        if let error = error {
            if let servicesDiscoveredPromise = self.servicesDiscoveredPromise, !servicesDiscoveredPromise.completed {
                servicesDiscoveredPromise.failure(error)
            }
        } else {
            services.forEach { cbService in
                let serviceProfile = profileManager?.services[cbService.uuid]
                let bcService = Service(cbService: cbService, peripheral: self, profile: serviceProfile)
                Logger.debug("service uuid=\(cbService.uuid.uuidString), service name=\(bcService.name), peripheral name=\(self.name), peripheral uuid=\(identifier.uuidString)")
                if let bcServices = discoveredServices[cbService.uuid] {
                    discoveredServices[cbService.uuid] = bcServices + [bcService]
                } else {
                    discoveredServices[cbService.uuid] = [bcService]
                }
            }
            if let servicesDiscoveredPromise = servicesDiscoveredPromise, !servicesDiscoveredPromise.completed {
                 servicesDiscoveredPromise.success(())
            }
        }
    }
    
    internal func didUpdateNotificationStateForCharacteristic(_ characteristic: CBCharacteristicInjectable, error: Error?) {
        guard let bcCharacteristic = characteristicWithCBCharacteristic(characteristic) else {
            Logger.debug("characteristic not found uuid=\(characteristic.uuid.uuidString)")
            return
        }
        Logger.debug("uuid=\(characteristic.uuid.uuidString), name=\(bcCharacteristic.name)")
        bcCharacteristic.didUpdateNotificationState(error)
    }
    
    internal func didUpdateValueForCharacteristic(_ characteristic: CBCharacteristicInjectable, error: Error?) {
        guard let bcCharacteristic = characteristicWithCBCharacteristic(characteristic) else {
            Logger.debug("characteristic not found uuid=\(characteristic.uuid.uuidString)")
            return
        }
        Logger.debug("uuid=\(characteristic.uuid.uuidString), name=\(bcCharacteristic.name)")
        bcCharacteristic.didUpdate(error)
    }

    internal func didWriteValueForCharacteristic(_ characteristic: CBCharacteristicInjectable, error: Error?) {
        guard let bcCharacteristic = characteristicWithCBCharacteristic(characteristic) else {
            Logger.debug("characteristic not found uuid=\(characteristic.uuid.uuidString)")
            return
        }
        Logger.debug("uuid=\(characteristic.uuid.uuidString), name=\(bcCharacteristic.name)")
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
            Logger.debug("RSSI = \(RSSI.stringValue), peripheral name = \(self.name), uuid=\(identifier.uuidString), state = \(self.state.rawValue)")
            self._RSSI = RSSI.intValue
            if let completed = self.readRSSIPromise?.completed, !completed {
                self.readRSSIPromise?.success(RSSI.intValue)
            }
            self.pollRSSIPromise?.success(RSSI.intValue)
        }
    }

    // MARK: CBCentralManagerDelegate Shims

    func didConnectPeripheral() {
        Logger.debug("uuid=\(identifier.uuidString), name=\(self.name)")
        _connectedAt = Date()
        _disconnectedAt = nil
        connectionPromise?.success(())
    }

    func didDisconnectPeripheral(_ error: Swift.Error?) {
        _disconnectedAt = Date()
        _totalSecondsConnected += _secondsConnected
        switch(terminationStatus) {
        case .connected:
            _disconnectionCount += 1
            if let error = error {
                Logger.debug("disconnecting with errors uuid=\(identifier.uuidString), name=\(self.name), error=\(error.localizedDescription), disconnection count=\(_disconnectionCount) ")
                connectionPromise?.failure(error)
            } else  {
                Logger.debug("disconnecting with no errors uuid=\(identifier.uuidString), name=\(self.name)")
                self.connectionPromise?.failure(PeripheralError.disconnected)
            }
        case .forcedDisconnect:
            Logger.debug("disconnect forced uuid=\(identifier.uuidString), name=\(self.name)")
            connectionPromise?.failure(PeripheralError.forcedDisconnect)
        case .timeout:
            _timeoutCount += 1
            Logger.debug("timeout connection uuid=\(identifier.uuidString), name=\(self.name), timeout count=\(_timeoutCount)")
            connectionPromise?.failure(PeripheralError.connectionTimeout)
        }
        for service in Array(discoveredServices.values).flatMap({ $0 }) {
            service.didDisconnectPeripheral(error)
        }
    }

    internal func didFailToConnectPeripheral(_ error: Swift.Error?) {
        didDisconnectPeripheral(error)
    }

    // MARK: CBPeripheral Delegation

    internal func setNotifyValue(_ state: Bool, forCharacteristic characteristic: CBCharacteristicInjectable) {
        cbPeripheral.setNotifyValue(state, forCharacteristic:characteristic)
    }
    
    internal func readValueForCharacteristic(_ characteristic: CBCharacteristicInjectable) {
        cbPeripheral.readValueForCharacteristic(characteristic)
    }
    
    internal func writeValue(_ value: Data, forCharacteristic characteristic: CBCharacteristicInjectable, type: CBCharacteristicWriteType = .withResponse) {
        cbPeripheral.writeValue(value, forCharacteristic:characteristic, type: type)
    }
    
    internal func discoverCharacteristics(_ characteristics: [CBUUID]?, forService service: CBServiceInjectable) {
        cbPeripheral.discoverCharacteristics(characteristics, forService: service)
    }

    // MARK: Utilities

    fileprivate func serviceWithCBService(_ cbService: CBServiceInjectable) -> Service? {
        return Array(self.discoveredServices.values).flatMap { $0 }.filter { $0.cbService === cbService }.first
    }

    fileprivate func characteristicWithCBCharacteristic(_ cbCharacteristic: CBCharacteristicInjectable) -> Characteristic? {
        guard let discoveredCBServices = cbPeripheral.getServices() else {
            return nil
        }
        for discoveredCBService in discoveredCBServices {
            guard let discoveredCBCharacteristics = discoveredCBService.getCharacteristics() else {
                continue
            }
            for discoveredCBCharacteristic in discoveredCBCharacteristics {
                if discoveredCBCharacteristic === cbCharacteristic {
                    guard let bcService = self.serviceWithCBService(discoveredCBService) else {
                        return nil
                    }
                    return Array(bcService.discoveredCharacteristics.values).flatMap { $0 }.filter { $0.cbCharacteristic === cbCharacteristic }.first
                }
            }
        }
        return nil
    }

    fileprivate func discoverIfConnected(_ services: [CBUUID]?, timeout: TimeInterval = TimeInterval.infinity)  -> Future<Void> {
        return centralQueue.sync {
            if let servicesDiscoveredPromise = self.servicesDiscoveredPromise, !servicesDiscoveredPromise.completed {
                return servicesDiscoveredPromise.future
            }
            self.servicesDiscoveredPromise = Promise<Void>()
            if self.state == .connected {
                self.serviceDiscoverySequence += 1
                self.discoveredServices.removeAll()
                self.timeoutServiceDiscovery(self.serviceDiscoverySequence, timeout: timeout)
                self.cbPeripheral.discoverServices(services)
            } else {
                self.servicesDiscoveredPromise?.failure(PeripheralError.disconnected)
            }
            return self.servicesDiscoveredPromise!.future
        }
    }

    fileprivate func timeoutConnection(_ sequence: Int) {
        guard connectionTimeout < TimeInterval.infinity else {
            return
        }
        Logger.debug("name = \(self.name), uuid = \(identifier.uuidString), sequence = \(sequence), timeout = \(self.connectionTimeout)")
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
        Logger.debug("name = \(self.name), uuid = \(identifier.uuidString), sequence = \(sequence), timeout = \(timeout)")
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
        Logger.debug("name = \(self.name), uuid = \(identifier.uuidString), period = \(period)")
        guard self.pollRSSIPromise != nil else {
            Logger.debug("exiting: name = \(self.name), uuid = \(identifier.uuidString)")
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
            cbPeripheral.readRSSI()
        } else {
            self.readRSSIPromise?.failure(PeripheralError.disconnected)
            self.pollRSSIPromise?.failure(PeripheralError.disconnected)
        }
    }

}
