//
//  CentralManager.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/4/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import Foundation
import CoreBluetooth

// MARK: - CentralManager -

public class CentralManager : NSObject, CBCentralManagerDelegate {

    // MARK: Properties

    fileprivate var afterStateChangedPromise: StreamPromise<ManagerState>?
    fileprivate var afterPeripheralDiscoveredPromise: StreamPromise<Peripheral>?
    fileprivate var afterStateRestoredPromise: Promise<(peripherals: [Peripheral], scannedServices: [CBUUID], options: [String:AnyObject])>?

    fileprivate let options: [String : Any]?
    fileprivate let name: String

    fileprivate var _isScanning = false

    fileprivate let profileManager: ProfileManager?
    fileprivate var _discoveredPeripherals = [UUID : Peripheral]()

    let centralQueue: Queue
    fileprivate(set) var cbCentralManager: CBCentralManagerInjectable!

    fileprivate var scanTimeSequence = 0

    public var discoveredPeripherals : [UUID : Peripheral] {
        return centralQueue.sync { self._discoveredPeripherals }
    }

    public var peripherals: [Peripheral] {
        return Array(discoveredPeripherals.values).sorted { (p1: Peripheral, p2: Peripheral) -> Bool in
            switch p1.discoveredAt.compare(p2.discoveredAt) {
            case .orderedSame:
                return true
            case .orderedDescending:
                return false
            case .orderedAscending:
                return true
            }
        }
    }

    public var isScanning: Bool {
        return centralQueue.sync { return self._isScanning }
    }

    public var poweredOn: Bool {
        return self.cbCentralManager.managerState == .poweredOn
    }

    public var state: ManagerState {
        return cbCentralManager.managerState
    }

    // MARK: Initializers

    public convenience override init() {
        self.init(queue: DispatchQueue(label: "us.gnos.blueCap.central-manager.main", qos: .background), profileManager: nil, options: nil)
    }

    public convenience init(profileManager: ProfileManager? = nil, options: [String : Any]? = nil) {
        self.init(queue: DispatchQueue(label: "us.gnos.blueCap.central-manager.main", qos: .background), profileManager: profileManager, options: options)
    }

    public init(queue: DispatchQueue, profileManager: ProfileManager? = nil, options: [String : Any]? = nil) {
        self.centralQueue = Queue(queue)
        self.profileManager = profileManager
        self.options = options
        self.name = (options?[CBCentralManagerOptionRestoreIdentifierKey] as? String) ?? "unknown"
        super.init()
        self.cbCentralManager = CBCentralManager(delegate: self, queue: self.centralQueue.queue, options: options)
    }

    init(centralManager: CBCentralManagerInjectable, profileManager: ProfileManager? = nil) {
        self.centralQueue = Queue("us.gnos.blueCap.central-manger.main")
        self.profileManager = profileManager
        self.options = nil
        self.name = "unknown"
        super.init()
        self.cbCentralManager = centralManager
    }

    deinit {
        cbCentralManager.delegate = nil
    }

    public func reset()  {
        centralQueue.async {
            self.afterStateChangedPromise = nil
            self.afterPeripheralDiscoveredPromise = nil
            self.afterStateRestoredPromise = nil
            if self.cbCentralManager is CBCentralManager {
                self.cbCentralManager = CBCentralManager(delegate: self, queue: self.centralQueue.queue, options: self.options)
                self.cbCentralManager.delegate = self
            }
        }
    }

    // MARK: Power ON/OFF

    public func whenStateChanges() -> FutureStream<ManagerState> {
        return self.centralQueue.sync {
            self.afterStateChangedPromise = StreamPromise<ManagerState>()
            self.afterStateChangedPromise?.success(self.cbCentralManager.managerState)
            return self.afterStateChangedPromise!.stream
        }
    }

    // MARK: Manage Peripherals

    func connect(_ peripheral: Peripheral, options: [String : Any]? = nil) {
        cbCentralManager.connect(peripheral.cbPeripheral, options: options)
    }
    
    func cancelPeripheralConnection(_ peripheral: Peripheral) {
        cbCentralManager.cancelPeripheralConnection(peripheral.cbPeripheral)
    }

    public func disconnectAllPeripherals() {
        centralQueue.sync {
            for peripheral in self._discoveredPeripherals.values {
                peripheral.forceDisconnect()
            }
        }
    }

    public func removeAllPeripherals() {
        centralQueue.sync { self._discoveredPeripherals.removeAll() }
    }

    public func removePeripheral(withIdentifier identifier: UUID) {
        centralQueue.sync { _ = self._discoveredPeripherals.removeValue(forKey: identifier) }
    }

