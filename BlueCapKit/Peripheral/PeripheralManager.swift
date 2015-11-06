//
//  PeripheralManager.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/9/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import Foundation
import CoreBluetooth

///////////////////////////////////////////
// PeripheralManagerImpl
public protocol CBPeripheralManagerWrappable {
    
    var isAdvertising   : Bool                      {get}
    var state           : CBPeripheralManagerState  {get}
    
    func startAdvertising(advertisementData:[String:AnyObject]?)
    func stopAdvertising()
    func addService(service:CBMutableService)
    func removeService(service:CBMutableService)
    func removeAllServices()
    func respondToRequest(request:CBATTRequest, withResult result:CBATTError)
    func updateValue(value:NSData, forCharacteristic characteristic:CBMutableCharacteristic, onSubscribedCentrals centrals:[CBCentral]?) -> Bool
}

extension CBPeripheralManager : CBPeripheralManagerWrappable {}

public class PeripheralManager : NSObject, CBPeripheralManagerDelegate {
    
    private let WAIT_FOR_ADVERTISING_TO_STOP_POLLING_INTERVAL : Double                  = 0.25

    private var _name : String?
    
    private var afterAdvertisingStartedPromise                                          = Promise<Void>()
    private var afterAdvertsingStoppedPromise                                           = Promise<Void>()
    private var afterPowerOnPromise                                                     = Promise<Void>()
    private var afterPowerOffPromise                                                    = Promise<Void>()
    private var afterSeriviceAddPromise                                                 = Promise<Void>()

    internal var configuredServices  : [CBUUID:MutableService]                          = [:]
    internal var configuredCharcteristics : [CBCharacteristic:MutableCharacteristic]    = [:]
    private var cbPeripheralManager : CBPeripheralManagerWrappable!

    public let peripheralQueue : Queue
    
    public var isAdvertising : Bool {
        return self.cbPeripheralManager.isAdvertising
    }
    
    public var poweredOn : Bool {
        return self.cbPeripheralManager.state == CBPeripheralManagerState.PoweredOn
    }
    
    public var poweredOff : Bool {
        return self.cbPeripheralManager.state == CBPeripheralManagerState.PoweredOff
    }

    public var state : CBPeripheralManagerState {
        return self.cbPeripheralManager.state
    }
    
    public var services : [MutableService] {
        return Array(self.configuredServices.values)
    }
    
    public func addWrappedService(service:MutableService) {
        self.configuredServices[service.uuid] = service
        self.cbPeripheralManager.addService(service.cbMutableService)
    }
    
    public class var sharedInstance : PeripheralManager {
        struct StaticInstance {
            static var onceToken : dispatch_once_t      = 0
            static var instance : PeripheralManager?    = nil
        }
        dispatch_once(&StaticInstance.onceToken) {
            StaticInstance.instance = PeripheralManager()
        }
        return StaticInstance.instance!
    }
    
    public class func sharedInstance(options:[String:AnyObject]) -> PeripheralManager {
        struct StaticInstance {
            static var onceToken : dispatch_once_t      = 0
            static var instance : PeripheralManager?   = nil
        }
        dispatch_once(&StaticInstance.onceToken) {
            StaticInstance.instance = PeripheralManager(options:options)
        }
        return StaticInstance.instance!
    }
    
    private override init() {
        self.peripheralQueue = Queue(dispatch_queue_create("com.gnos.us.peripheral.main", DISPATCH_QUEUE_SERIAL))
        super.init()
        self.cbPeripheralManager = CBPeripheralManager(delegate:self, queue:self.peripheralQueue.queue)
    }
    
    private init(options:[String:AnyObject]) {
        self.peripheralQueue = Queue(dispatch_queue_create("com.gnos.us.peripheral.main", DISPATCH_QUEUE_SERIAL))
        super.init()
        self.cbPeripheralManager = CBPeripheralManager(delegate:self, queue:self.peripheralQueue.queue, options:options)
    }

    public init(queue:dispatch_queue_t, options:[String:AnyObject]?=nil) {
        self.peripheralQueue = Queue(queue)
        super.init()
        self.cbPeripheralManager = CBPeripheralManager(delegate:self, queue:self.peripheralQueue.queue, options:options)
    }

    public init(peripheralManager:CBPeripheralManagerWrappable) {
        self.peripheralQueue = Queue(dispatch_queue_create("com.gnos.us.peripheral.main", DISPATCH_QUEUE_SERIAL))
        super.init()
        self.cbPeripheralManager = peripheralManager
    }

    public func service(uuid:CBUUID) -> MutableService? {
        return self.configuredServices[uuid]
    }
    
    public func powerOn() -> Future<Void> {
        Logger.debug()
        self.peripheralQueue.sync {
            self.afterPowerOnPromise = Promise<Void>()
            if self.poweredOn {
                self.afterPowerOnPromise.success()
            }
        }
        return self.afterPowerOnPromise.future
    }
    
