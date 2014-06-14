//
//  Peripheral.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/8/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation
import CoreBluetooth

let PERIPHERAL_CONNECTION_TIMEOUT   : Float = 5.0
let RECONNECT_DELAY                 : Float = 1.0

enum PeripheralConnectionError {
    case None
    case Timeout
}

class Peripheral : NSObject, CBPeripheralDelegate {
    
    var peripheralConnected         : ((peripheral:Peripheral!, error:NSError!) -> ())?
    var peripheralDisconnected      : ((Peripheral:Peripheral!) -> ())?
    var servicesDiscovered          : ((services:Service[]!) -> ())?
    var peripheralDiscovered        : ((peripheral:Peripheral!, error:NSError!) -> ())?
    
    
    let cbPeripheral    : CBPeripheral!
    let advertisement   : NSDictionary!
    
    var discoveredServices  : Dictionary<String, Service> = [:]
    var discoveredObjects   : Dictionary<String, AnyObject> = [:]
    var currentError        : PeripheralConnectionError!
    
    var name : String {
        return cbPeripheral.name
    }
    
    var state : CBPeripheralState {
        return self.cbPeripheral.state
    }
    
    init(cbPeripheral:CBPeripheral, advertisement:NSDictionary) {
        self.cbPeripheral = cbPeripheral
        self.advertisement = advertisement
        self.currentError = .None
    }
    
    // connect
    func connect(peripheralConnected:(peripheral:Peripheral!, error:NSError!)->()) {
        if (self.state != .Connected) {
            self.peripheralConnected = peripheralConnected
            CentralManager.sharedinstance().connectPeripheral(self)
        }
    }
    
    func connect(peripheralConnected:(peripheral:Peripheral!, error:NSError!)->(), perpheralDisconnected:(peripheral:Peripheral!)->()) {
    }

    func connect () {
    }

    func disconnect() {
    }
    
    func timeoutConnection() {
        let central = CentralManager.sharedinstance()
        central.delayCallback(PERIPHERAL_CONNECTION_TIMEOUT) {
            if (self.state != .Connected) {
                self.currentError = PeripheralConnectionError.Timeout
                central.cancelPeripheralConnection(self)
            }
        }
    }
    
    // service discovery
    func discoverAllServices(servicesDiscovered:(services:Service[]!)->()) {
    }
    
    func discoverServices(services:CBUUID[]!, servicesDiscovered:(services:Service[]!)->()) {
    }
    
    func discoverPeripheral(peripheralDiscovered:(peripheral:Peripheral!, error:NSError!)->()) {
    }
    
    // CBPeripheralDelegate Peripheral
    func peripheralDidUpdateName(peripheral:CBPeripheral!) {
    }
    
    func peripheral(peripheral:CBPeripheral!, didModifyServices invalidatedServices:AnyObject[]!) {
    }

    // CBPeripheralDelegate Services
    func peripheral(peripheral:CBPeripheral!, didDiscoverServices error:NSError!) {
    }
    
    func peripheral(peripheral:CBPeripheral!, didDiscoverIncludedServicesForService service:CBService!, error:NSError!) {
    }
    
    // CBPeripheralDelegate Characteristics
    func peripheral(peripheral:CBPeripheral!, didDiscoverCharacteristicsForService service:CBService!, error:NSError!) {
    }
    
    func peripheral(peripheral:CBPeripheral!, didUpdateNotificationStateForCharacteristic characteristic:CBCharacteristic!, error: NSError!) {
    }

    func peripheral(peripheral:CBPeripheral!, didUpdateValueForCharacteristic characteristic:CBCharacteristic!, error:NSError!) {
    }

    func peripheral(peripheral:CBPeripheral!, didWriteValueForCharacteristic characteristic:CBCharacteristic!, error: NSError!) {
    }
    
    // CBPeripheral Delegate Descriptors
    func peripheral(peripheral:CBPeripheral!, didDiscoverDescriptorsForCharacteristic characteristic:CBCharacteristic!, error:NSError!) {
    }
    
    func peripheral(peripheral:CBPeripheral!, didUpdateValueForDescriptor descriptor:CBDescriptor!, error:NSError!) {
    }
    
    func peripheral(peripheral:CBPeripheral!, didWriteValueForDescriptor descriptor:CBDescriptor!, error:NSError!) {
    }
}
