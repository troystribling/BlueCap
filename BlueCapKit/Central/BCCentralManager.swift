//
//  BCCentralManager.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/4/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import Foundation
import CoreBluetooth

// MARK: - CBCentralManagerInjectable -
public protocol CBCentralManagerInjectable {
    var state : CBCentralManagerState { get }
    func scanForPeripheralsWithServices(uuids: [CBUUID]?, options: [String: AnyObject]?)
    func stopScan()
    func connectPeripheral(peripheral: CBPeripheral, options: [String: AnyObject]?)
    func cancelPeripheralConnection(peripheral: CBPeripheral)
    func retrieveConnectedPeripheralsWithServices(serviceUUIDs: [CBUUID]) -> [CBPeripheral]
    func retrievePeripheralsWithIdentifiers(identifiers: [NSUUID]) -> [CBPeripheral]
}

extension CBCentralManager : CBCentralManagerInjectable {}

// MARK: - BCCentralManager -
public class BCCentralManager : NSObject, CBCentralManagerDelegate {

    // MARK: Serialize Property IO
    static let ioQueue = Queue("us.gnos.blueCap.central-manager.io")

    // MARK: Properties
    private var _afterPowerOnPromise = Promise<Void>()
    private var _afterPowerOffPromise = Promise<Void>()
    private var _afterStateRestoredPromise = Promise<(peripherals: [BCPeripheral], scannedServices: [CBUUID], options: [String:AnyObject])>()

    private var _isScanning = false

    internal var _afterPeripheralDiscoveredPromise = StreamPromise<BCPeripheral>()
    internal var discoveredPeripherals = BCSerialIODictionary<NSUUID, BCPeripheral>(BCCentralManager.ioQueue)

    public var cbCentralManager: CBCentralManagerInjectable!
    public let centralQueue: Queue

    private var afterPowerOnPromise: Promise<Void> {
        get {
            return BCCentralManager.ioQueue.sync { return self._afterPowerOnPromise }
        }
        set {
            BCCentralManager.ioQueue.sync { self._afterPowerOnPromise = newValue }
        }
    }

    private var afterPowerOffPromise: Promise<Void> {
        get {
            return BCCentralManager.ioQueue.sync { return self._afterPowerOffPromise }
        }
        set {
            BCCentralManager.ioQueue.sync { self._afterPowerOffPromise = newValue }
        }
    }

    internal var afterPeripheralDiscoveredPromise: StreamPromise<BCPeripheral> {
        get {
            return BCCentralManager.ioQueue.sync { return self._afterPeripheralDiscoveredPromise }
        }
        set {
            BCCentralManager.ioQueue.sync { self._afterPeripheralDiscoveredPromise = newValue }
        }
    }

    private var afterStateRestoredPromise: Promise<(peripherals: [BCPeripheral], scannedServices: [CBUUID], options: [String:AnyObject])> {
        get {
            return BCPeripheralManager.ioQueue.sync { return self._afterStateRestoredPromise }
        }
        set {
            BCPeripheralManager.ioQueue.sync { self._afterStateRestoredPromise = newValue }
        }
    }

    public var poweredOn: Bool {
        return self.cbCentralManager.state == CBCentralManagerState.PoweredOn
    }
    
    public var poweredOff: Bool {
        return self.cbCentralManager.state == CBCentralManagerState.PoweredOff
    }

    public var peripherals: [BCPeripheral] {
        return Array(self.discoveredPeripherals.values).sort() {(p1: BCPeripheral, p2: BCPeripheral) -> Bool in
            switch p1.discoveredAt.compare(p2.discoveredAt) {
            case .OrderedSame:
                return true
            case .OrderedDescending:
                return false
            case .OrderedAscending:
                return true
            }
        }
    }

    public var state: CBCentralManagerState {
        return self.cbCentralManager.state
    }
    
    public var isScanning: Bool {
        return self._isScanning
    }

    // MARK: Initializers
    public override init() {
        self.centralQueue = Queue("us.gnos.blueCap.central-manager.main")
        super.init()
        self.cbCentralManager = CBCentralManager(delegate: self, queue: self.centralQueue.queue)
    }
    
    public init(queue:dispatch_queue_t, options: [String:AnyObject]?=nil) {
        self.centralQueue = Queue(queue)
        super.init()
        self.cbCentralManager = CBCentralManager(delegate: self, queue: self.centralQueue.queue, options: options)
    }