    // MARK: Scan

    public func startScanning(capacity: Int = Int.max, timeout: TimeInterval = TimeInterval.infinity, options: [String : Any]? = nil) -> FutureStream<Peripheral> {
        return startScanning(forServiceUUIDs: nil, capacity: capacity, timeout: timeout)
    }

    public func startScanning(forServiceUUIDs uuids: [CBUUID]?, capacity: Int = Int.max, timeout: TimeInterval = TimeInterval.infinity, options: [String : Any]? = nil) -> FutureStream<Peripheral> {
        return self.centralQueue.sync {
            if let afterPeripheralDiscoveredPromise = self.afterPeripheralDiscoveredPromise {
                return afterPeripheralDiscoveredPromise.stream
            }
            if !self._isScanning {
                Logger.debug("\(self.name) UUIDs \(uuids)")
                self._isScanning = true
                self.afterPeripheralDiscoveredPromise = StreamPromise<Peripheral>(capacity: capacity)
                if self.poweredOn {
                    self.cbCentralManager.scanForPeripherals(withServices: uuids, options: options)
                    self.timeScan(timeout, sequence: self.scanTimeSequence)
                } else {
                    self.afterPeripheralDiscoveredPromise?.failure(CentralManagerError.isPoweredOff)
                }
            }
            return self.afterPeripheralDiscoveredPromise!.stream
        }
    }
    
    public func stopScanning() {
        self.centralQueue.sync {
            self.stopScanningIfScanning()
        }
    }

    fileprivate func stopScanningIfScanning() {
        guard _isScanning else {
            Logger.debug("\(self.name) is not scanning")
            return
        }
        Logger.debug("\(self.name)")
        _isScanning = false
        cbCentralManager.stopScan()
        afterPeripheralDiscoveredPromise = nil
    }

    fileprivate func timeScan(_ timeout: TimeInterval, sequence: Int) {
        guard timeout < TimeInterval.infinity else {
            return
        }
        Logger.debug("\(self.name) scan timeout in \(timeout)s")
        centralQueue.delay(timeout) { [weak self] in
            self.forEach { strongSelf in
                if strongSelf._isScanning {
                    if sequence == strongSelf.scanTimeSequence {
                        strongSelf.afterPeripheralDiscoveredPromise?.failure(CentralManagerError.serviceScanTimeout)
                    }
                    strongSelf.stopScanningIfScanning()
                }
            }
        }
    }

    // MARK: State Restoration

    public func whenStateRestored() -> Future<(peripherals: [Peripheral], scannedServices: [CBUUID], options: [String:AnyObject])> {
        return centralQueue.sync {
            if let afterStateRestoredPromise = self.afterStateRestoredPromise, !afterStateRestoredPromise.completed {
                return afterStateRestoredPromise.future
            }
            self.afterStateRestoredPromise = Promise<(peripherals: [Peripheral], scannedServices: [CBUUID], options: [String:AnyObject])>()
            return self.afterStateRestoredPromise!.future
        }
    }

    // MARK: Retrieve Peripherals

    public func retrieveConnectedPeripherals(withServices services: [CBUUID]) -> [Peripheral] {
        return centralQueue.sync {
            return self.cbCentralManager.retrieveConnectedPeripherals(withServices: services).map(self.loadRetrievedPeripheral)
        }
    }

    public func retrievePeripherals(withIdentifiers identifiers: [UUID]) -> [Peripheral] {
        return centralQueue.sync {
            return self.cbCentralManager.retrievePeripherals(withIdentifiers: identifiers).map(self.loadRetrievedPeripheral)
        }
    }

    public func retrievePeripherals() -> [Peripheral] {
        let identifiers = Array(discoveredPeripherals.keys)
        return retrievePeripherals(withIdentifiers: identifiers)
    }

    private func loadRetrievedPeripheral(_ peripheral: CBPeripheralInjectable) -> Peripheral {
        let newBCPeripheral: Peripheral
        if let oldBCPeripheral = _discoveredPeripherals[peripheral.identifier] {
            newBCPeripheral = Peripheral(cbPeripheral: peripheral, bcPeripheral: oldBCPeripheral, profileManager: profileManager)
        } else {
            newBCPeripheral = Peripheral(cbPeripheral: peripheral, centralManager: self, profileManager: profileManager)
        }
        Logger.debug("\(self.name) uuid=\(newBCPeripheral.identifier.uuidString), name=\(newBCPeripheral.name)")
        self._discoveredPeripherals[peripheral.identifier] = newBCPeripheral
        return newBCPeripheral
    }

