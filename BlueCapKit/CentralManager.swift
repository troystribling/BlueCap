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
    
    var afterPowerOnCallback : (()->())?
    var afterPowerOffCallback : (()->())?
    var afterPeripheralDiscoveredCallback : ((peripheral:Peripheral!, rssi:Int)->())?
    
    var discoveredPeripherals : Dictionary<CBPeripheral, Peripheral> = [:]

    let centralManager : CBCentralManager!
    
    let mainQueue = dispatch_queue_create("com.gnos.us.central.main:", DISPATCH_QUEUE_SERIAL)
    let callbackQueue = dispatch_queue_create("com.gnos.us.central.callback", DISPATCH_QUEUE_SERIAL);
    
    var isScanning  = false
    var connecting  = false
    
    init() {
        super.init()
        self.centralManager = CBCentralManager(delegate:self, queue:self.mainQueue)
    }
    
    // class methods
    class func sharedinstance() -> CentralManager {
        if (!thisCentralManager) {
            thisCentralManager = CentralManager()
        }
        return thisCentralManager!;
    }
    
    // queues

    // scanning
    func startScanning() {
        startScanningForServiceUUIDds(nil)
    }
    
    func startScanningForServiceUUIDds(uuids:Array<CBUUID>!) {
        if (!self.isScanning) {
            Logger.debug("startScanningForServiceUUIDds")
            self.isScanning = true
            self.centralManager.scanForPeripheralsWithServices(uuids,options: nil)
        }
    }
    
    func stopScanning() {
        if (self.isScanning) {
            Logger.debug("stopScanning")
            self.isScanning = false
            self.centralManager.stopScan()
        }
    }
    
    // connection
    func disconnectAllPeripherals() {
        Logger.debug("disconnectAllPeripherals")
    }
    
    // power up
    func powerOn(afterPowerOnCallback:(()->())?) {
        self.afterPowerOnCallback = afterPowerOnCallback
        Logger.debug("powerOn")
    }

    func powerOn(afterPowerOnCallback:(()->())?, afterPowerOff:(()->())?) {
        Logger.debug("powerOn")
    }
    
    // CBCentralManagerDelegate
    func centralManager(central: CBCentralManager!, didConnectPeripheral peripheral: CBPeripheral!) {
        Logger.debug("didConnectPeripheral")
    }
    
    func centralManager(central: CBCentralManager!, didDisconnectPeripheral peripheral: CBPeripheral!, error: NSError!) {
        Logger.debug("didDisconnectPeripheral")
    }
    
    func centralManager(central: CBCentralManager!, didDiscoverPeripheral peripheral: CBPeripheral!, advertisementData: NSDictionary!, RSSI: NSNumber!) {
        Logger.debug("didDiscoverPeripheral")
    }
    
    func centralManager(central: CBCentralManager!, didFailToConnectPeripheral peripheral: CBPeripheral!, error: NSError!) {
        Logger.debug("didFailToConnectPeripheral")
    }
    
    func centralManager(central: CBCentralManager!, didRetrieveConnectedPeripherals peripherals: AnyObject[]!) {
        Logger.debug("didRetrieveConnectedPeripherals")
    }
    
    func centralManager(central: CBCentralManager!, didRetrievePeripherals peripherals: AnyObject[]!) {
        Logger.debug("didRetrievePeripherals")
    }
    
    func centralManager(central: CBCentralManager!, willRestoreState dict: NSDictionary!) {
        Logger.debug("willRestoreState")
    }
    
    func centralManagerDidUpdateState(central: CBCentralManager!) {
        switch(self.centralManager.state) {
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
            break
        case .PoweredOn:
            Logger.debug("centralManagerDidUpdateState: PoweredOn")
            break
        }
    }
}

var thisCentralManager : CentralManager?