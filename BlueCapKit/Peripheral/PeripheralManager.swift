//
//  PeripheralManager.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/9/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation
import CoreBluetooth

///////////////////////////////////////////
// PeripheralManagerImpl
public protocol PeripheralManagerWrappable {
    
    typealias WrappedService
    typealias WrappedBeaconRegion
    
    var isAdvertising   : Bool                      {get}
    var poweredOn       : Bool                      {get}
    var poweredOff      : Bool                      {get}
    var state           : CBPeripheralManagerState  {get}
    var services        : [WrappedService]          {get}
    
    func startAdvertising(advertisementData:[NSObject:AnyObject])
    func startAdversting(beaconRegion:WrappedBeaconRegion)
    func stopAdvertising()
    func addWrappedService(service:WrappedService)
    func removeWrappedService(service:WrappedService)
    func removeAllWrappedServices()
}

public struct PeripheralQueue {
    
    private static let queue = dispatch_queue_create("com.gnos.us.peripheral.main", DISPATCH_QUEUE_SERIAL)
    
    public static func sync(request:()->()) {
        dispatch_sync(self.queue, request)
    }
    
    public static func async(request:()->()) {
        dispatch_async(self.queue, request)
    }
    
    public static func delay(delay:Double, request:()->()) {
        let popTime = dispatch_time(DISPATCH_TIME_NOW, Int64(Float(delay)*Float(NSEC_PER_SEC)))
        dispatch_after(popTime, self.queue, request)
    }
    
}

