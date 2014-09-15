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
    
    // PRIVATE
    private let WAIT_FOR_ADVERTISING_TO_STOP_POLLING_INTERVAL : Float = 0.25
    
    private var afterAdvertisingStartedSuccessCallback  : (()->())?
    private var afterAdvertisingStartedFailedCallback   : ((error:NSError!)->())?
    private var afterAdvertsingStoppedCallback          : (()->())?
    private var afterPowerOnCallback                    : (()->())?
    private var afterPowerOffCallback                   : (()->())?
    private var afterServiceAddSuccessCallback          : (()->())?
    private var afterServiceAddFailedCallback           : ((error:NSError!)->())?
    
    private let peripheralQueue = dispatch_queue_create("com.gnos.us.peripheral.main", DISPATCH_QUEUE_SERIAL)
    
    private var _name : String?

    private var _isPoweredOn    = false
    private var serviceAdded    = false

    // INTERNAL
    internal var cbPeripheralManager        : CBPeripheralManager!
    internal var configuredServices         : Dictionary<CBUUID, MutableService>                    = [:]
    internal var configuredCharcteristics   : Dictionary<CBCharacteristic, MutableCharacteristic>   = [:]

    // PUBLIC
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

    public class func sharedInstance() -> PeripheralManager {
        if thisPeripheralManager == nil {
            thisPeripheralManager = PeripheralManager()
        }
        return thisPeripheralManager!
    }
    
    public func service(uuid:CBUUID) -> MutableService? {
        return self.configuredServices[uuid]
    }
    
    // power on
    public func powerOn(afterPowerOn:()->(), afterPowerOff:(()->())?) {
        self.afterPowerOnCallback = afterPowerOn
        self.afterPowerOffCallback = afterPowerOff
        if self._isPoweredOn && self.afterPowerOnCallback != nil {
            self.asyncCallback(self.afterPowerOnCallback!)
        }
    }
    
    // advertising
    public func startAdvertising(name:String, uuids:[CBUUID]?, afterAdvertisingStartedSuccess:(()->())? = nil, afterAdvertisingStartFailed:((error:NSError!)->())? = nil) {
        self._name = name
        self.afterAdvertisingStartedSuccessCallback = afterAdvertisingStartedSuccess
        self.afterAdvertisingStartedFailedCallback = afterAdvertisingStartFailed
        var advertisementData : [NSObject:AnyObject] = [CBAdvertisementDataLocalNameKey:name]
        if let uuids = uuids {
            advertisementData[CBAdvertisementDataServiceUUIDsKey] = uuids
        }
        self.cbPeripheralManager.startAdvertising(advertisementData)
    }
    
    public func startAdvertising(name:String, uuids:[CBUUID], afterAdvertisingStartFailed:((error:NSError!)->())? = nil) {
        self.startAdvertising(name, uuids:uuids, afterAdvertisingStartedSuccess:nil, afterAdvertisingStartFailed:afterAdvertisingStartFailed)
    }

    public func startAdvertising(name:String, afterAdvertisingStartedSuccess:(()->())? = nil, afterAdvertisingStartFailed:((error:NSError!)->())? = nil) {
        self.startAdvertising(name, uuids:nil, afterAdvertisingStartedSuccess:afterAdvertisingStartedSuccess, afterAdvertisingStartFailed:afterAdvertisingStartFailed)
    }

    public func startAdvertising(name:String, afterAdvertisingStartFailed:((error:NSError!)->())? = nil) {
        self.startAdvertising(name, uuids:nil, afterAdvertisingStartedSuccess:nil, afterAdvertisingStartFailed:afterAdvertisingStartFailed)
    }
    
    public func stopAdvertising(afterAdvertisingStopped:(()->())? = nil) {
        self._name = nil
        self.afterAdvertisingStartedSuccessCallback = nil
        self.afterAdvertisingStartedFailedCallback = nil
        self.afterAdvertsingStoppedCallback = afterAdvertisingStopped
        self.cbPeripheralManager.stopAdvertising()
        dispatch_async(self.peripheralQueue, {self.lookForAdvertisingToStop()})
    }
    
    // services
    public func addService(service:MutableService, afterServiceAddSuccess:()->(), afterServiceAddFailed:((error:NSError!)->())? = nil) {
        if !self.isAdvertising {
            self.afterServiceAddSuccessCallback = afterServiceAddSuccess
            self.afterServiceAddFailedCallback = afterServiceAddFailed
            self.configuredServices[service.uuid] = service
            self.cbPeripheralManager.addService(service.cbMutableService)
        } else {
            NSException(name:"Add service failed", reason: "Peripheral is advertising", userInfo: nil).raise()
        }
    }

    public func addService(service:MutableService, afterServiceAddFailed:((error:NSError!)->())? = nil) {
        if !self.isAdvertising {
            self.afterServiceAddSuccessCallback = nil
            self.afterServiceAddFailedCallback = afterServiceAddFailed
            self.configuredServices[service.uuid] = service
            self.cbPeripheralManager.addService(service.cbMutableService)
        } else {
            NSException(name:"Add service failed", reason: "Peripheral is advertising", userInfo: nil).raise()
        }
    }
    
    public func addServices(services:[MutableService], afterServiceAddSuccess:()->(), afterServiceAddFailed:((error:NSError!)->())? = nil) {
        if services.count > 0 {
            Logger.debug("PeripheralManager#addServices: service count \(services.count)")
            self.addService(services[0], afterServiceAddSuccess:{
                    if services.count > 1 {
                        let servicesTail = Array(services[1...services.count-1])
                        Logger.debug("PeripheralManager#addServices: services remaining \(servicesTail.count)")
                        self.addServices(servicesTail, afterServiceAddSuccess:afterServiceAddSuccess, afterServiceAddFailed:afterServiceAddFailed)
                    } else {
                        Logger.debug("PeripheralManager#addServices: completed")
                        self.asyncCallback(afterServiceAddSuccess)
                    }
                }, afterServiceAddFailed:{(error) in
                    self.removeAllServices() {
                        Logger.debug("PeripheralManager#addServices: failed '\(error.localizedDescription)'")
                        if let afterServiceAddFailed = afterServiceAddFailed {
                            self.asyncCallback(){afterServiceAddFailed(error:error)}
                        }
                    }
                })
        } else {
            self.asyncCallback(afterServiceAddSuccess)
        }
    }

    public func addServices(services:[MutableService], afterServiceAddFailed:((error:NSError!)->())? = nil) {
        if services.count > 0 {
            Logger.debug("PeripheralManager#addServices: service count \(services.count)")
            self.addService(services[0], afterServiceAddSuccess:{
                    if services.count > 1 {
                        let servicesTail = Array(services[1...services.count-1])
                        Logger.debug("PeripheralManager#addServices: services remaining \(servicesTail.count)")
                        self.addServices(servicesTail, afterServiceAddFailed:afterServiceAddFailed)
                    } else {
                        Logger.debug("PeripheralManager#addServices: completed")
                    }
                }, afterServiceAddFailed:{(error) in
                    self.removeAllServices() {
                        Logger.debug("PeripheralManager#addServices: failed '\(error.localizedDescription)'")
                        if let afterServiceAddFailed = afterServiceAddFailed {
                            self.asyncCallback(){afterServiceAddFailed(error:error)}
                        }
                    }
                })
        }
    }

    public func removeService(service:MutableService, afterServiceRemoved:(()->())? = nil) {
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
            if let afterServiceRemoved = afterServiceRemoved {
                self.asyncCallback(afterServiceRemoved)
            }
        } else {
            NSException(name:"Remove service failed", reason: "Peripheral is advertising", userInfo: nil).raise()
        }
    }
    
    public func removeAllServices(afterServiceRemoved:(()->())? = nil) {
        if !self.isAdvertising {
            Logger.debug("PeripheralManager#removeAllServices")
            self.configuredServices.removeAll(keepCapacity:false)
            self.configuredCharcteristics.removeAll(keepCapacity:false)
            self.cbPeripheralManager.removeAllServices()
            if let afterServiceRemoved = afterServiceRemoved {
                self.asyncCallback(afterServiceRemoved)
            }
        } else {
            NSException(name:"Remove all services failed", reason: "Peripheral is advertising", userInfo: nil).raise()
        }
    }

    // CBPeripheralManagerDelegate
    public func peripheralManagerDidUpdateState(_:CBPeripheralManager!) {
        switch self.state {
        case CBPeripheralManagerState.PoweredOn:
            Logger.debug("PeripheralManager#peripheralManagerDidUpdateState: poweredOn")
            self._isPoweredOn = true
            if let afterPowerOnCallback = self.afterPowerOnCallback {
                self.asyncCallback(afterPowerOnCallback)
            }
            break
        case CBPeripheralManagerState.PoweredOff:
            Logger.debug("PeripheralManager#peripheralManagerDidUpdateState: poweredOff")
            self._isPoweredOn = false
            if let afterPowerOffCallback = self.afterPowerOffCallback {
                self.asyncCallback(afterPowerOffCallback)
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
    
    public func peripheralManager(_:CBPeripheralManager!, willRestoreState dict: [NSObject : AnyObject]!) {
    }
    
    public func peripheralManagerDidStartAdvertising(_:CBPeripheralManager!, error:NSError!) {
        if error == nil {
            Logger.debug("PeripheralManager#peripheralManagerDidStartAdvertising: Success")
            if let afterAdvertisingStartedSuccessCallback = self.afterAdvertisingStartedSuccessCallback {
                self.asyncCallback(afterAdvertisingStartedSuccessCallback)
            }
        } else {
            Logger.debug("PeripheralManager#peripheralManagerDidStartAdvertising: Failed '\(error.localizedDescription)'")
            if let afterAdvertisingStartedFailedCallback = self.afterAdvertisingStartedFailedCallback {
                self.asyncCallback(){afterAdvertisingStartedFailedCallback(error:error)}
            }
        }
    }
    
    public func peripheralManager(_:CBPeripheralManager!, didAddService service:CBService!, error:NSError!) {
        if let bcService = self.configuredServices[service.UUID] {
            self.serviceAdded = true
            if error == nil {
                Logger.debug("PeripheralManager#didAddService: Success")
                if let  afterServiceAddSuccessCallback = self.afterServiceAddSuccessCallback {
                    self.asyncCallback(afterServiceAddSuccessCallback)
                }
            } else {
                Logger.debug("PeripheralManager#didAddService: Failed '\(error.localizedDescription)'")
                self.configuredServices.removeValueForKey(service.UUID)
                if let afterServiceAddFailedCallback = self.afterServiceAddFailedCallback {
                    self.asyncCallback(){afterServiceAddFailedCallback(error:error)}
                }
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
            Logger.debug("Responding with data: \(characteristic.stringValues)")
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
                    if let processWriteCallback = characteristic.processWriteRequestCallback {
                        self.asyncCallback(processWriteCallback)
                    }
                } else {
                    Logger.debug("Error: characteristic \(cbattRequest.characteristic.UUID.UUIDString) not found")
                }
            } else {
                Logger.debug("Error: request cast failed")
            }
        }
    }
    
    // INTERNAL INTERFACE
    internal class func syncCallback(request:()->()) {
        PeripheralManager.sharedInstance().syncCallback(request)
    }
    
    internal class func asyncCallback(request:()->()) {
        PeripheralManager.sharedInstance().asyncCallback(request)
    }
    
    internal class func delayCallback(delay:Float, request:()->()) {
        PeripheralManager.sharedInstance().delayCallback(delay, request)
    }
    
    internal func syncCallback(request:()->()) {
        dispatch_sync(dispatch_get_main_queue(), request)
    }
    
    internal func asyncCallback(request:()->()) {
        dispatch_async(dispatch_get_main_queue(), request)
    }
    
    internal func delayCallback(delay:Float, request:()->()) {
        let popTime = dispatch_time(DISPATCH_TIME_NOW, Int64(delay*Float(NSEC_PER_SEC)))
        dispatch_after(popTime, dispatch_get_main_queue(), request)
    }
    
    // PRIVATE
    private override init() {
        super.init()
        self.cbPeripheralManager = CBPeripheralManager(delegate:self, queue:self.peripheralQueue)
    }
    
    private func lookForAdvertisingToStop() {
        if self.isAdvertising && self.afterAdvertsingStoppedCallback != nil {
            let popTime = dispatch_time(DISPATCH_TIME_NOW, Int64(WAIT_FOR_ADVERTISING_TO_STOP_POLLING_INTERVAL * Float(NSEC_PER_SEC)))
            dispatch_after(popTime, self.peripheralQueue, {
                self.lookForAdvertisingToStop()
            })
        } else {
            Logger.debug("Peripheral#lookForAdvertisingToStop: Advertising stopped")
            self.asyncCallback(self.afterAdvertsingStoppedCallback!)
        }
    }    
}

var thisPeripheralManager : PeripheralManager?