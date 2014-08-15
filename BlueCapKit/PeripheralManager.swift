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
    
    private let peripheralQueue =  dispatch_queue_create("com.gnos.us.peripheral.main", DISPATCH_QUEUE_SERIAL)
    private var _isPoweredOn    = false
    private var _name           = "BlueCapPeripheral"

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
        return Array(self.configuredServices.values)
    }
    
    public var name : String {
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
    
    // power on
    public func powerOn(afterPowerOn:()->(), afterPowerOff:(()->())?) {
        self.afterPowerOnCallback = afterPowerOn
        self.afterPowerOffCallback = afterPowerOff
        if self._isPoweredOn && self.afterPowerOnCallback != nil {
            self.asyncCallback(self.afterPowerOnCallback!)
        }
    }
    
    // advertising
    public func startAdvertising(name:String, afterAdvertisingStartedSuccess:()->(), afterAdvertisingStartFailed:((error:NSError!)->())? = nil) {
        self._name = name
        self.afterAdvertisingStartedSuccessCallback = afterAdvertisingStartedSuccess
        self.afterAdvertisingStartedFailedCallback = afterAdvertisingStartFailed
        self.cbPeripheralManager.startAdvertising([CBAdvertisementDataLocalNameKey:name, CBAdvertisementDataServiceUUIDsKey:Array(self.configuredServices.keys)])
    }

    public func startAdvertising(name:String, afterAdvertisingStartFailed:((error:NSError!)->())? = nil) {
        self._name = name
        self.afterAdvertisingStartedSuccessCallback = nil
        self.afterAdvertisingStartedFailedCallback = afterAdvertisingStartFailed
        self.cbPeripheralManager.startAdvertising([CBAdvertisementDataLocalNameKey:name, CBAdvertisementDataServiceUUIDsKey:Array(self.configuredServices.keys)])
    }
    
    public func stopAdvertising(afterAdvertisingStopped:(()->())? = nil) {
        self.afterAdvertsingStoppedCallback = afterAdvertisingStopped
        self.cbPeripheralManager.stopAdvertising()
        self.lookForAdvertisingToStop()
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
    
    public func removeService(service:MutableService, afterServiceRemoved:(()->())? = nil) {
        if !self.isAdvertising {
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
            self.configuredServices.removeAll(keepCapacity:false)
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
            if let afterAdvertisingStartedSuccessCallback = self.afterAdvertsingStoppedCallback {
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
        if let service = self.configuredServices[service.UUID] {
            if error == nil {
                Logger.debug("PeripheralManager#didAddService: Success")
                if let  afterServiceAddSuccessCallback = self.afterServiceAddSuccessCallback {
                    self.asyncCallback(afterServiceAddSuccessCallback)
                }
            } else {
                Logger.debug("PeripheralManager#didAddService: Failed '\(error.localizedDescription)'")
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
            dispatch_after(popTime, dispatch_get_main_queue(), {
                self.lookForAdvertisingToStop()
            })
        } else {
            Logger.debug("Peripheral#lookForAdvertisingToStop: Advertising stopped")
            self.asyncCallback(self.afterAdvertsingStoppedCallback!)
        }
    }
}

var thisPeripheralManager : PeripheralManager?