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

public class PeripheralManager: NSObject, CBPeripheralManagerDelegate {

    fileprivate let WAIT_FOR_ADVERTISING_TO_STOP_POLLING_INTERVAL = 0.25

    // MARK: Properties

    fileprivate var _name: String?
    internal fileprivate(set) var cbPeripheralManager: CBPeripheralManagerInjectable!
    
    fileprivate var afterAdvertisingStartedPromise: Promise<Void>?
    fileprivate var afterBeaconAdvertisingStartedPromise: Promise<Void>?
    fileprivate var afterAdvertisingStoppedPromise: Promise<Void>?

    fileprivate var options: [String : Any]?

    fileprivate var afterStateChangedPromise: StreamPromise<ManagerState>?
    fileprivate var afterStateRestoredPromise: Promise<PeripheralAdvertisements>?

    var configuredServices  = [CBUUID : [MutableService]]()
    let peripheralQueue: Queue

    fileprivate var stopAdvertisingTimeoutSequence = 0

    fileprivate var _characteristics: [MutableCharacteristic] {
        return Array(self.configuredServices.values).flatMap { $0 }.map { $0.characteristics }.flatMap { $0 }
    }

    fileprivate func _characteristics(withUUID uuid: CBUUID) -> [MutableCharacteristic]? {
        return self._characteristics.filter { $0.uuid == uuid }
    }

    public var isAdvertising: Bool {
        return cbPeripheralManager?.isAdvertising ?? false
    }

    public var poweredOn: Bool {
        return cbPeripheralManager.managerState == .poweredOn
    }

    public var state: ManagerState {
        return cbPeripheralManager?.managerState ?? .unknown
    }
    
    public var services: [MutableService] {
        return peripheralQueue.sync { Array(self.configuredServices.values).flatMap { $0 } }
    }

    public var characteristics: [MutableCharacteristic] {
        return peripheralQueue.sync { self._characteristics }
    }

    public func service(withUUID uuid: CBUUID) -> [MutableService]? {
        return peripheralQueue.sync { self.configuredServices[uuid] }
    }

    public func characteristics(withUUID uuid: CBUUID) -> [MutableCharacteristic]? {
        return peripheralQueue.sync {  self._characteristics(withUUID: uuid) }
    }

    // MARK: Initialize

    public convenience override init() {
        self.init(queue: DispatchQueue(label: "com.gnos.us.peripheral-manger.main", qos: .background), options: nil)
    }

    public convenience init(options: [String : Any]? = nil) {
        self.init(queue: DispatchQueue(label: "com.gnos.us.peripheral-manger.main", qos: .background), options: options)
    }

    public init(queue: DispatchQueue, options: [String : Any]? = nil) {
        self.peripheralQueue = Queue(queue)
        self.options = options
        super.init()
        self.cbPeripheralManager = CBPeripheralManager(delegate:self, queue: self.peripheralQueue.queue, options: options)
    }

    init(peripheralManager: CBPeripheralManagerInjectable) {
        self.peripheralQueue = Queue("com.gnos.us.peripheral.main")
        super.init()
        self.cbPeripheralManager = peripheralManager
    }

    deinit {
        cbPeripheralManager?.delegate = nil
    }

    public func reset()  {
        return peripheralQueue.async { [weak self] in
            self.forEach { strongSelf in
                if strongSelf.cbPeripheralManager is CBPeripheralManager {
                    strongSelf.cbPeripheralManager.delegate = nil
                    strongSelf.cbPeripheralManager = CBPeripheralManager(delegate: strongSelf, queue: strongSelf.peripheralQueue.queue, options: strongSelf.options)
                    strongSelf.cbPeripheralManager?.delegate = self
                }
            }
        }
    }

    public func invalidate()  {
        peripheralQueue.async { [weak self] in
            self.forEach { strongSelf in
                strongSelf.afterAdvertisingStartedPromise = nil
                strongSelf.afterBeaconAdvertisingStartedPromise = nil
                strongSelf.afterStateChangedPromise = nil
                strongSelf.afterStateRestoredPromise = nil
            }
        }
        reset()
    }

    // MARK: Power ON/OFF

    public func whenStateChanges() -> FutureStream<ManagerState> {
        return self.peripheralQueue.sync {
            self.afterStateChangedPromise = StreamPromise<ManagerState>()
            self.afterStateChangedPromise?.success(self.cbPeripheralManager.managerState)
            return self.afterStateChangedPromise!.stream
        }
    }

    // MARK: Advertising

