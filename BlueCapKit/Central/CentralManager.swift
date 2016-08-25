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

    // MARK: Serialize Property IO
    static let ioQueue = Queue("us.gnos.blueCap.central-manager.io")

    // MARK: Properties
    fileprivate var _afterPowerOnPromise = Promise<Void>()
    fileprivate var _afterPowerOffPromise = Promise<Void>()
    fileprivate var _afterStateRestoredPromise = StreamPromise<(peripherals: [Peripheral], scannedServices: [CBUUID], options: [String:AnyObject])>()

    fileprivate var _isScanning = false
    fileprivate var _poweredOn = false

    internal var _afterPeripheralDiscoveredPromise = StreamPromise<Peripheral>()
    internal var discoveredPeripherals = SerialIODictionary<UUID, Peripheral>(CentralManager.ioQueue)

    internal let centralQueue: Queue
    open fileprivate(set) var cbCentralManager: CBCentralManagerInjectable!

    fileprivate var timeoutSequence = 0

    fileprivate var afterPowerOnPromise: Promise<Void> {
        get {
            return CentralManager.ioQueue.sync { return self._afterPowerOnPromise }
        }
        set {
            CentralManager.ioQueue.sync { self._afterPowerOnPromise = newValue }
        }
    }

    fileprivate var afterPowerOffPromise: Promise<Void> {
        get {
            return CentralManager.ioQueue.sync { return self._afterPowerOffPromise }
        }
        set {
            CentralManager.ioQueue.sync { self._afterPowerOffPromise = newValue }
        }
    }

    internal var afterPeripheralDiscoveredPromise: StreamPromise<Peripheral> {
        get {
            return CentralManager.ioQueue.sync { return self._afterPeripheralDiscoveredPromise }
        }
        set {
            CentralManager.ioQueue.sync { self._afterPeripheralDiscoveredPromise = newValue }
        }
    }

    fileprivate var afterStateRestoredPromise: StreamPromise<(peripherals: [Peripheral], scannedServices: [CBUUID], options: [String:AnyObject])> {
        get {
            return PeripheralManager.ioQueue.sync { return self._afterStateRestoredPromise }
        }
        set {
            PeripheralManager.ioQueue.sync { self._afterStateRestoredPromise = newValue }
        }
    }

    public var peripherals: [Peripheral] {
        var values = Array(discoveredPeripherals.values)
        let sorted: [Peripheral] = values.sort { (p1: Peripheral, p2: Peripheral) -> Bool in
            switch p1.discoveredAt.compare(p2.discoveredAt) {
            case .orderedSame:
                return true
            case .orderedDescending:
                return false
            case .orderedAscending:
                return true
            }
        }
        return sorted
    }

    public private(set) var isScanning: Bool {
        get {
            return PeripheralManager.ioQueue.sync { return self._isScanning }
        }
        set {
            PeripheralManager.ioQueue.sync { self._isScanning = newValue }
        }
    }

    public private(set) var poweredOn: Bool {
        get {
            return PeripheralManager.ioQueue.sync { return self._poweredOn }
        }
        set {
            PeripheralManager.ioQueue.sync { self._poweredOn = newValue }
        }
    }

    public var state: CBCentralManagerState {
        get {
            return cbCentralManager.state
        }
    }

    // MARK: Initializers

    public override init() {
        self.centralQueue = Queue("us.gnos.blueCap.central-manager.main")
        super.init()
        self.cbCentralManager = CBCentralManager(delegate: self, queue: self.centralQueue.queue)
        self.poweredOn = self.cbCentralManager.state == .poweredOn
    }

    public init(queue:DispatchQueue, options: [String:AnyObject]?=nil) {
        self.centralQueue = Queue(queue)
        super.init()
        self.cbCentralManager = CBCentralManager(delegate: self, queue: self.centralQueue.queue, options: options)
        self.poweredOn = self.cbCentralManager.state == .poweredOn
    }

    public init(centralManager: CBCentralManagerInjectable) {
        self.centralQueue = Queue("us.gnos.blueCap.central-manger.main")
        super.init()
        self.cbCentralManager = centralManager
        self.poweredOn = self.cbCentralManager.state == .poweredOn
    }

    deinit {
        cbCentralManager.delegate = nil
    }

    // MARK: Power ON/OFF

    public func whenPowerOn() -> Future<Void> {
        afterPowerOnPromise = Promise<Void>()
        if poweredOn {
            Logger.debug("Central already powered on")
            afterPowerOnPromise.success()
        }
        return afterPowerOnPromise.future
    }

    public func whenPowerOff() -> Future<Void> {
        afterPowerOffPromise = Promise<Void>()
        if !poweredOn {
            afterPowerOffPromise.success()
        }
        return afterPowerOffPromise.future
    }

    // MARK: Manage Peripherals

    func connect(peripheral: Peripheral, options: [String : Any]? = nil) {
        cbCentralManager.connect(peripheral.cbPeripheral, options: options)
    }
    
    func cancelConnection(forPeripheral peripheral: Peripheral) {
        cbCentralManager.cancelPeripheralConnection(peripheral.cbPeripheral)
    }

    public func disconnectAllPeripherals() {
        for peripheral in discoveredPeripherals.values {
            peripheral.disconnect()
        }
    }

    public func removeAllPeripherals() {
        discoveredPeripherals.removeAll()
    }

    // MARK: Scan

    public func startScanning(capacity: Int = Int.max, timeout: Double = Double.infinity, options: [String : Any]? = nil) -> FutureStream<Peripheral> {
        return startScanning(forServiceUUIDs: nil, capacity: capacity, timeout: timeout)
    }
    
    public func startScanning(forServiceUUIDs UUIDs: [CBUUID]?, capacity: Int = Int.max, timeout: Double = Double.infinity, options: [String:AnyObject]? = nil) -> FutureStream<Peripheral> {
        if !isScanning {
            Logger.debug("UUIDs \(UUIDs)")
            isScanning = true
            afterPeripheralDiscoveredPromise = StreamPromise<Peripheral>(capacity: capacity)
            if poweredOn {
                cbCentralManager.scanForPeripherals(withServices: UUIDs, options: options)
                timeoutScan(timeout, sequence: timeoutSequence)
            } else {
                afterPeripheralDiscoveredPromise.failure(CentralError.isPoweredOff)
            }
        }
        return afterPeripheralDiscoveredPromise.stream
    }
    
    public func stopScanning() {
        if isScanning {
            isScanning = false
            cbCentralManager.stopScan()
            afterPeripheralDiscoveredPromise = StreamPromise<Peripheral>()
        }
    }

    fileprivate func timeoutScan(_ timeout: Double, sequence: Int) {
        guard timeout < Double.infinity else {
            return
        }
        Logger.debug("timeout in \(timeout)s")
        centralQueue.delay(timeout) {
            if self.isScanning {
                if self.peripherals.count == 0 && sequence == self.timeoutSequence{
                    self.afterPeripheralDiscoveredPromise.failure(CentralError.peripheralScanTimeout)
                }
                self.stopScanning()
            }
        }
    }

    // MARK: State Restoration

    public func whenStateRestored() -> FutureStream<(peripherals: [Peripheral], scannedServices: [CBUUID], options: [String:AnyObject])> {
        afterStateRestoredPromise = StreamPromise<(peripherals: [Peripheral], scannedServices: [CBUUID], options: [String:AnyObject])>()
        return afterStateRestoredPromise.stream
    }

    // MARK: Retrieve Peripherals

    public func retrieveConnectedPeripherals(withServices services: [CBUUID]) -> [Peripheral] {
        return cbCentralManager.retrieveConnectedPeripheralsWithServices(services).map { cbPeripheral in
            let newBCPeripheral: Peripheral
            if let oldBCPeripheral = discoveredPeripherals[cbPeripheral.identifier] {
                newBCPeripheral = Peripheral(cbPeripheral: cbPeripheral, bcPeripheral: oldBCPeripheral)
            } else {
                newBCPeripheral = Peripheral(cbPeripheral: cbPeripheral, centralManager: self)
            }
            discoveredPeripherals[cbPeripheral.identifier] = newBCPeripheral
            return newBCPeripheral
        }
    }

    func retrievePeripherals(withIdentifiers identifiers: [UUID]) -> [Peripheral] {
        return cbCentralManager.retrievePeripheralsWithIdentifiers(identifiers).map { cbPeripheral in
            let newBCPeripheral: Peripheral
            if let oldBCPeripheral = discoveredPeripherals[cbPeripheral.identifier] {
                newBCPeripheral = Peripheral(cbPeripheral: cbPeripheral, bcPeripheral: oldBCPeripheral)
            } else {
                newBCPeripheral = Peripheral(cbPeripheral: cbPeripheral, centralManager: self)
            }
            discoveredPeripherals[cbPeripheral.identifier] = newBCPeripheral
            return newBCPeripheral
        }
    }

    func retrievePeripherals() -> [Peripheral] {
        return retrievePeripherals(withIdentifiers: discoveredPeripherals.keys)
    }

    // MARK: CBCentralManagerDelegate

    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        didConnectPeripheral(peripheral)
    }

    @nonobjc public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        didDisconnectPeripheral(peripheral, error: error)
    }

    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        didDiscoverPeripheral(peripheral, advertisementData: advertisementData, RSSI: RSSI)
    }

    @nonobjc public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
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
    internal func didConnectPeripheral(_ peripheral: CBPeripheralInjectable) {
        Logger.debug("uuid=\(peripheral.identifier.uuidString), name=\(peripheral.name)")
        if let bcPeripheral = discoveredPeripherals[peripheral.identifier] {
            bcPeripheral.didConnectPeripheral()
        }
    }
    
    internal func didDisconnectPeripheral(_ peripheral: CBPeripheralInjectable, error: Error?) {
        Logger.debug("uuid=\(peripheral.identifier.uuidString), name=\(peripheral.name), error=\(error)")
        if let bcPeripheral = discoveredPeripherals[peripheral.identifier] {
            bcPeripheral.didDisconnectPeripheral(error)
        }
    }
    
    internal func didDiscoverPeripheral(_ peripheral: CBPeripheralInjectable, advertisementData: [String : Any], RSSI: NSNumber) {
        guard discoveredPeripherals[peripheral.identifier] == nil else {
            return
        }
        let bcPeripheral = Peripheral(cbPeripheral: peripheral, centralManager: self, advertisements: advertisementData, RSSI: RSSI.intValue)
        Logger.debug("uuid=\(bcPeripheral.identifier.uuidString), name=\(bcPeripheral.name)")
        discoveredPeripherals[peripheral.identifier] = bcPeripheral
        afterPeripheralDiscoveredPromise.success(bcPeripheral)
    }
    
    internal func didFailToConnectPeripheral(_ peripheral: CBPeripheralInjectable, error: Error?) {
        Logger.debug()
        guard let bcPeripheral = discoveredPeripherals[peripheral.identifier] else {
            return
        }
        bcPeripheral.didFailToConnectPeripheral(error)
    }

    internal func willRestoreState(_ cbPeripherals: [CBPeripheralInjectable]?, scannedServices: [CBUUID]?, options: [String: AnyObject]?) {
        Logger.debug()
        if let cbPeripherals = cbPeripherals, let scannedServices = scannedServices, let options = options {
            let peripherals = cbPeripherals.map { cbPeripheral -> Peripheral in
                let peripheral = Peripheral(cbPeripheral: cbPeripheral, centralManager: self)
                discoveredPeripherals[peripheral.identifier] = peripheral
                if let cbServices = cbPeripheral.getServices() {
                    for cbService in cbServices {
                        let service = Service(cbService: cbService, peripheral: peripheral)
                        peripheral.discoveredServices[service.UUID] = service
                        if let cbCharacteristics = cbService.getCharacteristics() {
                            for cbCharacteristic in cbCharacteristics {
                                let characteristic = Characteristic(cbCharacteristic: cbCharacteristic, service: service)
                                service.discoveredCharacteristics[characteristic.UUID] = characteristic
                                peripheral.discoveredCharacteristics[characteristic.UUID] = characteristic
                            }
                        }
                    }
                }
                return peripheral
            }
            afterStateRestoredPromise.success((peripherals, scannedServices, options))
        } else {
            afterStateRestoredPromise.failure(CentralError.restoreFailed)
        }
    }

    internal func didUpdateState(_ centralManager: CBCentralManagerInjectable) {
        poweredOn = centralManager.state == .poweredOn
        switch(centralManager.state) {
        case .unauthorized:
            Logger.debug("Unauthorized")
            break
        case .unknown:
            Logger.debug("Unknown")
            break
        case .unsupported:
            Logger.debug("Unsupported")
            if !afterPowerOnPromise.completed {
                afterPowerOnPromise.failure(CentralError.unsupported)
            }
            break
        case .resetting:
            Logger.debug("Resetting")
            break
        case .poweredOff:
            Logger.debug("PoweredOff")
            if !afterPowerOffPromise.completed {
                afterPowerOffPromise.success()
            }
            break
        case .poweredOn:
            Logger.debug("PoweredOn")
            if !afterPowerOnPromise.completed {
                afterPowerOnPromise.success()
            }
            break
        }
    }
    
}
