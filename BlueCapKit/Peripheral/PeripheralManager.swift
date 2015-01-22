//
//  PeripheralManager.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/9/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation
import CoreBluetooth

public class PeripheralManager : NSObject, CBPeripheralManagerDelegate {
    
    private let WAIT_FOR_ADVERTISING_TO_STOP_POLLING_INTERVAL : Float = 0.25
    
    private var afterAdvertisingStartedPromise      = Promise<Void>()
    private var afterAdvertsingStoppedPromise       = Promise<Void>()
    private var afterPowerOnPromise                 = Promise<Void>()
    private var afterPowerOffPromise                = Promise<Void>()
    private var afterSeriviceAddPromise             = Promise<Void>()
    
    private let peripheralQueue = dispatch_queue_create("com.gnos.us.peripheral.main", DISPATCH_QUEUE_SERIAL)
    
    private var _name : String?

    private var _isPoweredOn    = false
    private var serviceAdded    = false

    internal var cbPeripheralManager        : CBPeripheralManager!
    internal var configuredServices         : Dictionary<CBUUID, MutableService>                    = [:]
    internal var configuredCharcteristics   : Dictionary<CBCharacteristic, MutableCharacteristic>   = [:]

    public var isAdvertising : Bool {
        return self.cbPeripheralManager.isAdvertising
    }
    
    public var state : CBPeripheralManagerState {
        return self.cbPeripheralManager.state
    }
    
    public var services : [MutableService] {
        return self.configuredServices.values.array
    }
    
    public var name : String? {
        return self._name
    }
    