public class PeripheralManagerImpl<Wrapper where Wrapper:PeripheralManagerWrappable,
                                                 Wrapper.WrappedService:MutableServiceWrappable,
                                                 Wrapper.WrappedBeaconRegion:BeaconRegionWrappable> {
    
    private let WAIT_FOR_ADVERTISING_TO_STOP_POLLING_INTERVAL : Double = 0.25
    
    private var afterAdvertisingStartedPromise      = Promise<Void>()
    private var afterAdvertsingStoppedPromise       = Promise<Void>()
    private var afterPowerOnPromise                 = Promise<Void>()
    private var afterPowerOffPromise                = Promise<Void>()
    private var afterSeriviceAddPromise             = Promise<Void>()
    
    
    // power on
    public func powerOn(peripheral:Wrapper) -> Future<Void> {
        Logger.debug("PeripheralManagerImpl#powerOn")
        self.afterPowerOnPromise = Promise<Void>()
        if peripheral.poweredOn {
            self.afterPowerOnPromise.success()
        }
        return self.afterPowerOnPromise.future
    }
    
    public func powerOff(peripheral:Wrapper) -> Future<Void> {
        Logger.debug("PeripheralManagerImpl#powerOff")
        self.afterPowerOffPromise = Promise<Void>()
        if peripheral.poweredOff {
            self.afterPowerOffPromise.success()
        }
        return self.afterPowerOffPromise.future
    }
    
    // advertising
    public func startAdvertising(peripheral:Wrapper, name:String, uuids:[CBUUID]?) -> Future<Void> {
        self.afterAdvertisingStartedPromise = Promise<Void>()
        if !peripheral.isAdvertising {
            var advertisementData : [NSObject:AnyObject] = [CBAdvertisementDataLocalNameKey:name]
            if let uuids = uuids {
                advertisementData[CBAdvertisementDataServiceUUIDsKey] = uuids
            }
            peripheral.startAdvertising(advertisementData)
        } else {
            self.afterAdvertisingStartedPromise.failure(BCError.peripheralManagerIsAdvertising)
        }
        return self.afterAdvertisingStartedPromise.future
    }
    
    public func startAdvertising(peripheral:Wrapper, name:String) -> Future<Void> {
        return self.startAdvertising(peripheral, name:name, uuids:nil)
    }
    
    public func startAdvertising(peripheral:Wrapper, region:Wrapper.WrappedBeaconRegion) -> Future<Void> {
        self.afterAdvertisingStartedPromise = Promise<Void>()
        if !peripheral.isAdvertising {
            peripheral.startAdvertising(region.peripheralDataWithMeasuredPower(nil))
        } else {
            self.afterAdvertisingStartedPromise.failure(BCError.peripheralManagerIsAdvertising)
        }
        return self.afterAdvertisingStartedPromise.future
    }
    
    public func stopAdvertising(peripheral:Wrapper) -> Future<Void> {
        self.afterAdvertsingStoppedPromise = Promise<Void>()
        if peripheral.isAdvertising {
            peripheral.stopAdvertising()
            PeripheralQueue.async{self.lookForAdvertisingToStop(peripheral)}
        } else {
            self.afterAdvertsingStoppedPromise.failure(BCError.peripheralManagerIsNotAdvertising)
        }
        return self.afterAdvertsingStoppedPromise.future
    }
    
    // services
    public func addService(peripheral:Wrapper, service:Wrapper.WrappedService) -> Future<Void> {
        self.afterSeriviceAddPromise = Promise<Void>()
        if !peripheral.isAdvertising {
            peripheral.addWrappedService(service)
            Logger.debug("PeripheralManagerImpl#addService:\(service.name), \(service.uuid)")
        } else {
            self.afterSeriviceAddPromise.failure(BCError.peripheralManagerIsAdvertising)
        }
        return self.afterSeriviceAddPromise.future
    }
    
    public func addServices(peripheral:Wrapper, services:[Wrapper.WrappedService]) -> Future<Void> {
        Logger.debug("PeripheralManagerImpl#addServices: service count \(services.count)")
        let promise = Promise<Void>()
        self.addService(peripheral, promise:promise, services:services)
        return promise.future
    }
    
    public func addService(peripheral:Wrapper, promise:Promise<Void>, services:[Wrapper.WrappedService]) {
        if services.count > 0 {
            let future = self.addService(peripheral, service:services[0])
            future.onSuccess {
                if services.count > 1 {
                    let servicesTail = Array(services[1...services.count-1])
                    Logger.debug("PeripheralManagerImpl#addServices: services remaining \(servicesTail.count)")
                    self.addService(peripheral, promise:promise, services:servicesTail)
                } else {
                    Logger.debug("PeripheralManagerImpl#addServices: completed")
                    promise.success()
                }
            }
            future.onFailure {(error) in
                let future = self.removeAllServices(peripheral)
                future.onSuccess {
                    Logger.debug("PeripheralManagerImpl#addServices: failed '\(error.localizedDescription)'")
                    promise.failure(error)
                }
            }
        }
    }
    
    public func removeService(peripheral:Wrapper, service:Wrapper.WrappedService) -> Future<Void> {
        let promise = Promise<Void>()
        if !peripheral.isAdvertising {
            Logger.debug("PeripheralManagerImpl#removeService: \(service.uuid.UUIDString)")
            peripheral.removeWrappedService(service)
            promise.success()
        } else {
            promise.failure(BCError.peripheralManagerIsAdvertising)
        }
        return promise.future
    }
    
    public func removeAllServices(peripheral:Wrapper) -> Future<Void> {
        let promise = Promise<Void>()
        if !peripheral.isAdvertising {
            Logger.debug("PeripheralManagerImpl#removeAllServices")
            peripheral.removeAllWrappedServices()
            promise.success()
        } else {
            promise.failure(BCError.peripheralManagerIsAdvertising)
        }
        return promise.future
    }
    
    // CBPeripheralManagerDelegate
    public func didUpdateState(peripheral:Wrapper) {
        switch peripheral.state {
        case CBPeripheralManagerState.PoweredOn:
            Logger.debug("PeripheralManagerImpl#peripheralManagerDidUpdateState: poweredOn")
            if !self.afterPowerOnPromise.completed() {
                self.afterPowerOnPromise.success()
            }
            break
        case CBPeripheralManagerState.PoweredOff:
            Logger.debug("PeripheralManagerImpl#peripheralManagerDidUpdateState: poweredOff")
            if !self.afterPowerOffPromise.completed() {
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
    
    public func didStartAdvertising(error:NSError!) {
        if let error = error {
            Logger.debug("PeripheralManagerImpl#peripheralManagerDidStartAdvertising: Failed '\(error.localizedDescription)'")
            self.afterAdvertisingStartedPromise.failure(error)
        } else {
            Logger.debug("PeripheralManagerImpl#peripheralManagerDidStartAdvertising: Success")
            self.afterAdvertisingStartedPromise.success()
        }
    }
    
    public func didAddService(error:NSError!) {
        if let error = error {
            Logger.debug("PeripheralManagerImpl#didAddService: Failed '\(error.localizedDescription)'")
            self.afterSeriviceAddPromise.failure(error)
        } else {
            Logger.debug("PeripheralManagerImpl#didAddService: Success")
            self.afterSeriviceAddPromise.success()
        }
    }
    
    public init() {
    }
    
    private func lookForAdvertisingToStop(peripheral:Wrapper) {
        if peripheral.isAdvertising {
            PeripheralQueue.delay(WAIT_FOR_ADVERTISING_TO_STOP_POLLING_INTERVAL) {
                self.lookForAdvertisingToStop(peripheral)
            }
        } else {
            Logger.debug("PeripheralImpl#lookForAdvertisingToStop: Advertising stopped")
            self.afterAdvertsingStoppedPromise.success()
        }
    }
}

// PeripheralManagerImpl
///////////////////////////////////////////
public class PeripheralManager : NSObject, CBPeripheralManagerDelegate, PeripheralManagerWrappable {
    
    private var impl = PeripheralManagerImpl<PeripheralManager>()
    
    // PeripheralManagerImpl
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
        return self.configuredServices.values.array
    }
    
    public func startAdvertising(advertisementData:[NSObject:AnyObject]) {
        self.cbPeripheralManager.startAdvertising(advertisementData)
    }
    
    public func startAdversting(region:BeaconRegion) {
        self.cbPeripheralManager.startAdvertising(region.peripheralDataWithMeasuredPower())
    }
    
    public func stopAdvertising() {
        self.cbPeripheralManager.stopAdvertising()
    }
    
    public func addWrappedService(service:MutableService) {
        self.configuredServices[service.uuid] = service
        self.cbPeripheralManager.addService(service.cbMutableService)
    }
    
    public func removeWrappedService(service:MutableService) {
        let removeCharacteristics = Array(self.configuredCharcteristics.keys).filter{(cbCharacteristic) in
            for bcCharacteristic in service.characteristics {
                if let uuid = cbCharacteristic.UUID {
                    if uuid == bcCharacteristic.uuid {
                        return true
                    }
                }
            }
            return false
        }
        for cbCharacteristic in removeCharacteristics {
            self.configuredCharcteristics.removeValueForKey(cbCharacteristic)
        }
        self.configuredServices.removeValueForKey(service.uuid)
        self.cbPeripheralManager.removeService(service.cbMutableService)
    }
    
    public func removeAllWrappedServices() {
        self.configuredServices.removeAll(keepCapacity:false)
        self.configuredCharcteristics.removeAll(keepCapacity:false)
        self.cbPeripheralManager.removeAllServices()
    }
    // PeripheralManagerImpl
    
    private var _name : String?

    internal var cbPeripheralManager        : CBPeripheralManager!
    internal var configuredServices         : [CBUUID:MutableService]                    = [:]
    internal var configuredCharcteristics   : [CBCharacteristic:MutableCharacteristic]   = [:]

    public class var sharedInstance : PeripheralManager {
        struct Static {
            static let instance = PeripheralManager()
        }
        return Static.instance
    }
    
    public func service(uuid:CBUUID) -> MutableService? {
        return self.configuredServices[uuid]
    }
    
    // power on
    public func powerOn() -> Future<Void> {
        return self.impl.powerOn(self)
    }
    
    public func powerOff() -> Future<Void> {
        return self.impl.powerOff(self)
    }

    // advertising
    public func startAdvertising(name:String, uuids:[CBUUID]?) -> Future<Void> {
        self._name = name
        return self.impl.startAdvertising(self, name:name, uuids:uuids)
    }
    
    public func startAdvertising(name:String) -> Future<Void> {
        return self.impl.startAdvertising(self, name:name)
    }
    
    public func startAdvertising(region:BeaconRegion) -> Future<Void> {
        self._name = region.identifier
        return self.impl.startAdvertising(self, region:region)
    }
    
    public func stopAdvertising() -> Future<Void> {
        self._name = nil
        return self.impl.stopAdvertising(self)
    }
    
    // services
    public func addService(service:MutableService) -> Future<Void> {
        return self.impl.addService(self, service:service)
    }
    
    public func addServices(services:[MutableService]) -> Future<Void> {
        return self.impl.addServices(self, services:services)
    }

    public func removeService(service:MutableService) -> Future<Void> {
        return self.impl.removeService(self, service:service)
    }
    
    public func removeAllServices() -> Future<Void> {
        return self.impl.removeAllServices(self)
    }

    // CBPeripheralManagerDelegate
    public func peripheralManagerDidUpdateState(_:CBPeripheralManager!) {
        self.impl.didUpdateState(self)
    }
    
    public func peripheralManager(_:CBPeripheralManager!, willRestoreState dict: [NSObject : AnyObject]!) {
    }
    
    public func peripheralManagerDidStartAdvertising(_:CBPeripheralManager!, error:NSError!) {
        self.impl.didStartAdvertising(error)
    }
    
    public func peripheralManager(_:CBPeripheralManager!, didAddService service:CBService!, error:NSError!) {
        if error != nil {
            self.configuredServices.removeValueForKey(service.UUID)
        }
        self.impl.didAddService(error)
    }
    
    public func peripheralManager(_:CBPeripheralManager!, central:CBCentral!, didSubscribeToCharacteristic characteristic:CBCharacteristic!) {
        Logger.debug("PeripheralManager#didSubscribeToCharacteristic")
    }
    
    public func peripheralManager(_:CBPeripheralManager!, central:CBCentral!, didUnsubscribeFromCharacteristic characteristic:CBCharacteristic!) {
        Logger.debug("PeripheralManager#didUnsubscribeFromCharacteristic")
    }
    
    public func peripheralManagerIsReadyToUpdateSubscribers(_:CBPeripheralManager!) {
        Logger.debug("PeripheralManager#peripheralManagerIsReadyToUpdateSubscribers")
    }
    
    public func peripheralManager(_:CBPeripheralManager!, didReceiveReadRequest request:CBATTRequest!) {
        Logger.debug("PeripheralManager#didReceiveReadRequest: chracteracteristic \(request.characteristic.UUID)")
        if let characteristic = self.configuredCharcteristics[request.characteristic] {
            Logger.debug("Responding with data: \(characteristic.stringValue)")
            request.value = characteristic.value
            self.cbPeripheralManager.respondToRequest(request, withResult:CBATTError.Success)
        } else {
            Logger.debug("Error: characteristic not found")
            self.cbPeripheralManager.respondToRequest(request, withResult:CBATTError.AttributeNotFound)
        }
    }
    
    public func peripheralManager(_:CBPeripheralManager!, didReceiveWriteRequests requests:[AnyObject]!) {
        Logger.debug("PeripheralManager#didReceiveWriteRequests")
        for request in requests {
            let cbattRequest = request as! CBATTRequest
            if let characteristic = self.configuredCharcteristics[cbattRequest.characteristic] {
                Logger.debug("characteristic write request received for \(characteristic.uuid.UUIDString)")
                if characteristic.didRespondToWriteRequest(cbattRequest) {
                    characteristic.value = cbattRequest.value
                } else {
                    characteristic.respondToRequest(cbattRequest, withResult:CBATTError.WriteNotPermitted)
                }
            } else {
                Logger.debug("Error: characteristic \(cbattRequest.characteristic.UUID.UUIDString) not found")
            }
        }
    }
    
    private override init() {
        super.init()
        self.cbPeripheralManager = CBPeripheralManager(delegate:self, queue:PeripheralQueue.queue)
    }
    
}
