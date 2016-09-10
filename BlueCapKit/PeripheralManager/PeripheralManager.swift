//
//  PeripheralManager.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/9/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import Foundation
import CoreBluetooth

// MARK: - PeripheralManager -
@available(iOS 10, *)
public class PeripheralManager: NSObject, CBPeripheralManagerDelegate {

    // MARK: Serialize Property IO
    static let ioQueue = Queue("us.gnos.blueCap.peripheral-manager.io")

    fileprivate let WAIT_FOR_ADVERTISING_TO_STOP_POLLING_INTERVAL   = 0.25

    // MARK: Properties
    fileprivate var _name: String?
    internal fileprivate(set) var cbPeripheralManager: CBPeripheralManagerInjectable!
    
    fileprivate var afterAdvertisingStartedPromise: Promise<Void>?
    fileprivate var afterBeaconAdvertisingStartedPromise: Promise<Void>?

    fileprivate var afterPoweredOnPromise: Promise<Void>?
    fileprivate var afterPoweredOffPromise: Promise<Void>?
    fileprivate var afterStateRestoredPromise: StreamPromise<(services: [MutableService], advertisements: PeripheralAdvertisements)>?

    fileprivate var _afterSeriviceAddPromise = Promise<Void>()

    fileprivate var _state = CBManagerState.unknown
    fileprivate var _poweredOn = false
    fileprivate var _isAdvertising = false

    internal var configuredServices  = SerialIODictionary<CBUUID, MutableService>(PeripheralManager.ioQueue)
    internal var configuredCharcteristics = SerialIODictionary<CBUUID, MutableCharacteristic>(PeripheralManager.ioQueue)

    internal let peripheralQueue: Queue

    fileprivate var afterSeriviceAddPromise: Promise<Void> {
        get {
            return PeripheralManager.ioQueue.sync { return self._afterSeriviceAddPromise }
        }
        set {
            PeripheralManager.ioQueue.sync { self._afterSeriviceAddPromise = newValue }
        }
    }

    public var isAdvertising: Bool {
        get {
            return self.cbPeripheralManager.isAdvertising
        }
    }

    public fileprivate(set) var poweredOn: Bool {
        get {
            return PeripheralManager.ioQueue.sync { return self._poweredOn }
        }
        set {
            PeripheralManager.ioQueue.sync { self._poweredOn = newValue }
        }
    }

    public var state: CBManagerState {
        get {
            return cbPeripheralManager.state
        }
    }
    
    public var services: [MutableService] {
        return Array(self.configuredServices.values)
    }

    public func service(_ uuid: CBUUID) -> MutableService? {
        return self.configuredServices[uuid]
    }

    public var characteristics: [MutableCharacteristic] {
        return Array(self.configuredCharcteristics.values)
    }

    // MARK: Initialize

    public override init() {
        self.peripheralQueue = Queue(DispatchQueue(label: "com.gnos.us.peripheral.main", attributes: []))
        super.init()
        self.cbPeripheralManager = CBPeripheralManager(delegate:self, queue:self.peripheralQueue.queue)
        self.poweredOn = self.cbPeripheralManager.state == .poweredOn
    }

    public init(queue: DispatchQueue, options: [String:AnyObject]?=nil) {
        self.peripheralQueue = Queue(queue)
        super.init()
        self.cbPeripheralManager = CBPeripheralManager(delegate:self, queue:self.peripheralQueue.queue, options:options)
        self.poweredOn = self.cbPeripheralManager.state == .poweredOn
    }

    public init(peripheralManager: CBPeripheralManagerInjectable) {
        self.peripheralQueue = Queue(DispatchQueue(label: "com.gnos.us.peripheral.main", attributes: []))
        super.init()
        self.cbPeripheralManager = peripheralManager
        self.poweredOn = self.cbPeripheralManager.state == .poweredOn
    }

    deinit {
        self.cbPeripheralManager.delegate = nil
    }

    // MARK: Power ON/OFF

    public func whenPoweredOn() -> Future<Void> {
        return self.peripheralQueue.sync {
            if let afterPoweredOnPromise = self.afterPoweredOnPromise, !afterPoweredOnPromise.completed {
                return afterPoweredOnPromise.future
            }
            self.afterPoweredOnPromise = Promise<Void>()
            if self.poweredOn {
                self.afterPoweredOnPromise!.success()
            }
            return self.afterPoweredOnPromise!.future
        }
    }
    