    public func startAdvertising(_ name: String, uuids: [CBUUID]? = nil) -> Future<Void> {
        return self.peripheralQueue.sync {
            if let afterAdvertisingStartedPromise = self.afterAdvertisingStartedPromise, !afterAdvertisingStartedPromise.completed {
                Logger.debug("Alerady adversting beacon")
                return afterAdvertisingStartedPromise.future
            }
            if !self.isAdvertising {
                Logger.debug("Adversting with UUIDs: \(String(describing: uuids))")
                self._name = name
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
                Logger.debug("Alerady adversting beacon")
                return afterBeaconAdvertisingStartedPromise.future
            }
            Logger.debug("Adversting beacon with UUID: \(String(describing: region.proximityUUID))")
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
    
    public func stopAdvertising(timeout: TimeInterval = 10.0) -> Future<Void> {
        return self.peripheralQueue.sync {
            guard self.isAdvertising else {
                return Future<Void>(value: ())
            }
            if let afterAdvertisingStoppedPromise = self.afterAdvertisingStoppedPromise, !afterAdvertisingStoppedPromise.completed {
                return afterAdvertisingStoppedPromise.future
            }
            self.afterAdvertisingStoppedPromise = Promise<Void>()
            self._name = nil
            self.cbPeripheralManager.stopAdvertising()
            self.timeoutStopAdvertising(timeout, sequence: self.stopAdvertisingTimeoutSequence)
            return self.afterAdvertisingStoppedPromise!.future
        }
    }

    // MARK: Manage Services

    public func add(_ service: MutableService) -> Future<Void> {
        return self.peripheralQueue.sync {
            Logger.debug("service name=\(service.name), uuid=\(service.uuid)")
            service.peripheralManager = self
            service.afterServiceAddPromise = Promise<Void>()
            if let services = self.configuredServices[service.uuid] {
                self.configuredServices[service.uuid] = services + [service]
            } else {
                self.configuredServices[service.uuid] = [service]
            }
            self.cbPeripheralManager.add(service.cbMutableService)
            return service.afterServiceAddPromise!.future
        }
    }
    
    public func remove(_ service: MutableService) {
        peripheralQueue.sync {
            guard let services = self.configuredServices[service.uuid] else {
                return
            }
            Logger.debug("removing service \(service.uuid.uuidString)")
            let remainingServices = services.filter { $0.cbMutableService !== service.cbMutableService }
            if remainingServices.count == 0 {
                self.configuredServices.removeValue(forKey: service.uuid)
            } else {
                self.configuredServices[service.uuid] = remainingServices
            }
            self.cbPeripheralManager.remove(service.cbMutableService)
        }
    }
    
    public func removeAllServices() {
        Logger.debug()
        peripheralQueue.sync {
            self.configuredServices.removeAll()
            self.cbPeripheralManager.removeAllServices()
        }
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

    public func whenStateRestored() -> Future<PeripheralAdvertisements> {
        return peripheralQueue.sync {
            if let afterStateRestoredPromise = self.afterStateRestoredPromise, !afterStateRestoredPromise.completed {
                return afterStateRestoredPromise.future
            }
            self.afterStateRestoredPromise = Promise<PeripheralAdvertisements>()
            return self.afterStateRestoredPromise!.future
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
        willRestoreState(injectableServices, advertisements: advertisements)
    }
    
    public func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        didStartAdvertising(error)
    }
    
    public func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        didAddService(service, error:error)
    }
    
    public func peripheralManager(_: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        didSubscribeToCharacteristic(characteristic, central: central)
    }
    
    public func peripheralManager(_: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        didUnsubscribeFromCharacteristic(characteristic, central: central)
    }
    
    public func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        didReceiveReadRequest(request, central: request.central)
    }
    
    public func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        isReadyToUpdateSubscribers()
    }

