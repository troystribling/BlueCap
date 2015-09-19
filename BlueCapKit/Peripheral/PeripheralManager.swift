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
public protocol PeripheralManagerWrappable {
    
    typealias WrappedService
    typealias WrappedBeaconRegion
    
    var isAdvertising   : Bool                      {get}
    var poweredOn       : Bool                      {get}
    var poweredOff      : Bool                      {get}
    var state           : CBPeripheralManagerState  {get}
    var services        : [WrappedService]          {get}
    
    func startAdvertising(advertisementData:[String:AnyObject])
    func startAdversting(beaconRegion:WrappedBeaconRegion)
    func stopAdvertisingWrapped()
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
        Logger.debug()
        PeripheralQueue.sync {
            self.afterPowerOnPromise = Promise<Void>()
            if peripheral.poweredOn {
                self.afterPowerOnPromise.success()
            }
        }
        return self.afterPowerOnPromise.future
    }
    
    public func powerOff(peripheral:Wrapper) -> Future<Void> {
        Logger.debug()
        PeripheralQueue.sync {
            self.afterPowerOffPromise = Promise<Void>()
            if peripheral.poweredOff {
                self.afterPowerOffPromise.success()
            }
        }
        return self.afterPowerOffPromise.future
    }
    
    // advertising
    public func startAdvertising(peripheral:Wrapper, name:String, uuids:[CBUUID]?) -> Future<Void> {
        PeripheralQueue.sync {
            self.afterAdvertisingStartedPromise = Promise<Void>()
            if !peripheral.isAdvertising {
                var advertisementData : [String:AnyObject] = [CBAdvertisementDataLocalNameKey:name]
                if let uuids = uuids {
                    advertisementData[CBAdvertisementDataServiceUUIDsKey] = uuids
                }
                peripheral.startAdvertising(advertisementData)
            } else {
                self.afterAdvertisingStartedPromise.failure(BCError.peripheralManagerIsAdvertising)
            }
        }
        return self.afterAdvertisingStartedPromise.future
    }
    
    public func startAdvertising(peripheral:Wrapper, name:String) -> Future<Void> {
        return self.startAdvertising(peripheral, name:name, uuids:nil)
    }
    
    public func startAdvertising(peripheral:Wrapper, region:Wrapper.WrappedBeaconRegion) -> Future<Void> {
        PeripheralQueue.sync {
            self.afterAdvertisingStartedPromise = Promise<Void>()
            if !peripheral.isAdvertising {
                peripheral.startAdvertising(region.peripheralDataWithMeasuredPower(nil))
            } else {
                self.afterAdvertisingStartedPromise.failure(BCError.peripheralManagerIsAdvertising)
            }
        }
        return self.afterAdvertisingStartedPromise.future
    }
    
    public func stopAdvertising(peripheral:Wrapper) -> Future<Void> {
        PeripheralQueue.sync {
            self.afterAdvertsingStoppedPromise = Promise<Void>()
            if peripheral.isAdvertising {
                peripheral.stopAdvertisingWrapped()
                PeripheralQueue.async{self.lookForAdvertisingToStop(peripheral)}
            } else {
                self.afterAdvertsingStoppedPromise.failure(BCError.peripheralManagerIsNotAdvertising)
            }
        }
        return self.afterAdvertsingStoppedPromise.future
    }
    
    // services
    public func addService(peripheral:Wrapper, service:Wrapper.WrappedService) -> Future<Void> {
        PeripheralQueue.sync {
            self.afterSeriviceAddPromise = Promise<Void>()
            if !peripheral.isAdvertising {
                peripheral.addWrappedService(service)
                Logger.debug("service name=\(service.name), uuid=\(service.uuid)")
            } else {
                self.afterSeriviceAddPromise.failure(BCError.peripheralManagerIsAdvertising)
            }
        }
        return self.afterSeriviceAddPromise.future
    }
    
    public func addServices(peripheral:Wrapper, services:[Wrapper.WrappedService]) -> Future<Void> {
        Logger.debug("service count \(services.count)")
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
                    Logger.debug("services remaining \(servicesTail.count)")
                    self.addService(peripheral, promise:promise, services:servicesTail)
                } else {
                    Logger.debug("completed")
                    promise.success()
                }
            }
            future.onFailure {(error) in
                let future = self.removeAllServices(peripheral)
                future.onSuccess {
                    Logger.debug("failed '\(error.localizedDescription)'")
                    promise.failure(error)
                }
            }
        }
    }
    
    public func removeService(peripheral:Wrapper, service:Wrapper.WrappedService) -> Future<Void> {
        let promise = Promise<Void>()
        if !peripheral.isAdvertising {
            Logger.debug("removing service \(service.uuid.UUIDString)")
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
            Logger.debug()
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
    
    public func didAddService(error:NSError?) {
        if let error = error {
            Logger.debug("failed '\(error.localizedDescription)'")
            self.afterSeriviceAddPromise.failure(error)
        } else {
            Logger.debug("success")
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
            Logger.debug("advertising stopped")
            self.afterAdvertsingStoppedPromise.success()
        }
    }
}

// PeripheralManagerImpl
///////////////////////////////////////////
public class PeripheralManager : NSObject, CBPeripheralManagerDelegate, PeripheralManagerWrappable {
    
    private static var instance : PeripheralManager!
    
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
        return Array(self.configuredServices.values)
    }
    
    public func startAdvertising(advertisementData:[String:AnyObject]) {
        self.cbPeripheralManager.startAdvertising(advertisementData)
    }
    
    public func startAdversting(region:BeaconRegion) {
        self.cbPeripheralManager.startAdvertising(region.peripheralDataWithMeasuredPower(nil))
    }
    
    public func stopAdvertisingWrapped() {
        self.cbPeripheralManager.stopAdvertising()
    }
    
    public func addWrappedService(service:MutableService) {
        self.configuredServices[service.uuid] = service
        self.cbPeripheralManager.addService(service.cbMutableService)
    }
    
    public func removeWrappedService(service:MutableService) {
        let removeCharacteristics = Array(self.configuredCharcteristics.keys).filter{(cbCharacteristic) in
            for bcCharacteristic in service.characteristics {
                let uuid = cbCharacteristic.UUID
                if uuid == bcCharacteristic.uuid {
                    return true
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
        self.instance = self.instance ?? PeripheralManager()
        return self.instance
    }

    public class func sharedInstance(options:[String:AnyObject]) -> PeripheralManager {
        self.instance = self.instance ?? PeripheralManager(options:options)
        return self.instance
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
        self.addConfiguredCharacteristics(service.characteristics)
        return self.impl.addService(self, service:service)
    }
    
    public func addServices(services:[MutableService]) -> Future<Void> {
        for service in services {
            self.addConfiguredCharacteristics(service.characteristics)
        }
        return self.impl.addServices(self, services:services)
    }

    public func removeService(service:MutableService) -> Future<Void> {
        return self.impl.removeService(self, service:service)
    }
    
    public func removeAllServices() -> Future<Void> {
        return self.impl.removeAllServices(self)
    }

    // CBPeripheralManagerDelegate
    public func peripheralManagerDidUpdateState(_:CBPeripheralManager) {
        self.impl.didUpdateState(self)
    }
    
    public func peripheralManager(_:CBPeripheralManager, willRestoreState dict:[String:AnyObject]) {
    }
    
    public func peripheralManagerDidStartAdvertising(_:CBPeripheralManager, error:NSError?) {
        self.impl.didStartAdvertising(error)
    }
    
    public func peripheralManager(_:CBPeripheralManager, didAddService service:CBService, error:NSError?) {
        if error != nil {
            self.configuredServices.removeValueForKey(service.UUID)
        }
        self.impl.didAddService(error)
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
    
    private override init() {
        super.init()
        self.cbPeripheralManager = CBPeripheralManager(delegate:self, queue:PeripheralQueue.queue)
    }

    private init(options:[String:AnyObject]) {
        super.init()
        self.cbPeripheralManager = CBPeripheralManager(delegate:self, queue:PeripheralQueue.queue, options:options)
    }

    private func addConfiguredCharacteristics(characteristics:[MutableCharacteristic]) {
        for characteristic in characteristics {
            self.configuredCharcteristics[characteristic.cbMutableChracteristic] = characteristic
        }
    }
}
