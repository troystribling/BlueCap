//
//  BCPeripheralManager.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/9/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import Foundation
import CoreBluetooth

// MARK: - BCPeripheralManager -
public class BCPeripheralManager: NSObject, CBPeripheralManagerDelegate {

    internal static var CBPeripheralManagerStateKVOContext = UInt8()
    internal static var CBPeripheralManagerIsAdvertisingKVOContext = UInt8()

    // MARK: Serialize Property IO
    static let ioQueue = Queue("us.gnos.blueCap.peripheral-manager.io")

    private let WAIT_FOR_ADVERTISING_TO_STOP_POLLING_INTERVAL   = 0.25

    // MARK: Properties
    private var _name: String?
    internal private(set) var cbPeripheralManager: CBPeripheralManagerInjectable!
    
    private var _afterAdvertisingStartedPromise = Promise<Void>()
    private var _afterAdvertsingStoppedPromise = Promise<Void>()
    private var _afterPowerOnPromise = Promise<Void>()
    private var _afterPowerOffPromise = Promise<Void>()
    private var _afterSeriviceAddPromise = Promise<Void>()
    private var _afterStateRestoredPromise = StreamPromise<(services: [BCMutableService], advertisements: BCPeripheralAdvertisements)>()

    private var _state = CBPeripheralManagerState.Unknown
    private var _poweredOn = false
    private var _isAdvertising = false

    internal var configuredServices  = BCSerialIODictionary<CBUUID, BCMutableService>(BCPeripheralManager.ioQueue)
    internal var configuredCharcteristics = BCSerialIODictionary<CBUUID, BCMutableCharacteristic>(BCPeripheralManager.ioQueue)

    public let peripheralQueue: Queue

    private var afterAdvertisingStartedPromise: Promise<Void> {
        get {
            return BCPeripheralManager.ioQueue.sync { return self._afterAdvertisingStartedPromise }
        }
        set {
            BCPeripheralManager.ioQueue.sync { self._afterAdvertisingStartedPromise = newValue }
        }
    }

    private var afterAdvertsingStoppedPromise: Promise<Void> {
        get {
            return BCPeripheralManager.ioQueue.sync { return self._afterAdvertsingStoppedPromise }
        }
        set {
            BCPeripheralManager.ioQueue.sync { self._afterAdvertsingStoppedPromise = newValue }
        }
    }

    private var afterPowerOnPromise: Promise<Void> {
        get {
            return BCPeripheralManager.ioQueue.sync { return self._afterPowerOnPromise }
        }
        set {
            BCPeripheralManager.ioQueue.sync { self._afterPowerOnPromise = newValue }
        }
    }

    private var afterPowerOffPromise: Promise<Void> {
        get {
            return BCPeripheralManager.ioQueue.sync { return self._afterPowerOffPromise }
        }
        set {
            BCPeripheralManager.ioQueue.sync { self._afterPowerOffPromise = newValue }
        }
    }

    private var afterSeriviceAddPromise: Promise<Void> {
        get {
            return BCPeripheralManager.ioQueue.sync { return self._afterSeriviceAddPromise }
        }
        set {
            BCPeripheralManager.ioQueue.sync { self._afterSeriviceAddPromise = newValue }
        }
    }

    private var afterStateRestoredPromise: StreamPromise<(services: [BCMutableService], advertisements: BCPeripheralAdvertisements)> {
        get {
            return BCPeripheralManager.ioQueue.sync { return self._afterStateRestoredPromise }
        }
        set {
            BCPeripheralManager.ioQueue.sync { self._afterStateRestoredPromise = newValue }
        }
    }