    public func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        Logger.debug()
        requests.forEach{ didReceiveWriteRequest($0, central: $0.central) }
    }

    // MARK: CBPeripheralManagerDelegate Shims

    func didSubscribeToCharacteristic(_ characteristic: CBCharacteristicInjectable, central: CBCentralInjectable) {
        Logger.debug()
        characteristicWithCBCharacteristic(characteristic)?.didSubscribeToCharacteristic(central)
    }
    
    func didUnsubscribeFromCharacteristic(_ characteristic: CBCharacteristicInjectable, central: CBCentralInjectable) {
        Logger.debug()
        characteristicWithCBCharacteristic(characteristic)?.didUnsubscribeFromCharacteristic(central)
    }
    
    func isReadyToUpdateSubscribers() {
        Logger.debug()
        for characteristic in _characteristics {
            if !characteristic._isUpdating {
                characteristic.peripheralManagerIsReadyToUpdateSubscribers()
            }
        }
    }
    
    func didReceiveWriteRequest(_ request: CBATTRequestInjectable, central: CBCentralInjectable) {
        if let characteristic = characteristicWithCBCharacteristic(request.getCharacteristic()) {
            Logger.debug("characteristic write request received for \(characteristic.uuid.uuidString)")
            if characteristic.didRespondToWriteRequest(request, central: central) {
                characteristic._value = request.value
            } else {
                respondToRequest(request, withResult:CBATTError.Code.requestNotSupported)
            }
        } else {
            respondToRequest(request, withResult:CBATTError.Code.unlikelyError)
        }
    }
    
    func didReceiveReadRequest(_ request: CBATTRequestInjectable, central: CBCentralInjectable) {
        var request = request
        Logger.debug("chracteracteristic \(request.getCharacteristic().uuid)")
        if let characteristic = characteristicWithCBCharacteristic(request.getCharacteristic()) {
            Logger.debug("responding with data: \(String(describing: characteristic._value.map { $0.hexStringValue() }))")
            request.value = characteristic._value
            respondToRequest(request, withResult:CBATTError.Code.success)
        } else {
            Logger.debug("characteristic not found")
            respondToRequest(request, withResult:CBATTError.Code.unlikelyError)
        }
    }
    
    func didUpdateState(_ peripheralManager: CBPeripheralManagerInjectable) {
        afterStateChangedPromise?.success(peripheralManager.managerState)
    }
    
    func didStartAdvertising(_ error: Error?) {
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
                afterAdvertisingStartedPromise.success(())
            }
            if let afterBeaconAdvertisingStartedPromise = self.afterBeaconAdvertisingStartedPromise, !afterBeaconAdvertisingStartedPromise.completed {
                afterBeaconAdvertisingStartedPromise.success(())
            }
        }
    }
    
    func didAddService(_ service: CBServiceInjectable, error: Error?) {
        guard let bcService = serviceWithCBService(service), let afterServiceAddPromise = bcService.afterServiceAddPromise else {
            Logger.debug("afterServiceAddPromise not found with UIID: \(service.uuid)")
            return
        }
        if let error = error {
            Logger.debug("failed '\(error.localizedDescription)'")
            self.configuredServices.removeValue(forKey: service.uuid)
            afterServiceAddPromise.failure(error)
        } else {
            Logger.debug("success")
            afterServiceAddPromise.success(())
        }
    }

    func willRestoreState(_ cbServices: [CBMutableServiceInjectable]?, advertisements: [String: Any]?) {
        if let cbServices = cbServices, let advertisements = advertisements {
            cbServices.forEach { cbService in
                let service = MutableService(cbMutableService: cbService)
                if let services = self.configuredServices[service.uuid] {
                    self.configuredServices[service.uuid] = services + [service]
                } else {
                    self.configuredServices[service.uuid] = [service]
                }
                var characteristics = [MutableCharacteristic]()
                if let cbCharacteristics = cbService.getCharacteristics() as? [CBMutableCharacteristic] {
                    characteristics = cbCharacteristics.map { bcChracteristic in
                        let characteristic = MutableCharacteristic(cbMutableCharacteristic: bcChracteristic)
                        return characteristic
                    }
                }
                service.characteristics = characteristics
            }
            if let completed = self.afterStateRestoredPromise?.completed, !completed {
                self.afterStateRestoredPromise?.success(PeripheralAdvertisements(advertisements: advertisements))
            }
        } else {
            if let completed = self.afterStateRestoredPromise?.completed, !completed {
                self.afterStateRestoredPromise?.failure(PeripheralManagerError.restoreFailed)
            }
        }
    }

    // MARK: Utils

    fileprivate func serviceWithCBService(_ cbService: CBServiceInjectable) -> MutableService? {
        return Array(self.configuredServices.values).flatMap { $0 }.filter { $0.cbMutableService === cbService }.first
    }

    fileprivate func characteristicWithCBCharacteristic(_ cbCharacteristic: CBCharacteristicInjectable) -> MutableCharacteristic? {
        let configuredCBServices = Array(self.configuredServices.values).flatMap { $0 }.map { $0.cbMutableService }
        for configuredCBService in configuredCBServices {
            guard let configuredCBCharacteristics = configuredCBService.getCharacteristics() else {
                continue
            }
            for configuredCBCharacteristic in configuredCBCharacteristics {
                if configuredCBCharacteristic === cbCharacteristic {
                    guard let bcService = self.serviceWithCBService(configuredCBService) else {
                        return nil
                    }
                    return bcService.characteristics.filter { $0.cbMutableChracteristic === cbCharacteristic }.first
                }
            }
        }
        return nil
    }


    fileprivate func timeoutStopAdvertising(_ timeout: TimeInterval, sequence: Int, count: Int = 0) {
        guard timeout < TimeInterval.infinity else {
            return
        }
        Logger.debug("stop advertising timeout in \(timeout)s")
        peripheralQueue.delay(WAIT_FOR_ADVERTISING_TO_STOP_POLLING_INTERVAL) { [weak self] in
            self.forEach { strongSelf in
                if strongSelf.isAdvertising {
                    let maxCount = Int(timeout / strongSelf.WAIT_FOR_ADVERTISING_TO_STOP_POLLING_INTERVAL)
                    if sequence == strongSelf.stopAdvertisingTimeoutSequence  &&  count > maxCount {
                        strongSelf.afterAdvertisingStoppedPromise?.failure(PeripheralManagerError.stopAdvertisingTimeout)
                    } else {
                        strongSelf.timeoutStopAdvertising(timeout, sequence: sequence, count: count + 1)
                    }
                } else {
                    strongSelf.afterAdvertisingStoppedPromise?.success(())
                }
            }
        }
    }

}
