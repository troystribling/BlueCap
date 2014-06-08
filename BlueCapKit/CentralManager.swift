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
    
    var discoveredPeripherals : Dictionary<CBPeripheral, Peripheral> = [:]
    var centralManager : CBCentralManager!
    
    let mainQueue = dispatch_queue_create("com.gnos.us.central.main:", DISPATCH_QUEUE_SERIAL)
    let callbackQueue = dispatch_queue_create("com.gnos.us.central.callback", DISPATCH_QUEUE_SERIAL);
    
    var isScanning      = false
    var poweredOn       = false
    var connecting      = false
    
    init() {
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
    }
    
    // connection
    func disconnectAllPeripherals() {
    }
    
    // power up
    func powerOn() {
    }
    
    // CBCentralManagerDelegate
    func centralManager(central: CBCentralManager!, didConnectPeripheral peripheral: CBPeripheral!) {
    }
    
    func centralManager(central: CBCentralManager!, didDisconnectPeripheral peripheral: CBPeripheral!, error: NSError!) {
    }
    
    func centralManager(central: CBCentralManager!, didDiscoverPeripheral peripheral: CBPeripheral!, advertisementData: NSDictionary!, RSSI: NSNumber!) {
    }
    
    func centralManager(central: CBCentralManager!, didFailToConnectPeripheral peripheral: CBPeripheral!, error: NSError!) {
    }
    
    func centralManager(central: CBCentralManager!, didRetrieveConnectedPeripherals peripherals: AnyObject[]!) {
    }
    
    func centralManager(central: CBCentralManager!, didRetrievePeripherals peripherals: AnyObject[]!) {
    }
    
    func centralManager(central: CBCentralManager!, willRestoreState dict: NSDictionary!) {
    }
    
    func centralManagerDidUpdateState(central: CBCentralManager!) {
    }
}

var thisCentralManager : CentralManager?