    public private(set) var isAdvertising: Bool {
        get {
            return BCPeripheralManager.ioQueue.sync { return self._isAdvertising }
        }
        set {
            BCPeripheralManager.ioQueue.sync { self._isAdvertising = newValue }
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

    public var state: CBPeripheralManagerState {
        get {
            return BCPeripheralManager.ioQueue.sync { return self._state }
        }
        set {
            BCPeripheralManager.ioQueue.sync { self._state = newValue }
        }
    }
    
    public var services: [BCMutableService] {
        return Array(self.configuredServices.values)
    }

    public func service(uuid: CBUUID) -> BCMutableService? {
        return self.configuredServices[uuid]
    }

    public var characteristics: [BCMutableCharacteristic] {
        return Array(self.configuredCharcteristics.values)
    }

    // MARK: Initialize
    public override init() {
        self.peripheralQueue = Queue(dispatch_queue_create("com.gnos.us.peripheral.main", DISPATCH_QUEUE_SERIAL))
        super.init()
        self.cbPeripheralManager = CBPeripheralManager(delegate:self, queue:self.peripheralQueue.queue)
        self.poweredOn = self.cbPeripheralManager.state == .PoweredOn
        self.isAdvertising = self.cbPeripheralManager.isAdvertising
        self.startObserving()
    }

    public init(queue: dispatch_queue_t, options: [String:AnyObject]?=nil) {
        self.peripheralQueue = Queue(queue)
        super.init()
        self.cbPeripheralManager = CBPeripheralManager(delegate:self, queue:self.peripheralQueue.queue, options:options)
        self.poweredOn = self.cbPeripheralManager.state == .PoweredOn
        self.isAdvertising = self.cbPeripheralManager.isAdvertising
        self.startObserving()
    }

    public init(peripheralManager: CBPeripheralManagerInjectable) {
        self.peripheralQueue = Queue(dispatch_queue_create("com.gnos.us.peripheral.main", DISPATCH_QUEUE_SERIAL))
        super.init()
        self.cbPeripheralManager = peripheralManager
        self.poweredOn = self.cbPeripheralManager.state == .PoweredOn
        self.isAdvertising = self.cbPeripheralManager.isAdvertising
        self.startObserving()
    }

    deinit {
        self.cbPeripheralManager.delegate = nil
        self.stopObserving()
    }

    // MARK: KVO
    internal func startObserving() {
        guard let cbPeripheralManager = self.cbPeripheralManager as? CBPeripheralManager else {
            return
        }
        let options = NSKeyValueObservingOptions([.New, .Old])
        cbPeripheralManager.addObserver(self, forKeyPath: "state", options: options, context: &BCPeripheralManager.CBPeripheralManagerStateKVOContext)
        cbPeripheralManager.addObserver(self, forKeyPath: "isAdvertising", options: options, context: &BCPeripheralManager.CBPeripheralManagerIsAdvertisingKVOContext)
    }

    internal func stopObserving() {
        guard let cbPeripheralManager = self.cbPeripheralManager as? CBPeripheralManager else {
            return
        }
        cbPeripheralManager.removeObserver(self, forKeyPath: "state", context: &BCPeripheralManager.CBPeripheralManagerStateKVOContext)
        cbPeripheralManager.removeObserver(self, forKeyPath: "isAdvertising", context: &BCPeripheralManager.CBPeripheralManagerIsAdvertisingKVOContext)
    }

    override public func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String: AnyObject]?, context: UnsafeMutablePointer<Void>) {
        guard keyPath != nil else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
            return
        }
        switch (keyPath!, context) {
        case("state", &BCPeripheralManager.CBPeripheralManagerStateKVOContext):
            if let change = change, newValue = change[NSKeyValueChangeNewKey], oldValue = change[NSKeyValueChangeOldKey], newRawState = newValue as? Int, oldRawState = oldValue as? Int, newState = CBPeripheralManagerState(rawValue: newRawState) {
                if newRawState != oldRawState {
                    self.willChangeValueForKey("state")
                    self.state = newState
                    self.didChangeValueForKey("state")
                }
            }
        case ("isAdvertising", &BCPeripheralManager.CBPeripheralManagerIsAdvertisingKVOContext):
            if let change = change, newValue = change[NSKeyValueChangeNewKey], oldValue = change[NSKeyValueChangeOldKey], newIsAdvertising = newValue as? Bool, oldIsAdvertising = oldValue as? Bool {
                if newIsAdvertising != oldIsAdvertising {
                    self.willChangeValueForKey("isAdvertising")
                    self.isAdvertising = newIsAdvertising
                    self.didChangeValueForKey("isAdvertising")
                }
            }
        default:
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
    
    // MARK: Power ON/OFF
    public func whenPowerOn() -> Future<Void> {
        BCLogger.debug()
        self.afterPowerOnPromise = Promise<Void>()
        if self.poweredOn {
            self.afterPowerOnPromise.success()
        }
        return self.afterPowerOnPromise.future
    }
    
    public func whenPowerOff() -> Future<Void> {
        BCLogger.debug()
        self.afterPowerOffPromise = Promise<Void>()
        if !self.poweredOn {
            self.afterPowerOffPromise.success()
        }
        return self.afterPowerOffPromise.future
    }

    // MARK: Advertising
    public func startAdvertising(name: String, uuids: [CBUUID]? = nil) -> Future<Void> {
        self._name = name
        self.afterAdvertisingStartedPromise = Promise<Void>()
        if !self.isAdvertising {
            var advertisementData : [String:AnyObject] = [CBAdvertisementDataLocalNameKey:name]
            if let uuids = uuids {
                advertisementData[CBAdvertisementDataServiceUUIDsKey] = uuids
            }
            self.cbPeripheralManager.startAdvertising(advertisementData)
        } else {
            self.afterAdvertisingStartedPromise.failure(BCError.peripheralManagerIsAdvertising)
        }
        return self.afterAdvertisingStartedPromise.future
    }
    
    public func startAdvertising(region: FLBeaconRegion) -> Future<Void> {
        self._name = region.identifier
        self.afterAdvertisingStartedPromise = Promise<Void>()
        if !self.isAdvertising {
            self.cbPeripheralManager.startAdvertising(region.peripheralDataWithMeasuredPower(nil))
        } else {
            self.afterAdvertisingStartedPromise.failure(BCError.peripheralManagerIsAdvertising)
        }
        return self.afterAdvertisingStartedPromise.future
    }
    
    public func stopAdvertising() -> Future<Void> {
        self._name = nil
        self.afterAdvertsingStoppedPromise = Promise<Void>()
        if self.isAdvertising {
             self.cbPeripheralManager.stopAdvertising()
            self.peripheralQueue.async{self.lookForAdvertisingToStop()}
        } else {
            self.afterAdvertsingStoppedPromise.failure(BCError.peripheralManagerIsNotAdvertising)
        }
        return self.afterAdvertsingStoppedPromise.future
    }

    // MARK: Manage Services
    public func addService(service: BCMutableService) -> Future<Void> {
        service.peripheralManager = self
        self.addConfiguredCharacteristics(service.characteristics)
        self.afterSeriviceAddPromise = Promise<Void>()
        self.configuredServices[service.UUID] = service
        self.cbPeripheralManager.addService(service.cbMutableService)
        BCLogger.debug("service name=\(service.name), uuid=\(service.UUID)")
        return self.afterSeriviceAddPromise.future
    }
    
    public func addServices(services: [BCMutableService]) -> Future<Void> {
        BCLogger.debug("service count \(services.count)")
        for service in services {
            self.addConfiguredCharacteristics(service.characteristics)
        }
        let promise = Promise<Void>()
        self.addServices(promise, services:services)
        return promise.future
    }

    public func removeService(service: BCMutableService) {
        BCLogger.debug("removing service \(service.UUID.UUIDString)")
        self.removeServiceAndCharacteristics(service)
    }
    
    public func removeAllServices() {
        BCLogger.debug()
        self.removeAllServiceAndCharacteristics()
    }

    // MARK: Characteristic IO
    public func updateValue(value: NSData, forCharacteristic characteristic: BCMutableCharacteristic) -> Bool  {
        return self.cbPeripheralManager.updateValue(value, forCharacteristic:characteristic.cbMutableChracteristic, onSubscribedCentrals:nil)
    }
    
    public func respondToRequest(request: CBATTRequestInjectable, withResult result: CBATTError) {
        if let request = request as? CBATTRequest {
            self.cbPeripheralManager.respondToRequest(request, withResult:result)
        }
    }

    // MARK: State Restoration
    public func whenStateRestored() -> FutureStream<(services: [BCMutableService], advertisements: BCPeripheralAdvertisements)> {
        self.afterStateRestoredPromise = StreamPromise<(services: [BCMutableService], advertisements: BCPeripheralAdvertisements)>()
        return self.afterStateRestoredPromise.future
    }

    // MARK: CBPeripheralManagerDelegate
    public func peripheralManagerDidUpdateState(_: CBPeripheralManager) {
        self.didUpdateState()
    }
    
    public func peripheralManager(_: CBPeripheralManager, willRestoreState dict: [String:AnyObject]) {
        var injectableServices: [CBMutableServiceInjectable]?
        if let cbServices = dict[CBPeripheralManagerRestoredStateServicesKey] as? [CBMutableService] {
            injectableServices = cbServices.map { $0 as CBMutableServiceInjectable }
        }
        let advertisements =  dict[CBPeripheralManagerRestoredStateAdvertisementDataKey] as? [String: AnyObject]
        self.willRestoreState(injectableServices, advertisements: advertisements)
    }
    
    public func peripheralManagerDidStartAdvertising(_: CBPeripheralManager, error: NSError?) {
        self.didStartAdvertising(error)
    }
    
    public func peripheralManager(_: CBPeripheralManager, didAddService service: CBService, error: NSError?) {
        self.didAddService(service, error:error)
    }
    
    public func peripheralManager(_: CBPeripheralManager, central: CBCentral, didSubscribeToCharacteristic characteristic: CBCharacteristic) {
        self.didSubscribeToCharacteristic(characteristic, central: central)
    }
    
    public func peripheralManager(_: CBPeripheralManager, central: CBCentral, didUnsubscribeFromCharacteristic characteristic: CBCharacteristic) {
        self.didUnsubscribeFromCharacteristic(characteristic, central: central)
    }
    
    public func peripheralManager(_: CBPeripheralManager, didReceiveReadRequest request: CBATTRequest) {
        self.didReceiveReadRequest(request, central: request.central)
    }
    
    public func peripheralManagerIsReadyToUpdateSubscribers(_: CBPeripheralManager) {
        self.isReadyToUpdateSubscribers()
    }

    public func peripheralManager(_: CBPeripheralManager, didReceiveWriteRequests requests: [CBATTRequest]) {
        BCLogger.debug()
        for request in requests {
            self.didReceiveWriteRequest(request, central: request.central)
        }
    }

    // MARK: CBPeripheralManagerDelegate Shims
    internal func didSubscribeToCharacteristic(characteristic: CBCharacteristicInjectable, central: CBCentralInjectable) {
        BCLogger.debug()
        self.configuredCharcteristics[characteristic.UUID]?.didSubscribeToCharacteristic(central)
    }
    
    internal func didUnsubscribeFromCharacteristic(characteristic: CBCharacteristicInjectable, central: CBCentralInjectable) {
        BCLogger.debug()
        self.configuredCharcteristics[characteristic.UUID]?.didUnsubscribeFromCharacteristic(central)
    }
    
    internal func isReadyToUpdateSubscribers() {
        BCLogger.debug()
        for characteristic in self.configuredCharcteristics.values {
            if !characteristic.isUpdating {
                characteristic.peripheralManagerIsReadyToUpdateSubscribers()
            }
        }
    }
    
    internal func didReceiveWriteRequest(request: CBATTRequestInjectable, central: CBCentralInjectable) {
        if let characteristic = self.configuredCharcteristics[request.getCharacteristic().UUID] {
            BCLogger.debug("characteristic write request received for \(characteristic.UUID.UUIDString)")
            if characteristic.didRespondToWriteRequest(request, central: central) {
                characteristic.value = request.value
            } else {
                self.respondToRequest(request, withResult:CBATTError.RequestNotSupported)
            }
        } else {
            self.respondToRequest(request, withResult:CBATTError.UnlikelyError)
        }
    }
    
    internal func didReceiveReadRequest(request: CBATTRequestInjectable, central: CBCentralInjectable) {
        var request = request
        BCLogger.debug("chracteracteristic \(request.getCharacteristic().UUID)")
        if let characteristic = self.configuredCharcteristics[request.getCharacteristic().UUID] {
            BCLogger.debug("responding with data: \(characteristic.stringValue)")
            request.value = characteristic.value
            self.respondToRequest(request, withResult:CBATTError.Success)
        } else {
            BCLogger.debug("characteristic not found")
            self.respondToRequest(request, withResult:CBATTError.UnlikelyError)
        }
    }
    
    internal func didUpdateState() {
        self.poweredOn = self.cbPeripheralManager.state == .PoweredOn
        switch self.cbPeripheralManager.state {
        case .PoweredOn:
            BCLogger.debug("poweredOn")
            if !self.afterPowerOnPromise.completed {
                self.afterPowerOnPromise.success()
            }
            break
        case .PoweredOff:
            BCLogger.debug("poweredOff")
            if !self.afterPowerOffPromise.completed {
                self.afterPowerOffPromise.success()
            }
            break
        case .Resetting:
            break
        case .Unsupported:
            break
        case .Unauthorized:
            break
        case .Unknown:
            break
        }
    }
    
    internal func didStartAdvertising(error: NSError?) {
        if let error = error {
            BCLogger.debug("failed '\(error.localizedDescription)'")
            self.afterAdvertisingStartedPromise.failure(error)
        } else {
            BCLogger.debug("success")
            self.afterAdvertisingStartedPromise.success()
        }
    }
    
    internal func didAddService(service: CBServiceInjectable, error: NSError?) {
        if let error = error {
            BCLogger.debug("failed '\(error.localizedDescription)'")
            self.configuredServices.removeValueForKey(service.UUID)
            self.afterSeriviceAddPromise.failure(error)
        } else {
            BCLogger.debug("success")
            self.afterSeriviceAddPromise.success()
        }
    }

    public func willRestoreState(cbServices: [CBMutableServiceInjectable]?, advertisements: [String: AnyObject]?) {
        if let cbServices = cbServices, let advertisements = advertisements {
            let services = cbServices.map { cbService -> BCMutableService in
                let service = BCMutableService(cbMutableService: cbService)
                self.configuredServices[service.UUID] = service
                var characteristics = [BCMutableCharacteristic]()
                if let cbCharacteristics = cbService.getCharacteristics() as? [CBMutableCharacteristic] {
                    characteristics = cbCharacteristics.map { bcChracteristic in
                        let characteristic = BCMutableCharacteristic(cbMutableCharacteristic: bcChracteristic)
                        self.configuredCharcteristics[characteristic.UUID] = characteristic
                        return characteristic
                    }
                }
                service.characteristics = characteristics
                return service
            }
            self.afterStateRestoredPromise.success((services, BCPeripheralAdvertisements(advertisements: advertisements)))
        } else {
            self.afterStateRestoredPromise.failure(BCError.peripheralManagerRestoreFailed)
        }
    }

    // MARK: Utils
    public func addServices(promise: Promise<Void>, services: [BCMutableService]) {
        if services.count > 0 {
            let future = self.addService(services[0])
            future.onSuccess {
                if services.count > 1 {
                    let servicesTail = Array(services[1...services.count-1])
                    BCLogger.debug("services remaining \(servicesTail.count)")
                    self.addServices(promise, services:servicesTail)
                } else {
                    BCLogger.debug("completed")
                    promise.success()
                }
            }
            future.onFailure {(error) in
                self.removeAllServices()
                BCLogger.debug("failed '\(error.localizedDescription)'")
                promise.failure(error)
            }
        }
    }

    private func lookForAdvertisingToStop() {
        if self.isAdvertising {
            self.peripheralQueue.delay(WAIT_FOR_ADVERTISING_TO_STOP_POLLING_INTERVAL) {
                self.lookForAdvertisingToStop()
            }
        } else {
            BCLogger.debug("advertising stopped")
            self.afterAdvertsingStoppedPromise.success()
        }
    }

    private func addConfiguredCharacteristics(characteristics: [BCMutableCharacteristic]) {
        for characteristic in characteristics {
            self.configuredCharcteristics[characteristic.cbMutableChracteristic.UUID] = characteristic
        }
    }

    private func removeServiceAndCharacteristics(service: BCMutableService) {
        let removedCharacteristics = Array(self.configuredCharcteristics.keys).filter{(uuid) in
            for bcCharacteristic in service.characteristics {
                if uuid == bcCharacteristic.UUID {
                    return true
                }
            }
            return false
        }
        for cbCharacteristic in removedCharacteristics {
            self.configuredCharcteristics.removeValueForKey(cbCharacteristic)
        }
        self.configuredServices.removeValueForKey(service.UUID)
        self.cbPeripheralManager.removeService(service.cbMutableService)
    }
    
    private func removeAllServiceAndCharacteristics() {
        self.configuredServices.removeAll()
        self.configuredCharcteristics.removeAll()
        self.cbPeripheralManager.removeAllServices()
    }

}
