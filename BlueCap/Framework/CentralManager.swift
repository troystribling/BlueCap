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