    public var isPoweredOn : Bool {
        return self._isPoweredOn
    }

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
        Logger.debug("PeripheralManager#powerOn")
        let future = self.afterPowerOnPromise.future
        self.afterPowerOnPromise = Promise<Void>()
        return future
    }
    
    public func powerOff() -> Future<Void> {
        Logger.debug("PeripheralManager#powerOff")
        let future = self.afterPowerOffPromise.future
        self.afterPowerOffPromise = Promise<Void>()
        return future
    }

    // advertising
    public func startAdvertising(name:String, uuids:[CBUUID]?) -> Future<Void> {
        self._name = name
        self.afterAdvertisingStartedPromise = Promise<Void>()
        var advertisementData : [NSObject:AnyObject] = [CBAdvertisementDataLocalNameKey:name]
        if let uuids = uuids {
            advertisementData[CBAdvertisementDataServiceUUIDsKey] = uuids
        }
        self.cbPeripheralManager.startAdvertising(advertisementData)
        return self.afterAdvertisingStartedPromise.future
    }
    
    public func startAdvertising(name:String) -> Future<Void> {
        return self.startAdvertising(name, uuids:nil)
    }
    
    public func startAdvertising(region:BeaconRegion) -> Future<Void> {
        self._name = region.identifier
        self.afterAdvertisingStartedPromise = Promise<Void>()
        self.cbPeripheralManager.startAdvertising(region.clBeaconRegion.peripheralDataWithMeasuredPower(nil))
        return self.afterAdvertisingStartedPromise.future
    }
    
    public func stopAdvertising() -> Future<Void> {
        self._name = nil
        self.afterAdvertsingStoppedPromise = Promise<Void>()
        self.cbPeripheralManager.stopAdvertising()
        dispatch_async(self.peripheralQueue, {self.lookForAdvertisingToStop()})
        return self.afterAdvertsingStoppedPromise.future
    }
    
    // services
    public func addService(service:MutableService) -> Future<Void> {
        if !self.isAdvertising {
            self.afterSeriviceAddPromise = Promise<Void>()
            self.configuredServices[service.uuid] = service
            self.cbPeripheralManager.addService(service.cbMutableService)
        } else {
            NSException(name:"Add service failed", reason: "Peripheral is advertising", userInfo: nil).raise()
        }
        return self.afterSeriviceAddPromise.future
    }
    
    public func addServices(services:[MutableService]) -> Future<Void> {
        Logger.debug("PeripheralManager#addServices: service count \(services.count)")
        let promise = Promise<Void>()
        self.addService(promise, services:services)
        return promise.future
    }

    private func addService(promise:Promise<Void>, services:[MutableService]) {
        if services.count > 0 {
            let future = self.addService(services[0])
            future.onSuccess {
                if services.count > 1 {
                    let servicesTail = Array(services[1...services.count-1])
                    Logger.debug("PeripheralManager#addServices: services remaining \(servicesTail.count)")
                    self.addService(promise, services:servicesTail)
                } else {
                    Logger.debug("PeripheralManager#addServices: completed")
                    promise.success()
                }
            }
            future.onFailure {(error) in
                let future = self.removeAllServices()
                future.onSuccess {
                    Logger.debug("PeripheralManager#addServices: failed '\(error.localizedDescription)'")
                    promise.failure(error)
                }
            }
        }
    }
    
    public func removeService(service:MutableService) -> Future<Void> {
        let promise = Promise<Void>()
        if !self.isAdvertising {
            Logger.debug("PeripheralManager#removeService: \(service.uuid.UUIDString)")
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
            promise.success()
        } else {
            promise.failure(BCError.peripheralManagerIsAdvertising)
        }
        return promise.future
    }
    
    public func removeAllServices() -> Future<Void> {
        let promise = Promise<Void>()
        if !self.isAdvertising {
            Logger.debug("PeripheralManager#removeAllServices")
            self.configuredServices.removeAll(keepCapacity:false)
            self.configuredCharcteristics.removeAll(keepCapacity:false)
            self.cbPeripheralManager.removeAllServices()
            promise.success()
        } else {
            promise.failure(BCError.peripheralManagerIsAdvertising)
        }
        return promise.future
    }

    // CBPeripheralManagerDelegate
    public func peripheralManagerDidUpdateState(_:CBPeripheralManager!) {
        switch self.state {
        case CBPeripheralManagerState.PoweredOn:
            Logger.debug("PeripheralManager#peripheralManagerDidUpdateState: poweredOn")
            self.afterPowerOnPromise.success()
            self._isPoweredOn = true
            break
        case CBPeripheralManagerState.PoweredOff:
            Logger.debug("PeripheralManager#peripheralManagerDidUpdateState: poweredOff")
            self.afterPowerOffPromise.success()
            self._isPoweredOn = false
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
    
    public func peripheralManager(_:CBPeripheralManager!, willRestoreState dict: [NSObject : AnyObject]!) {
    }
    
    public func peripheralManagerDidStartAdvertising(_:CBPeripheralManager!, error:NSError!) {
        if let error = error {
            Logger.debug("PeripheralManager#peripheralManagerDidStartAdvertising: Failed '\(error.localizedDescription)'")
            self.afterAdvertisingStartedPromise.failure(error)
        } else {
            Logger.debug("PeripheralManager#peripheralManagerDidStartAdvertising: Success")
            self.afterAdvertisingStartedPromise.success()
        }
    }
    
    public func peripheralManager(_:CBPeripheralManager!, didAddService service:CBService!, error:NSError!) {
        if let bcService = self.configuredServices[service.UUID] {
            self.serviceAdded = true
            if let error = error {
                Logger.debug("PeripheralManager#didAddService: Failed '\(error.localizedDescription)'")
                self.configuredServices.removeValueForKey(service.UUID)
                self.afterSeriviceAddPromise.failure(error)
            } else {
                Logger.debug("PeripheralManager#didAddService: Success")
                self.afterSeriviceAddPromise.success()
            }
        }
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
            if let cbattRequest = request as? CBATTRequest {
                if let characteristic = self.configuredCharcteristics[cbattRequest.characteristic] {
                    Logger.debug("characteristic write request received for \(characteristic.uuid.UUIDString)")
                    characteristic.value = request.value
                    if let processWriteRequestPromise = characteristic.processWriteRequestPromise {
                        processWriteRequestPromise.success(cbattRequest)
                    }
                } else {
                    Logger.debug("Error: characteristic \(cbattRequest.characteristic.UUID.UUIDString) not found")
                }
            } else {
                Logger.debug("Error: request cast failed")
            }
        }
    }
    
    private override init() {
        super.init()
        self.cbPeripheralManager = CBPeripheralManager(delegate:self, queue:self.peripheralQueue)
    }
    
    private func lookForAdvertisingToStop() {
        if self.isAdvertising {
            let popTime = dispatch_time(DISPATCH_TIME_NOW, Int64(WAIT_FOR_ADVERTISING_TO_STOP_POLLING_INTERVAL * Float(NSEC_PER_SEC)))
            dispatch_after(popTime, self.peripheralQueue, {
                self.lookForAdvertisingToStop()
            })
        } else {
            Logger.debug("Peripheral#lookForAdvertisingToStop: Advertising stopped")
            self.afterAdvertsingStoppedPromise.success()
        }
    }    
}