    public func whenPoweredOff() -> Future<Void> {
        return self.peripheralQueue.sync {
            if let afterPoweredOffPromise = self.afterPoweredOffPromise, !afterPoweredOffPromise.completed {
                return afterPoweredOffPromise.future
            }
            self.afterPoweredOffPromise = Promise<Void>()
            if !self.poweredOn {
                self.afterPoweredOffPromise!.success()
            }
            return self.afterPoweredOffPromise!.future
        }
    }

    // MARK: Advertising

    public func startAdvertising(_ name: String, uuids: [CBUUID]? = nil) -> Future<Void> {
        return self.peripheralQueue.sync {
            if let afterAdvertisingStartedPromise = self.afterAdvertisingStartedPromise, !afterAdvertisingStartedPromise.completed {
                return afterAdvertisingStartedPromise.future
            }
            self._name = name
            if !self.isAdvertising {
                self.afterAdvertisingStartedPromise = Promise<Void>()
                var advertisementData: [String : AnyObject] = [CBAdvertisementDataLocalNameKey: name as AnyObject]
                if let uuids = uuids {
                    advertisementData[CBAdvertisementDataServiceUUIDsKey] = uuids as AnyObject
                }
                self.cbPeripheralManager.startAdvertising(advertisementData)
                return self.afterAdvertisingStartedPromise!.future
            } else {
                return Future(error: PeripheralManagerError.isAdvertising)
            }
        }
    }
    
    public func startAdvertising(_ region: BeaconRegion) -> Future<Void> {
        return self.peripheralQueue.sync {
            if let afterBeaconAdvertisingStartedPromise = self.afterBeaconAdvertisingStartedPromise, !afterBeaconAdvertisingStartedPromise.completed {
                return afterBeaconAdvertisingStartedPromise.future
            }
            self._name = region.identifier
            self.afterBeaconAdvertisingStartedPromise = Promise<Void>()
            if !self.isAdvertising {
                self.cbPeripheralManager.startAdvertising(region.peripheralDataWithMeasuredPower(nil))
                return self.afterBeaconAdvertisingStartedPromise!.future
            } else {
                return Future(error: PeripheralManagerError.isAdvertising)
            }
        }
    }
    
    public func stopAdvertising() {
        self.peripheralQueue.sync {
            self._name = nil
            if self.isAdvertising {
                 self.cbPeripheralManager.stopAdvertising()
            }
        }
    }

    // MARK: Manage Services

    public func add(service: MutableService) -> Future<Void> {
        service.peripheralManager = self
        self.addConfiguredCharacteristics(service.characteristics)
        self.afterSeriviceAddPromise = Promise<Void>()
        self.configuredServices[service.UUID] = service
        self.cbPeripheralManager.add(service: service.cbMutableService)
        Logger.debug("service name=\(service.name), uuid=\(service.UUID)")
        return self.afterSeriviceAddPromise.future
    }
    
    public func add(services: [MutableService]) -> Future<Void> {
        Logger.debug("service count \(services.count)")
        for service in services {
            self.addConfiguredCharacteristics(service.characteristics)
        }
        let promise = Promise<Void>()
        self.addServices(promise, services:services)
        return promise.future
    }

    public func removeService(_ service: MutableService) {
        Logger.debug("removing service \(service.UUID.uuidString)")
        self.removeServiceAndCharacteristics(service)
    }
    
    public func removeAllServices() {
        Logger.debug()
        self.removeAllServiceAndCharacteristics()
    }

    // MARK: Characteristic IO

    public func updateValue(_ value: Data, forCharacteristic characteristic: MutableCharacteristic) -> Bool  {
        return self.cbPeripheralManager.updateValue(value, forCharacteristic:characteristic.cbMutableChracteristic, onSubscribedCentrals:nil)
    }
    
    public func respondToRequest(_ request: CBATTRequestInjectable, withResult result: CBATTError.Code) {
        if let request = request as? CBATTRequest {
            self.cbPeripheralManager.respondToRequest(request, withResult: result)
        }
    }

    // MARK: State Restoration

