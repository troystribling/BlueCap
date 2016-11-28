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

    fileprivate let WAIT_FOR_ADVERTISING_TO_STOP_POLLING_INTERVAL   = 0.25

    // MARK: Properties

    fileprivate var _name: String?
    internal fileprivate(set) var cbPeripheralManager: CBPeripheralManagerInjectable!
    
    fileprivate var afterAdvertisingStartedPromise: Promise<Void>?
    fileprivate var afterBeaconAdvertisingStartedPromise: Promise<Void>?

    fileprivate var options: [String : Any]?

    fileprivate var afterStateChangedPromise: StreamPromise<ManagerState>?
    fileprivate var afterStateRestoredPromise: Promise<(services: [MutableService], advertisements: PeripheralAdvertisements)>?
    fileprivate var afterSeriviceAddPromise: Promise<Void>?

    fileprivate var configuredServices  = [CBUUID : MutableService]()
    fileprivate var configuredCharcteristics = [CBUUID : MutableCharacteristic]()

    internal let peripheralQueue: Queue

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
        return peripheralQueue.sync { return Array(self.configuredServices.values) }
    }

    public var characteristics: [MutableCharacteristic] {
        return peripheralQueue.sync { Array(self.configuredCharcteristics.values) }
    }

    public func service(withUUID uuid: CBUUID) -> MutableService? {
        return peripheralQueue.sync { return self.configuredServices[uuid] }
    }

    public func characteristic(withUUID uuid: CBUUID) -> MutableCharacteristic? {
        return peripheralQueue.sync { return self.configuredCharcteristics[uuid] }
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
        return self.peripheralQueue.sync {
            self.afterAdvertisingStartedPromise = nil
            self.afterBeaconAdvertisingStartedPromise = nil
            self.afterStateChangedPromise = nil
            self.afterStateRestoredPromise = nil
            self.afterSeriviceAddPromise = nil
            if self.cbPeripheralManager is CBPeripheralManager {
                self.cbPeripheralManager = CBPeripheralManager(delegate:self, queue: self.peripheralQueue.queue, options: self.options)
                self.cbPeripheralManager?.delegate = self
            }
        }
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
                Logger.debug("Adversting with UUIDs: \(uuids.map { $0 })")
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
            Logger.debug("Adversting beacon with UUID: \(region.proximityUUID)")
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

    public func add(_ service: MutableService) -> Future<Void> {
        return self.peripheralQueue.sync {
            if let afterSeriviceAddPromise = self.afterSeriviceAddPromise, !afterSeriviceAddPromise.completed {
                return afterSeriviceAddPromise.future
            }
            Logger.debug("service name=\(service.name), uuid=\(service.uuid)")
            service.peripheralManager = self
            self.addConfiguredCharacteristics(service.characteristics)
            self.afterSeriviceAddPromise = Promise<Void>()
            self.configuredServices[service.uuid] = service
            self.cbPeripheralManager.add(service.cbMutableService)
            return self.afterSeriviceAddPromise!.future
        }
    }
    
    public func remove(_ service: MutableService) {
        peripheralQueue.sync {
            Logger.debug("removing service \(service.uuid.uuidString)")
            let removedCharacteristics = Array(self.configuredCharcteristics.keys).filter{(uuid) in
                for bcCharacteristic in service.characteristics {
                    if uuid == bcCharacteristic.uuid {
                        return true
                    }
                }
                return false
            }
            for cbCharacteristic in removedCharacteristics {
                self.configuredCharcteristics.removeValue(forKey: cbCharacteristic)
            }
            self.configuredServices.removeValue(forKey: service.uuid)
            self.cbPeripheralManager.remove(service.cbMutableService)
        }
    }
    
    public func removeAllServices() {
        Logger.debug()
        peripheralQueue.sync {
            self.configuredServices.removeAll()
            self.configuredCharcteristics.removeAll()
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

    public func whenStateRestored() -> Future<(services: [MutableService], advertisements: PeripheralAdvertisements)> {
        return peripheralQueue.sync {
            if let afterStateRestoredPromise = self.afterStateRestoredPromise, !afterStateRestoredPromise.completed {
                return afterStateRestoredPromise.future
            }
            self.afterStateRestoredPromise = Promise<(services: [MutableService], advertisements: PeripheralAdvertisements)>()
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
        self.willRestoreState(injectableServices, advertisements: advertisements)
    }
    
    public func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        self.didStartAdvertising(error)
    }
    
    public func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
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
        requests.forEach{ didReceiveWriteRequest($0, central: $0.central) }
    }

    // MARK: CBPeripheralManagerDelegate Shims

    func didSubscribeToCharacteristic(_ characteristic: CBCharacteristicInjectable, central: CBCentralInjectable) {
        Logger.debug()
        self.configuredCharcteristics[characteristic.uuid]?.didSubscribeToCharacteristic(central)
    }
    
    func didUnsubscribeFromCharacteristic(_ characteristic: CBCharacteristicInjectable, central: CBCentralInjectable) {
        Logger.debug()
        self.configuredCharcteristics[characteristic.uuid]?.didUnsubscribeFromCharacteristic(central)
    }
    
    func isReadyToUpdateSubscribers() {
        Logger.debug()
        for characteristic in self.configuredCharcteristics.values {
            if !characteristic._isUpdating {
                characteristic.peripheralManagerIsReadyToUpdateSubscribers()
            }
        }
    }
    
    func didReceiveWriteRequest(_ request: CBATTRequestInjectable, central: CBCentralInjectable) {
        if let characteristic = self.configuredCharcteristics[request.getCharacteristic().uuid] {
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
        if let characteristic = self.configuredCharcteristics[request.getCharacteristic().uuid] {
            Logger.debug("responding with data: \(characteristic._value)")
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
                afterAdvertisingStartedPromise.success()
            }
            if let afterBeaconAdvertisingStartedPromise = self.afterBeaconAdvertisingStartedPromise, !afterBeaconAdvertisingStartedPromise.completed {
                afterBeaconAdvertisingStartedPromise.success()
            }
        }
    }
    
    func didAddService(_ service: CBServiceInjectable, error: Error?) {
        if let error = error {
            Logger.debug("failed '\(error.localizedDescription)'")
            self.configuredServices.removeValue(forKey: service.uuid)
            self.afterSeriviceAddPromise?.failure(error)
        } else {
            Logger.debug("success")
            self.afterSeriviceAddPromise?.success()
        }
    }

    func willRestoreState(_ cbServices: [CBMutableServiceInjectable]?, advertisements: [String: Any]?) {
        if let cbServices = cbServices, let advertisements = advertisements {
            let services = cbServices.map { cbService -> MutableService in
                let service = MutableService(cbMutableService: cbService)
                self.configuredServices[service.uuid] = service
                var characteristics = [MutableCharacteristic]()
                if let cbCharacteristics = cbService.getCharacteristics() as? [CBMutableCharacteristic] {
                    characteristics = cbCharacteristics.map { bcChracteristic in
                        let characteristic = MutableCharacteristic(cbMutableCharacteristic: bcChracteristic)
                        self.configuredCharcteristics[characteristic.uuid] = characteristic
                        return characteristic
                    }
                }
                service.characteristics = characteristics
                return service
            }
            if let completed = self.afterStateRestoredPromise?.completed, !completed {
                self.afterStateRestoredPromise?.success((services, PeripheralAdvertisements(advertisements: advertisements)))
            }
        } else {
            if let completed = self.afterStateRestoredPromise?.completed, !completed {
                self.afterStateRestoredPromise?.failure(PeripheralManagerError.restoreFailed)
            }
        }
    }

    // MARK: Utils

    fileprivate func addConfiguredCharacteristics(_ characteristics: [MutableCharacteristic]) {
        for characteristic in characteristics {
            self.configuredCharcteristics[characteristic.cbMutableChracteristic.uuid] = characteristic
        }
    }

}
