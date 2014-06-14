//
//  CentralManager.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/4/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation
import CoreBluetooth

class CentralManager : NSObject, CBCentralManagerDelegate {
    
    var afterPowerOn                : (()->())?
    var afterPowerOff               : (()->())?
    var afterPeripheralDiscovered   : ((Peripheral!, Int)->())?
    
    var discoveredPeripherals : Dictionary<CBPeripheral, Peripheral> = [:]
    let cbCentralManager : CBCentralManager!
    
    let mainQueue       = dispatch_queue_create("com.gnos.us.central.main:", DISPATCH_QUEUE_SERIAL)
    let callbackQueue   = dispatch_queue_create("com.gnos.us.central.callback", DISPATCH_QUEUE_SERIAL);
    
    var isScanning  = false
    var connecting  = false
    
    init() {
        super.init()
        self.cbCentralManager = CBCentralManager(delegate:self, queue:self.mainQueue)
    }
    
    // class methods
    class func sharedinstance() -> CentralManager {
        if !thisCentralManager {
            thisCentralManager = CentralManager()
        }
        return thisCentralManager!;
    }
    
    // queues
    class func syncMain(request:()->()) {
        CentralManager.sharedinstance().syncMain(request)
    }

    class func asyncMain(request:()->()) {
        CentralManager.sharedinstance().asyncMain(request)
    }
    
    class func delayMain(delay:Float, request:()->()) {
        CentralManager.sharedinstance().delayMain(delay, request)
    }

    class func syncCallback(request:()->()) {
        CentralManager.sharedinstance().syncCallback(request)
    }
    
    class func asyncCallback(request:()->()) {
        CentralManager.sharedinstance().asyncCallback(request)
    }
    
    class func delayCallback(delay:Float, request:()->()) {
        CentralManager.sharedinstance().delayCallback(delay, request)
    }
    
    func syncMain(request:()->()) {
        dispatch_sync(self.mainQueue, request)
    }

    func asyncMain(request:()->()) {
        dispatch_async(self.mainQueue, request)
    }

    func delayMain(delay:Float, request:()->()) {
        let popTime = dispatch_time(DISPATCH_TIME_NOW, Int64(delay*Float(NSEC_PER_SEC)))
        dispatch_after(popTime, self.mainQueue, request)
    }
    
    func syncCallback(request:()->()) {
        dispatch_sync(self.callbackQueue, request)
    }
    
    func asyncCallback(request:()->()) {
        dispatch_async(self.callbackQueue, request)
    }

    func delayCallback(delay:Float, request:()->()) {
        let popTime = dispatch_time(DISPATCH_TIME_NOW, Int64(delay*Float(NSEC_PER_SEC)))
        dispatch_after(popTime, self.callbackQueue, request)
    }

    // scanning
    func startScanning(afterPeripheralDiscovered:((peripheral:Peripheral!, rssi:Int)->())?) {
        startScanningForServiceUUIDds(nil, afterPeripheralDiscovered)
    }
    
    func startScanningForServiceUUIDds(uuids:CBUUID[]!, afterPeripheralDiscovered:((peripheral:Peripheral!, rssi:Int)->())?) {
        if !self.isScanning {
            Logger.debug("startScanningForServiceUUIDds")
            self.isScanning = true
            self.afterPeripheralDiscovered = afterPeripheralDiscovered
            self.cbCentralManager.scanForPeripheralsWithServices(uuids,options: nil)
        }
    }
    
    func stopScanning() {
        if (self.isScanning) {
            Logger.debug("stopScanning")
            self.isScanning = false
            self.cbCentralManager.stopScan()
        }
    }
    
    // connection
    func disconnectAllPeripherals() {
        Logger.debug("disconnectAllPeripherals")
    }
    
    func connectPeripheral(peripheral:Peripheral) {
        Logger.debug("connectPeripheral")
        self.cbCentralManager.cancelPeripheralConnection(peripheral.cbPeripheral)
    }
    
    func cancelPeripheralConnection(peripheral:Peripheral) {
        Logger.debug("cancelPeripheralConnection")
        self.cbCentralManager.connectPeripheral(peripheral.cbPeripheral, options:nil)
    }
    
    // power up
    func powerOn(afterPowerOnCallback:(()->())?) {
        self.powerOn(afterPowerOnCallback, nil)
    }

    func powerOn(afterPowerOn:(()->())?, afterPowerOff:(()->())?) {
        Logger.debug("powerOn")
        self.afterPowerOn = afterPowerOn
        self.afterPowerOff = afterPowerOff
        if self.poweredOn() && self.afterPowerOn {
            self.asyncMain(self.afterPowerOn!)
        }
    }

    func poweredOn() -> Bool {
        return self.cbCentralManager.state == CBCentralManagerState.PoweredOn
    }
    
    // CBCentralManagerDelegate: peripheral
    func centralManager(central:CBCentralManager!, didConnectPeripheral peripheral:CBPeripheral!) {
        Logger.debug("didConnectPeripheral")
    }
    
    func centralManager(central:CBCentralManager!, didDisconnectPeripheral peripheral:CBPeripheral!, error:NSError!) {
        Logger.debug("didDisconnectPeripheral")
    }
    
    func centralManager(central: CBCentralManager!, didDiscoverPeripheral peripheral:CBPeripheral!, advertisementData:NSDictionary!, RSSI:NSNumber!) {
        let bcPeripheral = Peripheral(cbPeripheral:peripheral, advertisement:advertisementData)
        Logger.debug("didDiscoverPeripheral: \(bcPeripheral.name)")
        self.discoveredPeripherals[peripheral] = bcPeripheral
        if (self.afterPeripheralDiscovered) {
            self.afterPeripheralDiscovered!(bcPeripheral, RSSI.integerValue)
        }
    }
    
    func centralManager(central:CBCentralManager!, didFailToConnectPeripheral peripheral:CBPeripheral!, error:NSError!) {
        Logger.debug("didFailToConnectPeripheral")
    }
    
    func centralManager(central:CBCentralManager!, didRetrieveConnectedPeripherals peripherals:AnyObject[]!) {
        Logger.debug("didRetrieveConnectedPeripherals")
    }
    
    func centralManager(central:CBCentralManager!, didRetrievePeripherals peripherals:AnyObject[]!) {
        Logger.debug("didRetrievePeripherals")
    }
    
    // CBCentralManagerDelegate: centrail manager state
    func centralManager(central: CBCentralManager!, willRestoreState dict:NSDictionary!) {
        Logger.debug("willRestoreState")
    }
    
    func centralManagerDidUpdateState(central:CBCentralManager!) {
        switch(self.cbCentralManager.state) {
        case .Unauthorized:
            Logger.debug("centralManagerDidUpdateState: Unauthorized")
            break
        case .Unknown:
            Logger.debug("centralManagerDidUpdateState: Unknown")
            break
        case .Unsupported:
            Logger.debug("centralManagerDidUpdateState: Unsupported")
            break
        case .Resetting:
            Logger.debug("centralManagerDidUpdateState: Resetting")
            break
        case .PoweredOff:
            Logger.debug("centralManagerDidUpdateState: PoweredOff")
            if (self.afterPowerOff) {
                asyncCallback(self.afterPowerOff!)
            }
            break
        case .PoweredOn:
            Logger.debug("centralManagerDidUpdateState: PoweredOn")
            if (self.afterPowerOn) {
                asyncCallback(self.afterPowerOn!)
            }
            break
        }
    }
}

var thisCentralManager : CentralManager?