    public func powerOff() -> Future<Void> {
        Logger.debug()
        self.peripheralQueue.sync {
            self.afterPowerOffPromise = Promise<Void>()
            if self.poweredOff {
                self.afterPowerOffPromise.success()
            }
        }
        return self.afterPowerOffPromise.future
    }

    public func startAdvertising(name:String, uuids:[CBUUID]? = nil) -> Future<Void> {
        self._name = name
        self.peripheralQueue.sync {
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
        }
        return self.afterAdvertisingStartedPromise.future
    }
    
    public func startAdvertising(region:BeaconRegion) -> Future<Void> {
        self._name = region.identifier
        self.peripheralQueue.sync {
            self.afterAdvertisingStartedPromise = Promise<Void>()
            if !self.isAdvertising {
                self.cbPeripheralManager.startAdvertising(region.peripheralDataWithMeasuredPower(nil))
            } else {
                self.afterAdvertisingStartedPromise.failure(BCError.peripheralManagerIsAdvertising)
            }
        }
        return self.afterAdvertisingStartedPromise.future
    }
    
    public func stopAdvertising() -> Future<Void> {
        self._name = nil
        self.peripheralQueue.sync {
            self.afterAdvertsingStoppedPromise = Promise<Void>()
            if self.isAdvertising {
                 self.cbPeripheralManager.stopAdvertising()
                self.peripheralQueue.async{self.lookForAdvertisingToStop()}
            } else {
                self.afterAdvertsingStoppedPromise.failure(BCError.peripheralManagerIsNotAdvertising)
            }
        }
        return self.afterAdvertsingStoppedPromise.future
    }
    
    public func addService(service:MutableService) -> Future<Void> {
        self.addConfiguredCharacteristics(service.characteristics)
        self.peripheralQueue.sync {
            self.afterSeriviceAddPromise = Promise<Void>()
            if !self.isAdvertising {
                self.configuredServices[service.uuid] = service
                self.cbPeripheralManager.addService(service.cbMutableService)
                Logger.debug("service name=\(service.name), uuid=\(service.uuid)")
            } else {
                self.afterSeriviceAddPromise.failure(BCError.peripheralManagerIsAdvertising)
            }
        }
        return self.afterSeriviceAddPromise.future
    }
    
    public func addServices(services:[MutableService]) -> Future<Void> {
        Logger.debug("service count \(services.count)")
        for service in services {
            self.addConfiguredCharacteristics(service.characteristics)
        }
        let promise = Promise<Void>()
        self.addServices(promise, services:services)
        return promise.future
    }

    public func removeService(service:MutableService) -> Future<Void> {
        let promise = Promise<Void>()
        if !self.isAdvertising {
            Logger.debug("removing service \(service.uuid.UUIDString)")
            self.removeServiceAndCharacteristics(service)
            promise.success()
        } else {
            promise.failure(BCError.peripheralManagerIsAdvertising)
        }
        return promise.future
    }
    
    public func removeAllServices() -> Future<Void> {
        let promise = Promise<Void>()
        if !self.isAdvertising {
            Logger.debug()
            self.removeAllServiceAndCharacteristics()
            promise.success()
        } else {
            promise.failure(BCError.peripheralManagerIsAdvertising)
        }
        return promise.future
    }

    public func updateValue(value:NSData, forCharacteristic characteristic:MutableCharacteristic) -> Bool  {
        return self.cbPeripheralManager.updateValue(value, forCharacteristic:characteristic.cbMutableChracteristic, onSubscribedCentrals:nil)
    }
    
    public func respondToRequest(request:CBATTRequest, withResult result:CBATTError) {
        self.cbPeripheralManager.respondToRequest(request, withResult:result)
    }

    // CBPeripheralManagerDelegate
    public func peripheralManagerDidUpdateState(_:CBPeripheralManager) {
        self.didUpdateState()
    }
    
    public func peripheralManager(_:CBPeripheralManager, willRestoreState dict:[String:AnyObject]) {
    }
    
    public func peripheralManagerDidStartAdvertising(_:CBPeripheralManager, error:NSError?) {
        self.didStartAdvertising(error)
    }
    
    public func peripheralManager(_:CBPeripheralManager, didAddService service:CBService, error:NSError?) {
        self.didAddService(service, error:error)
    }
    
    public func peripheralManager(_:CBPeripheralManager, central:CBCentral, didSubscribeToCharacteristic characteristic:CBCharacteristic) {
        Logger.debug()
        if let characteristic = self.configuredCharcteristics[characteristic] {
            characteristic.didSubscribeToCharacteristic()
        }
    }
    
    public func peripheralManager(_:CBPeripheralManager, central:CBCentral, didUnsubscribeFromCharacteristic characteristic:CBCharacteristic) {
        Logger.debug()
        if let characteristic = self.configuredCharcteristics[characteristic] {
            characteristic.didUnsubscribeFromCharacteristic()
        }
    }
    