    // MARK: CBCentralManagerDelegate

    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        didConnectPeripheral(peripheral)
    }

    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        didDisconnectPeripheral(peripheral, error: error)
    }

    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        Logger.debug("advertisementData = \(advertisementData)")
        didDiscoverPeripheral(peripheral, advertisementData: advertisementData, RSSI: RSSI)
    }

    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        didFailToConnectPeripheral(peripheral, error: error)
    }

    public func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        var injectablePeripherals: [CBPeripheralInjectable]?
        if let cbPeripherals: [CBPeripheral] = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] {
            injectablePeripherals = cbPeripherals.map { $0 as CBPeripheralInjectable }
        }
        let scannedServices = dict[CBCentralManagerRestoredStateScanServicesKey] as? [CBUUID]
        let options = dict[CBCentralManagerRestoredStateScanOptionsKey] as? [String: AnyObject]
        willRestoreState(injectablePeripherals, scannedServices: scannedServices, options: options)
    }
    
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        didUpdateState(central)
    }

    // MARK: CBCentralManagerDelegate Shims
    
    func didConnectPeripheral(_ peripheral: CBPeripheralInjectable) {
        Logger.debug("\(self.name) uuid=\(peripheral.identifier.uuidString), name=\(peripheral.name)")
        if let bcPeripheral = _discoveredPeripherals[peripheral.identifier] {
            bcPeripheral.didConnectPeripheral()
        }
    }
    
    func didDisconnectPeripheral(_ peripheral: CBPeripheralInjectable, error: Error?) {
        Logger.debug("\(self.name) uuid=\(peripheral.identifier.uuidString), name=\(peripheral.name), error=\(error)")
        if let bcPeripheral = _discoveredPeripherals[peripheral.identifier] {
            bcPeripheral.didDisconnectPeripheral(error)
        }
    }
    
    func didDiscoverPeripheral(_ peripheral: CBPeripheralInjectable, advertisementData: [String : Any], RSSI: NSNumber) {
        let bcPeripheral = Peripheral(cbPeripheral: peripheral, centralManager: self, advertisements: advertisementData, RSSI: RSSI.intValue, profileManager: profileManager)
        Logger.debug("\(self.name) uuid=\(bcPeripheral.identifier.uuidString), name=\(bcPeripheral.name), RSSI=\(RSSI), Advertisements=\(advertisementData)")
        _discoveredPeripherals[peripheral.identifier] = bcPeripheral
        afterPeripheralDiscoveredPromise?.success(bcPeripheral)
    }
    
    func didFailToConnectPeripheral(_ peripheral: CBPeripheralInjectable, error: Error?) {
        Logger.debug("\(self.name)")
        guard let bcPeripheral = _discoveredPeripherals[peripheral.identifier] else {
            return
        }
        bcPeripheral.didFailToConnectPeripheral(error)
    }

    func willRestoreState(_ cbPeripherals: [CBPeripheralInjectable]?, scannedServices: [CBUUID]?, options: [String: AnyObject]?) {
        Logger.debug("\(self.name)")
        if let cbPeripherals = cbPeripherals, let scannedServices = scannedServices, let options = options {
            let peripherals = cbPeripherals.map { cbPeripheral -> Peripheral in
                let peripheral = Peripheral(cbPeripheral: cbPeripheral, centralManager: self)
                _discoveredPeripherals[peripheral.identifier] = peripheral
                if let cbServices = cbPeripheral.getServices() {
                    for cbService in cbServices {
                        let service = Service(cbService: cbService, peripheral: peripheral)
                        peripheral.discoveredServices[service.uuid] = service
                        if let cbCharacteristics = cbService.getCharacteristics() {
                            for cbCharacteristic in cbCharacteristics {
                                let characteristic = Characteristic(cbCharacteristic: cbCharacteristic, service: service)
                                service.discoveredCharacteristics[characteristic.uuid] = characteristic
                                peripheral.discoveredCharacteristics[characteristic.uuid] = characteristic
                            }
                        }
                    }
                }
                return peripheral
            }
            if let completed = afterStateRestoredPromise?.completed, !completed {
                afterStateRestoredPromise?.success((peripherals, scannedServices, options))
            }
        } else {
            if let completed = afterStateRestoredPromise?.completed, !completed {
                afterStateRestoredPromise?.failure(CentralManagerError.restoreFailed)
            }
        }
    }

    func didUpdateState(_ centralManager: CBCentralManagerInjectable) {
        afterStateChangedPromise?.success(centralManager.managerState)
    }
    
}