    public init(centralManager: CBCentralManagerInjectable) {
        self.centralQueue = Queue("us.gnos.blueCap.central-manger.main")
        super.init()
        self.cbCentralManager = centralManager
    }

    // MARK: Power ON/OFF
    public func whenPowerOn() -> Future<Void> {
        self.afterPowerOnPromise = Promise<Void>()
        if self.poweredOn {
            self.afterPowerOnPromise.success()
        }
        return self.afterPowerOnPromise.future
    }

    public func whenPowerOff() -> Future<Void> {
        self.afterPowerOffPromise = Promise<Void>()
        if self.poweredOff {
            self.afterPowerOffPromise.success()
        }
        return self.afterPowerOffPromise.future
    }

    // MARK: Manage Peripherals
    public func connectPeripheral(peripheral: BCPeripheral, options: [String:AnyObject]? = nil) {
        if let cbPeripheral = peripheral.cbPeripheral as? CBPeripheral {
            self.cbCentralManager.connectPeripheral(cbPeripheral, options: options)
        }
    }
    
    public func cancelPeripheralConnection(peripheral: BCPeripheral) {
        if let cbPeripheral = peripheral.cbPeripheral as? CBPeripheral {
            self.cbCentralManager.cancelPeripheralConnection(cbPeripheral)
        }
    }

    public func disconnectAllPeripherals() {
        for peripheral in self.discoveredPeripherals.values {
            peripheral.disconnect()
        }
    }

    public func removeAllPeripherals() {
        self.discoveredPeripherals.removeAll()
    }

    // MARK: Scan
    public func startScanning(capacity: Int? = nil, options: [String:AnyObject]? = nil) -> FutureStream<BCPeripheral> {
        return self.startScanningForServiceUUIDs(nil, capacity: capacity)
    }
    
    public func startScanningForServiceUUIDs(uuids: [CBUUID]?, capacity: Int? = nil, options: [String:AnyObject]? = nil) -> FutureStream<BCPeripheral> {
        if !self._isScanning {
            BCLogger.debug("UUIDs \(uuids)")
            self._isScanning = true
            if let capacity = capacity {
                self.afterPeripheralDiscoveredPromise = StreamPromise<BCPeripheral>(capacity: capacity)
            } else {
                self.afterPeripheralDiscoveredPromise = StreamPromise<BCPeripheral>()
            }
            if self.poweredOn {
                self.cbCentralManager.scanForPeripheralsWithServices(uuids, options: options)
            } else {
                self.afterPeripheralDiscoveredPromise.failure(BCError.centralIsPoweredOff)
            }
        }
        return self.afterPeripheralDiscoveredPromise.future
    }
    
    public func stopScanning() {
        if self._isScanning {
            self._isScanning = false
            self.cbCentralManager.stopScan()
            self.afterPeripheralDiscoveredPromise = StreamPromise<BCPeripheral>()
        }
    }

    // MARK: State Restoration
    public func whenStateRestored() -> Future<(peripherals: [BCPeripheral], scannedServices: [CBUUID], options: [String:AnyObject])> {
        self.afterStateRestoredPromise = Promise<(peripherals: [BCPeripheral], scannedServices: [CBUUID], options: [String:AnyObject])>()
        return self.afterStateRestoredPromise.future
    }

    // MARK: Retrieve Peripherals
    public func retrieveConnectedPeripheralsWithServices(services: [CBUUID]) -> [BCPeripheral] {
        let cbPeripherals = self.cbCentralManager.retrieveConnectedPeripheralsWithServices(services).filter { cbPeripheral in
            if let _ = self.discoveredPeripherals[cbPeripheral.identifier] {
                return true
            } else {
                return false
            }
        }
        return cbPeripherals.map { self.discoveredPeripherals[$0.identifier]! }
    }

    func retrievePeripheralsWithIdentifiers(identifiers: [NSUUID]) -> [BCPeripheral] {
        let cbPeripherals = self.cbCentralManager.retrievePeripheralsWithIdentifiers(identifiers).filter { cbPeripheral in
            if let _ = self.discoveredPeripherals[cbPeripheral.identifier] {
                return true
            } else {
                return false
            }
        }
        return cbPeripherals.map { self.discoveredPeripherals[$0.identifier]! }
    }

    // MARK: CBCentralManagerDelegate
    public func centralManager(_: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        self.didConnectPeripheral(peripheral)
    }

    public func centralManager(_: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        self.didDisconnectPeripheral(peripheral, error:error)
    }

