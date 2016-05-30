//
//  BCCentralManager.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/4/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import Foundation
import CoreBluetooth

// MARK: - BCCentralManager -
public class BCCentralManager : NSObject, CBCentralManagerDelegate {

    internal static var CBCentralManagerStateKVOContext = UInt8()

    // MARK: Serialize Property IO
    static let ioQueue = Queue("us.gnos.blueCap.central-manager.io")

    // MARK: Properties
    private var _afterPowerOnPromise = Promise<Void>()
    private var _afterPowerOffPromise = Promise<Void>()
    private var _afterStateRestoredPromise = StreamPromise<(peripherals: [BCPeripheral], scannedServices: [CBUUID], options: [String:AnyObject])>()

    private var _isScanning = false
    private var _poweredOn = false
    private var _state = CBCentralManagerState.Unknown

    internal var _afterPeripheralDiscoveredPromise = StreamPromise<BCPeripheral>()
    internal var discoveredPeripherals = BCSerialIODictionary<NSUUID, BCPeripheral>(BCCentralManager.ioQueue)

    internal let centralQueue: Queue
    public private(set) var cbCentralManager: CBCentralManagerInjectable!

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

    private var afterStateRestoredPromise: StreamPromise<(peripherals: [BCPeripheral], scannedServices: [CBUUID], options: [String:AnyObject])> {
        get {
            return BCPeripheralManager.ioQueue.sync { return self._afterStateRestoredPromise }
        }
        set {
            BCPeripheralManager.ioQueue.sync { self._afterStateRestoredPromise = newValue }
        }
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

    // TODO: should be updated in IO queue
    public private(set) var isScanning: Bool {
        get {
            return BCPeripheralManager.ioQueue.sync { return self._isScanning }
        }
        set {
            BCPeripheralManager.ioQueue.sync { self._isScanning = newValue }
        }
    }

    public private(set) var poweredOn: Bool {
        get {
            return BCPeripheralManager.ioQueue.sync { return self._poweredOn }
        }
        set {
            BCPeripheralManager.ioQueue.sync { self._poweredOn = newValue }
        }
    }

    public private(set) var state: CBCentralManagerState {
        get {
            return BCPeripheralManager.ioQueue.sync { return self._state }
        }
        set {
            BCPeripheralManager.ioQueue.sync { self._state = newValue }
        }
    }

    // MARK: Initializers
    public override init() {
        self.centralQueue = Queue("us.gnos.blueCap.central-manager.main")
        super.init()
        self.cbCentralManager = CBCentralManager(delegate: self, queue: self.centralQueue.queue)
        self.poweredOn = self.cbCentralManager.state == .PoweredOn
        self.startObserving()
    }

    public init(queue:dispatch_queue_t, options: [String:AnyObject]?=nil) {
        self.centralQueue = Queue(queue)
        super.init()
        self.cbCentralManager = CBCentralManager(delegate: self, queue: self.centralQueue.queue, options: options)
        self.poweredOn = self.cbCentralManager.state == .PoweredOn
        self.startObserving()
    }

    public init(centralManager: CBCentralManagerInjectable) {
        self.centralQueue = Queue("us.gnos.blueCap.central-manger.main")
        super.init()
        self.cbCentralManager = centralManager
        self.poweredOn = self.cbCentralManager.state == .PoweredOn
        self.startObserving()
    }

    deinit {
        self.cbCentralManager.delegate = nil
        self.stopObserving()
    }

    // MARK: KVO
    internal func startObserving() {
        guard let cbCentralManager = self.cbCentralManager as? CBCentralManager else {
            return
        }
        let options = NSKeyValueObservingOptions([.New, .Old])
        cbCentralManager.addObserver(self, forKeyPath: "state", options: options, context: &BCCentralManager.CBCentralManagerStateKVOContext)
    }

    internal func stopObserving() {
        guard let cbCentralManager = self.cbCentralManager as? CBCentralManager else {
            return
        }
        cbCentralManager.removeObserver(self, forKeyPath: "state", context: &BCCentralManager.CBCentralManagerStateKVOContext)
    }

    override public func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String: AnyObject]?, context: UnsafeMutablePointer<Void>) {
        guard keyPath != nil else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
            return
        }
        switch (keyPath!, context) {
        case("state", &BCCentralManager.CBCentralManagerStateKVOContext):
            if let change = change, newValue = change[NSKeyValueChangeNewKey], oldValue = change[NSKeyValueChangeOldKey], newRawState = newValue as? Int, oldRawState = oldValue as? Int, newState = CBCentralManagerState(rawValue: newRawState) {
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

    // MARK: Power ON/OFF
    public func whenPowerOn() -> Future<Void> {
        self.afterPowerOnPromise = Promise<Void>()
        if self.poweredOn {
            BCLogger.debug("Central already powered on")
            self.afterPowerOnPromise.success()
        }
        return self.afterPowerOnPromise.future
    }

    public func whenPowerOff() -> Future<Void> {
        self.afterPowerOffPromise = Promise<Void>()
        if !self.poweredOn {
            self.afterPowerOffPromise.success()
        }
        return self.afterPowerOffPromise.future
    }

    // MARK: Manage Peripherals
    public func connectPeripheral(peripheral: BCPeripheral, options: [String:AnyObject]? = nil) {
        self.cbCentralManager.connectPeripheral(peripheral.cbPeripheral, options: options)
    }
    
    public func cancelPeripheralConnection(peripheral: BCPeripheral) {
        self.cbCentralManager.cancelPeripheralConnection(peripheral.cbPeripheral)
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
        if !self.isScanning {
            BCLogger.debug("UUIDs \(uuids)")
            self.isScanning = true
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
        if self.isScanning {
            self.isScanning = false
            self.cbCentralManager.stopScan()
            self.afterPeripheralDiscoveredPromise = StreamPromise<BCPeripheral>()
        }
    }

    // MARK: State Restoration
    public func whenStateRestored() -> FutureStream<(peripherals: [BCPeripheral], scannedServices: [CBUUID], options: [String:AnyObject])> {
        self.afterStateRestoredPromise = StreamPromise<(peripherals: [BCPeripheral], scannedServices: [CBUUID], options: [String:AnyObject])>()
        return self.afterStateRestoredPromise.future
    }

    // MARK: Retrieve Peripherals
    public func retrieveConnectedPeripheralsWithServices(services: [CBUUID]) -> [BCPeripheral] {
        return self.cbCentralManager.retrieveConnectedPeripheralsWithServices(services).map { cbPeripheral in
            let newBCPeripheral: BCPeripheral
            if let oldBCPeripheral = self.discoveredPeripherals[cbPeripheral.identifier] {
                newBCPeripheral = BCPeripheral(cbPeripheral: cbPeripheral, bcPeripheral: oldBCPeripheral)
            } else {
                newBCPeripheral = BCPeripheral(cbPeripheral: cbPeripheral, centralManager: self)
            }
            self.discoveredPeripherals[cbPeripheral.identifier] = newBCPeripheral
            return newBCPeripheral
        }
    }

    func retrievePeripheralsWithIdentifiers(identifiers: [NSUUID]) -> [BCPeripheral] {
        return self.cbCentralManager.retrievePeripheralsWithIdentifiers(identifiers).map { cbPeripheral in
            let newBCPeripheral: BCPeripheral
            if let oldBCPeripheral = self.discoveredPeripherals[cbPeripheral.identifier] {
                newBCPeripheral = BCPeripheral(cbPeripheral: cbPeripheral, bcPeripheral: oldBCPeripheral)
            } else {
                newBCPeripheral = BCPeripheral(cbPeripheral: cbPeripheral, centralManager: self)
            }
            self.discoveredPeripherals[cbPeripheral.identifier] = newBCPeripheral
            return newBCPeripheral
        }
    }

    func retrievePeripherals() -> [BCPeripheral] {
        return self.retrievePeripheralsWithIdentifiers(self.discoveredPeripherals.keys)
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
        var injectablePeripherals: [CBPeripheralInjectable]?
        if let cbPeripherals: [CBPeripheral] = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] {
            injectablePeripherals = cbPeripherals.map { $0 as CBPeripheralInjectable }
        }
        let scannedServices = dict[CBCentralManagerRestoredStateScanServicesKey] as? [CBUUID]
        let options = dict[CBCentralManagerRestoredStateScanOptionsKey] as? [String: AnyObject]
        self.willRestoreState(injectablePeripherals, scannedServices: scannedServices, options: options)
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
        BCLogger.debug("uuid=\(peripheral.identifier.UUIDString), name=\(peripheral.name), error=\(error)")
        if let bcPeripheral = self.discoveredPeripherals[peripheral.identifier] {
            bcPeripheral.didDisconnectPeripheral(error)
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

    internal func willRestoreState(cbPeripherals: [CBPeripheralInjectable]?, scannedServices: [CBUUID]?, options: [String: AnyObject]?) {
        BCLogger.debug()
        if let cbPeripherals = cbPeripherals, scannedServices = scannedServices, options = options {
            let peripherals = cbPeripherals.map { cbPeripheral -> BCPeripheral in
                let peripheral = BCPeripheral(cbPeripheral: cbPeripheral, centralManager: self)
                self.discoveredPeripherals[peripheral.identifier] = peripheral
                if let cbServices = cbPeripheral.getServices() {
                    for cbService in cbServices {
                        let service = BCService(cbService: cbService, peripheral: peripheral)
                        peripheral.discoveredServices[service.UUID] = service
                        if let cbCharacteristics = cbService.getCharacteristics() {
                            for cbCharacteristic in cbCharacteristics {
                                let characteristic = BCCharacteristic(cbCharacteristic: cbCharacteristic, service: service)
                                service.discoveredCharacteristics[characteristic.UUID] = characteristic
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
        self.poweredOn = self.cbCentralManager.state == .PoweredOn
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