    public func whenStateRestored() -> FutureStream<(services: [MutableService], advertisements: PeripheralAdvertisements)> {
        return peripheralQueue.sync {
            if let afterStateRestoredPromise = self.afterStateRestoredPromise {
                return afterStateRestoredPromise.stream
            }
            self.afterStateRestoredPromise = StreamPromise<(services: [MutableService], advertisements: PeripheralAdvertisements)>()
            return self.afterStateRestoredPromise!.stream
        }
    }

    // MARK: CBPeripheralManagerDelegate

    public func peripheralManagerDidUpdateState(_ peripheralManager: CBPeripheralManager) {
        self.didUpdateState(peripheralManager)
    }
    
    public func peripheralManager(_: CBPeripheralManager, willRestoreState dict: [String: Any]) {
        var injectableServices: [CBMutableServiceInjectable]?
        if let cbServices = dict[CBPeripheralManagerRestoredStateServicesKey] as? [CBMutableService] {
            injectableServices = cbServices.map { $0 as CBMutableServiceInjectable }
        }
        let advertisements =  dict[CBPeripheralManagerRestoredStateAdvertisementDataKey] as? [String: AnyObject]
        self.willRestoreState(injectableServices, advertisements: advertisements)
    }
    
    @nonobjc public func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        self.didStartAdvertising(error)
    }
    
    @nonobjc public func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        self.didAddService(service, error:error)
    }
    
    public func peripheralManager(_: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        self.didSubscribeToCharacteristic(characteristic, central: central)
    }
    
    public func peripheralManager(_: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        self.didUnsubscribeFromCharacteristic(characteristic, central: central)
    }
    
    public func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        self.didReceiveReadRequest(request, central: request.central)
    }
    
    public func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        self.isReadyToUpdateSubscribers()
    }

    public func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        Logger.debug()
        for request in requests {
            self.didReceiveWriteRequest(request, central: request.central)
        }
    }

    // MARK: CBPeripheralManagerDelegate Shims
    internal func didSubscribeToCharacteristic(_ characteristic: CBCharacteristicInjectable, central: CBCentralInjectable) {
        Logger.debug()
        self.configuredCharcteristics[characteristic.UUID]?.didSubscribeToCharacteristic(central)
    }
    
    internal func didUnsubscribeFromCharacteristic(_ characteristic: CBCharacteristicInjectable, central: CBCentralInjectable) {
        Logger.debug()
        self.configuredCharcteristics[characteristic.UUID]?.didUnsubscribeFromCharacteristic(central)
    }
    
    internal func isReadyToUpdateSubscribers() {
        Logger.debug()
        for characteristic in self.configuredCharcteristics.values {
            if !characteristic.isUpdating {
                characteristic.peripheralManagerIsReadyToUpdateSubscribers()
            }
        }
    }
    
    internal func didReceiveWriteRequest(_ request: CBATTRequestInjectable, central: CBCentralInjectable) {
        if let characteristic = self.configuredCharcteristics[request.getCharacteristic().UUID] {
            Logger.debug("characteristic write request received for \(characteristic.UUID.uuidString)")
            if characteristic.didRespondToWriteRequest(request, central: central) {
                characteristic.value = request.value
            } else {
                respondToRequest(request, withResult:CBATTError.Code.requestNotSupported)
            }
        } else {
            respondToRequest(request, withResult:CBATTError.Code.unlikelyError)
        }
    }
    
    internal func didReceiveReadRequest(_ request: CBATTRequestInjectable, central: CBCentralInjectable) {
        var request = request
        Logger.debug("chracteracteristic \(request.getCharacteristic().UUID)")
        if let characteristic = self.configuredCharcteristics[request.getCharacteristic().UUID] {
            Logger.debug("responding with data: \(characteristic.stringValue)")
            request.value = characteristic.value
            respondToRequest(request, withResult:CBATTError.Code.success)
        } else {
            Logger.debug("characteristic not found")
            respondToRequest(request, withResult:CBATTError.Code.unlikelyError)
        }
    }
    
    internal func didUpdateState(_ peripheralManager: CBPeripheralManagerInjectable) {
        self.poweredOn = peripheralManager.state == .poweredOn
        switch peripheralManager.state {
        case .poweredOn:
            if let afterPoweredOnPromise = self.afterPoweredOnPromise, !afterPoweredOnPromise.completed {
                afterPoweredOnPromise.success()
            }
        case .poweredOff:
            if let afterPoweredOffPromise = self.afterPoweredOffPromise, !afterPoweredOffPromise.completed {
                afterPoweredOffPromise.success()
            }
        case .resetting:
            break
        case .unsupported:
            if let afterPowerOffPromise = self.afterPoweredOffPromise, !afterPowerOffPromise.completed {
                afterPowerOffPromise.failure(PeripheralManagerError.unsupported)
            }
            if let afterPoweredOnPromise = self.afterPoweredOnPromise, !afterPoweredOnPromise.completed {
                afterPoweredOnPromise.failure(PeripheralManagerError.unsupported)
            }
        case .unauthorized:
            break
        case .unknown:
            break
        }
    }
    
    internal func didStartAdvertising(_ error: Error?) {
        if let error = error {
            Logger.debug("failed '\(error.localizedDescription)'")
            if let afterAdvertisingStartedPromise = self.afterAdvertisingStartedPromise, !afterAdvertisingStartedPromise.completed {
                afterAdvertisingStartedPromise.failure(error)
            }
            if let afterBeaconAdvertisingStartedPromise = self.afterBeaconAdvertisingStartedPromise, !afterBeaconAdvertisingStartedPromise.completed {
                afterBeaconAdvertisingStartedPromise.failure(error)
            }
        } else {
            Logger.debug("success")
            if let afterAdvertisingStartedPromise = self.afterAdvertisingStartedPromise, !afterAdvertisingStartedPromise.completed {
                afterAdvertisingStartedPromise.success()
            }
            if let afterBeaconAdvertisingStartedPromise = self.afterBeaconAdvertisingStartedPromise, !afterBeaconAdvertisingStartedPromise.completed {
                afterBeaconAdvertisingStartedPromise.success()
            }
        }
    }
    
    internal func didAddService(_ service: CBServiceInjectable, error: Error?) {
        if let error = error {
            Logger.debug("failed '\(error.localizedDescription)'")
            self.configuredServices.removeValueForKey(service.UUID)
            self.afterSeriviceAddPromise.failure(error)
        } else {
            Logger.debug("success")
            self.afterSeriviceAddPromise.success()
        }
    }

    public func willRestoreState(_ cbServices: [CBMutableServiceInjectable]?, advertisements: [String: Any]?) {
        if let cbServices = cbServices, let advertisements = advertisements {
            let services = cbServices.map { cbService -> MutableService in
                let service = MutableService(cbMutableService: cbService)
                self.configuredServices[service.UUID] = service
                var characteristics = [MutableCharacteristic]()
                if let cbCharacteristics = cbService.getCharacteristics() as? [CBMutableCharacteristic] {
                    characteristics = cbCharacteristics.map { bcChracteristic in
                        let characteristic = MutableCharacteristic(cbMutableCharacteristic: bcChracteristic)
                        self.configuredCharcteristics[characteristic.UUID] = characteristic
                        return characteristic
                    }
                }
                service.characteristics = characteristics
                return service
            }
            self.afterStateRestoredPromise?.success((services, PeripheralAdvertisements(advertisements: advertisements)))
        } else {
            self.afterStateRestoredPromise?.failure(PeripheralManagerError.restoreFailed)
        }
    }

    // MARK: Utils
    public func addServices(_ promise: Promise<Void>, services: [MutableService]) {
        if services.count > 0 {
            let future = self.add(service: services[0])
            future.onSuccess {
                if services.count > 1 {
                    let servicesTail = Array(services[1...services.count-1])
                    Logger.debug("services remaining \(servicesTail.count)")
                    self.addServices(promise, services:servicesTail)
                } else {
                    Logger.debug("completed")
                    promise.success()
                }
            }
            future.onFailure {(error) in
                self.removeAllServices()
                Logger.debug("failed '\(error.localizedDescription)'")
                promise.failure(error)
            }
        }
    }

    fileprivate func addConfiguredCharacteristics(_ characteristics: [MutableCharacteristic]) {
        for characteristic in characteristics {
            self.configuredCharcteristics[characteristic.cbMutableChracteristic.UUID] = characteristic
        }
    }

    fileprivate func removeServiceAndCharacteristics(_ service: MutableService) {
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
        self.cbPeripheralManager.remove(service: service.cbMutableService)
    }
    
    fileprivate func removeAllServiceAndCharacteristics() {
        self.configuredServices.removeAll()
        self.configuredCharcteristics.removeAll()
        self.cbPeripheralManager.removeAllServices()
    }

}