    public func centralManager(_: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String: AnyObject], RSSI: NSNumber) {
        self.didDiscoverPeripheral(peripheral, advertisementData:advertisementData, RSSI:RSSI)
    }

    public func centralManager(_: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        self.didFailToConnectPeripheral(peripheral, error:error)
    }

    public func centralManager(_: CBCentralManager, willRestoreState dict: [String: AnyObject]) {
        self.willRestoreState(dict)
    }
    
    public func centralManagerDidUpdateState(_: CBCentralManager) {
        self.didUpdateState()
    }

    // MARK: CBCentralManagerDelegate Shims
    internal func didConnectPeripheral(peripheral: CBPeripheralInjectable) {
        BCLogger.debug("uuid=\(peripheral.identifier.UUIDString), name=\(peripheral.name)")
        if let bcPeripheral = self.discoveredPeripherals[peripheral.identifier] {
            bcPeripheral.didConnectPeripheral()
        }
    }
    
    internal func didDisconnectPeripheral(peripheral: CBPeripheralInjectable, error: NSError?) {
        BCLogger.debug("uuid=\(peripheral.identifier.UUIDString), name=\(peripheral.name)")
        if let bcPeripheral = self.discoveredPeripherals[peripheral.identifier] {
            bcPeripheral.didDisconnectPeripheral()
        }
    }
    
    internal func didDiscoverPeripheral(peripheral: CBPeripheralInjectable, advertisementData: [String:AnyObject], RSSI: NSNumber) {
        if self.discoveredPeripherals[peripheral.identifier] == nil {
            let bcPeripheral = BCPeripheral(cbPeripheral: peripheral, centralManager: self, advertisements: advertisementData, RSSI: RSSI.integerValue)
            BCLogger.debug("uuid=\(bcPeripheral.identifier.UUIDString), name=\(bcPeripheral.name)")
            self.discoveredPeripherals[peripheral.identifier] = bcPeripheral
            self.afterPeripheralDiscoveredPromise.success(bcPeripheral)
        }
    }
    
    internal func didFailToConnectPeripheral(peripheral: CBPeripheralInjectable, error: NSError?) {
        BCLogger.debug()
        if let bcPeripheral = self.discoveredPeripherals[peripheral.identifier] {
            bcPeripheral.didFailToConnectPeripheral(error)
        }
    }

    internal func willRestoreState(dict: [String: AnyObject]) {
        BCLogger.debug()
        if let cbPeripherals = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheralInjectable],
            let scannedServices = dict[CBCentralManagerRestoredStateScanServicesKey] as? [CBUUID],
            let options = dict[CBCentralManagerRestoredStateScanOptionsKey] as? [String: AnyObject] {

                let peripherals = cbPeripherals.map { cbPeripheral -> BCPeripheral in
                    let peripheral = BCPeripheral(cbPeripheral: cbPeripheral, centralManager: self)
                    self.discoveredPeripherals[peripheral.identifier] = peripheral
                    if let cbServices = cbPeripheral.services {
                        for cbService in cbServices {
                            let service = BCService(cbService: cbService, peripheral: peripheral)
                            peripheral.discoveredServices[service.UUID] = service
                            if let cbCharacteristics = cbService.characteristics {
                                for cbCharacteristic in cbCharacteristics {
                                    let characteristic = BCCharacteristic(cbCharacteristic: cbCharacteristic, service: service)
                                    peripheral.discoveredCharacteristics[characteristic.UUID] = characteristic
                                }
                            }
                        }
                    }
                    return peripheral
                }
                self.afterStateRestoredPromise.success((peripherals, scannedServices, options))
        } else {
            self.afterStateRestoredPromise.failure(BCError.centralRestoreFailed)
        }
    }

    internal func didUpdateState() {
        switch(self.cbCentralManager.state) {
        case .Unauthorized:
            BCLogger.debug("Unauthorized")
            break
        case .Unknown:
            BCLogger.debug("Unknown")
            break
        case .Unsupported:
            BCLogger.debug("Unsupported")
            break
        case .Resetting:
            BCLogger.debug("Resetting")
            break
        case .PoweredOff:
            BCLogger.debug("PoweredOff")
            if !self.afterPowerOffPromise.completed {
                self.afterPowerOffPromise.success()
            }
            break
        case .PoweredOn:
            BCLogger.debug("PoweredOn")
            if !self.afterPowerOnPromise.completed {
                self.afterPowerOnPromise.success()
            }
            break
        }
    }
    
}