    public func peripheralManagerIsReadyToUpdateSubscribers(_:CBPeripheralManager) {
        Logger.debug()
        for characteristic in self.configuredCharcteristics.values {
            if characteristic.hasSubscriber {
                characteristic.peripheralManagerIsReadyToUpdateSubscribers()
            }
        }
    }
    
    public func peripheralManager(_:CBPeripheralManager, didReceiveReadRequest request:CBATTRequest) {
        Logger.debug("chracteracteristic \(request.characteristic.UUID)")
        if let characteristic = self.configuredCharcteristics[request.characteristic] {
            Logger.debug("responding with data: \(characteristic.stringValue)")
            request.value = characteristic.value
            self.cbPeripheralManager.respondToRequest(request, withResult:CBATTError.Success)
        } else {
            Logger.debug("characteristic not found")
            self.cbPeripheralManager.respondToRequest(request, withResult:CBATTError.AttributeNotFound)
        }
    }
    
    public func peripheralManager(_:CBPeripheralManager, didReceiveWriteRequests requests:[CBATTRequest]) {
        Logger.debug()
        for request in requests {
            if let characteristic = self.configuredCharcteristics[request.characteristic] {
                Logger.debug("characteristic write request received for \(characteristic.uuid.UUIDString)")
                if characteristic.didRespondToWriteRequest(request) {
                    characteristic.value = request.value
                } else {
                    characteristic.respondToRequest(request, withResult:CBATTError.WriteNotPermitted)
                }
            } else {
                Logger.debug("error writing characteristic \(request.characteristic.UUID.UUIDString) not found")
            }
        }
    }
    
    public func didUpdateState() {
        switch self.state {
        case CBPeripheralManagerState.PoweredOn:
            Logger.debug("poweredOn")
            if !self.afterPowerOnPromise.completed {
                self.afterPowerOnPromise.success()
            }
            break
        case CBPeripheralManagerState.PoweredOff:
            Logger.debug("poweredOff")
            if !self.afterPowerOffPromise.completed {
                self.afterPowerOffPromise.success()
            }
            break
        case CBPeripheralManagerState.Resetting:
            break
        case CBPeripheralManagerState.Unsupported:
            break
        case CBPeripheralManagerState.Unauthorized:
            break
        case CBPeripheralManagerState.Unknown:
            break
        }
    }
    
    public func didStartAdvertising(error:NSError?) {
        if let error = error {
            Logger.debug("failed '\(error.localizedDescription)'")
            self.afterAdvertisingStartedPromise.failure(error)
        } else {
            Logger.debug("success")
            self.afterAdvertisingStartedPromise.success()
        }
    }
    
    public func didAddService(service:CBService, error:NSError?) {
        if let error = error {
            Logger.debug("failed '\(error.localizedDescription)'")
            self.configuredServices.removeValueForKey(service.UUID)
            self.afterSeriviceAddPromise.failure(error)
        } else {
            Logger.debug("success")
            self.afterSeriviceAddPromise.success()
        }
    }

    private func addServices(promise:Promise<Void>, services:[MutableService]) {
        if services.count > 0 {
            let future = self.addService(services[0])
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
                let future = self.removeAllServices()
                future.onSuccess {
                    Logger.debug("failed '\(error.localizedDescription)'")
                    promise.failure(error)
                }
            }
        }
    }

    private func lookForAdvertisingToStop() {
        if self.isAdvertising {
            self.peripheralQueue.delay(WAIT_FOR_ADVERTISING_TO_STOP_POLLING_INTERVAL) {
                self.lookForAdvertisingToStop()
            }
        } else {
            Logger.debug("advertising stopped")
            self.afterAdvertsingStoppedPromise.success()
        }
    }

    private func addConfiguredCharacteristics(characteristics:[MutableCharacteristic]) {
        for characteristic in characteristics {
            self.configuredCharcteristics[characteristic.cbMutableChracteristic] = characteristic
        }
    }

    private func removeServiceAndCharacteristics(service:MutableService) {
        let removedCharacteristics = Array(self.configuredCharcteristics.keys).filter{(cbCharacteristic) in
            for bcCharacteristic in service.characteristics {
                let uuid = cbCharacteristic.UUID
                if uuid == bcCharacteristic.uuid {
                    return true
                }
            }
            return false
        }
        for cbCharacteristic in removedCharacteristics {
            self.configuredCharcteristics.removeValueForKey(cbCharacteristic)
        }
        self.configuredServices.removeValueForKey(service.uuid)
        self.cbPeripheralManager.removeService(service.cbMutableService)
    }
    
    private func removeAllServiceAndCharacteristics() {
        self.configuredServices.removeAll(keepCapacity:false)
        self.configuredCharcteristics.removeAll(keepCapacity:false)
        self.cbPeripheralManager.removeAllServices()
    }

}
