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
    private var cbPeripheralManager : CBPeripheralManager!
    
    private var afterAdvertisingStartedSuccessCallback  : (()->())?
    private var afterAdvertisingStartedFailedCallback   : ((error:NSError!)->())?
    private var afterAdvertsingStoppedCallback          : (()->())?
    private var affterPowerOnCallback                   : (()->())?
    private var afterPowerOffCallback                   : (()->())?
    private var afterServiceAddSuccessCallback          : (()->())?
    private var afterServiceAddFailedCallback           : ((error:NSError!)->())?
    private var afterServiceRemovedCallback             : (()->())?
    
    private let peripheralQueue =  dispatch_queue_create("com.gnos.us.peripheral.main", DISPATCH_QUEUE_SERIAL)

    // INTERNAL
    internal var configuredServices : Dictionary<CBUUID, MutableService> = [:]

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
    
    public class func sharedInstance() -> PeripheralManager {
        if thisPeripheralManager == nil {
            thisPeripheralManager = PeripheralManager()
        }
        return thisPeripheralManager!
    }
    
    // power on
    public func powerOn(afterPowerOn:()->(), afterPowerOff:(()->())?) {
    }
    
    // advertising
    public func startAdvertising(name:String, afterAdvertisingStartedSuccess:()->(), afterAdvertisingStartFailed:((error:NSError!)->())? = nil) {
    }

    public func startAdvertising(name:String, afterAdvertisingStartFailed:(()->())? = nil) {
    }
    
    // services
    public func addService(service:MutableService, afterServiceAddedSuccess:()->(), afterServiceAddedFailed:((error:NSError!)->())? = nil) {
    }

    public func addService(service:MutableService, afterServiceAddedFailed:((error:NSError!)->())? = nil) {
    }
    
    public func removeService(service:MutableService, afterServiceRemoved:(()->())? = nil) {
    }
    
    public func removeAllServices(afterServiceRemoved:(()->())? = nil) {
    }

    // CBPeripheralManagerDelegate
    public func peripheralManagerDidUpdateState(_:CBPeripheralManager!) {
    }
    
    public func peripheralManager(_:CBPeripheralManager!, willRestoreState dict: [NSObject : AnyObject]!) {
    }
    
    public func peripheralManagerDidStartAdvertising(_:CBPeripheralManager!, error:NSError!) {
    }
    
    public func peripheralManager(_:CBPeripheralManager!, didAddService service:CBService!, error:NSError!) {
    }
    
    public func peripheralManager(_:CBPeripheralManager!, central:CBCentral!, didSubscribeToCharacteristic characteristic:CBCharacteristic!) {
    }
    
    public func peripheralManager(_:CBPeripheralManager!, central:CBCentral!, didUnsubscribeFromCharacteristic characteristic:CBCharacteristic!) {
    }
    
    public func peripheralManagerIsReadyToUpdateSubscribers(_:CBPeripheralManager!) {
    }
    
    public func peripheralManager(_:CBPeripheralManager!, didReceiveReadRequest request:CBATTRequest!) {
    }
    
    public func peripheralManager(_:CBPeripheralManager!, didReceiveWriteRequests requests:[AnyObject]!) {
        
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
    }
}

var thisPeripheralManager : PeripheralManager?