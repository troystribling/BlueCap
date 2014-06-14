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
    
    var peripheralConnected         : ((peripheral:Peripheral, error:NSError!) -> ())?
    var peripheralDisconnected      : ((peripheral:Peripheral) -> ())?
    var servicesDiscovered          : ((services:Service[]) -> ())?
    var peripheralDiscovered        : ((peripheral:Peripheral, error:NSError!) -> ())?

    var connectionSequence = 0
    
    let cbPeripheral    : CBPeripheral!
    let advertisement   : NSDictionary!
    
    var discoveredServices  : Dictionary<String, Service> = [:]
    var discoveredObjects   : Dictionary<String, AnyObject> = [:]
    var currentError        : PeripheralConnectionError
    
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
    func connect() {
        if self.state != .Connected {
            self.peripheralConnected = nil
            self.reconnect()
        }
    }
    
    func reconnect() {
        if self.state != .Connected {
            CentralManager.sharedinstance().connectPeripheral(self)
            ++self.connectionSequence
            self.timeoutConnection(self.connectionSequence)
        }
    }
    
    func connect(peripheralConnected:((peripheral:Peripheral , error:NSError!)->())) {
        if self.state != .Connected {
            self.peripheralConnected = peripheralConnected
            self.reconnect()
        }
    }
    
    func connect(peripheralConnected:(peripheral:Peripheral!, error:NSError!)->(), peripheralDisconnected:(peripheral:Peripheral)->()) {
        self.peripheralDisconnected = peripheralDisconnected
        self.connect(peripheralConnected)
    }

    func disconnect() {
        if self.state == .Connected {
            self.peripheralDisconnected = nil
            CentralManager.sharedinstance().cancelPeripheralConnection(self)
        }
    }

    func disconnect(peripheralDisconnected:((peripheral:Peripheral)->())) {
        if self.state == .Connected {
            self.peripheralDisconnected = peripheralDisconnected
            CentralManager.sharedinstance().cancelPeripheralConnection(self)
        }
    }
    
    // service discovery
    func discoverAllServices(servicesDiscovered:(services:Service[])->()) {
    }
    
    func discoverServices(services:CBUUID[]!, servicesDiscovered:(services:Service[])->()) {
    }
    
    func discoverPeripheral(peripheralDiscovered:(peripheral:Peripheral!, error:NSError!)->()) {
    }
    
    // CBPeripheralDelegate: peripheral
    func peripheralDidUpdateName(peripheral:CBPeripheral!) {
    }
    
    func peripheral(peripheral:CBPeripheral!, didModifyServices invalidatedServices:AnyObject[]!) {
    }

    // CBPeripheralDelegate: services
    func peripheral(peripheral:CBPeripheral!, didDiscoverServices error:NSError!) {
    }
    
    func peripheral(peripheral:CBPeripheral!, didDiscoverIncludedServicesForService service:CBService!, error:NSError!) {
    }
    
    // CBPeripheralDelegate: characteristics
    func peripheral(peripheral:CBPeripheral!, didDiscoverCharacteristicsForService service:CBService!, error:NSError!) {
    }
    
    func peripheral(peripheral:CBPeripheral!, didUpdateNotificationStateForCharacteristic characteristic:CBCharacteristic!, error: NSError!) {
    }

    func peripheral(peripheral:CBPeripheral!, didUpdateValueForCharacteristic characteristic:CBCharacteristic!, error:NSError!) {
    }

    func peripheral(peripheral:CBPeripheral!, didWriteValueForCharacteristic characteristic:CBCharacteristic!, error: NSError!) {
    }
    
    // CBPeripheralDelegate: descriptors
    func peripheral(peripheral:CBPeripheral!, didDiscoverDescriptorsForCharacteristic characteristic:CBCharacteristic!, error:NSError!) {
    }
    
    func peripheral(peripheral:CBPeripheral!, didUpdateValueForDescriptor descriptor:CBDescriptor!, error:NSError!) {
    }
    
    func peripheral(peripheral:CBPeripheral!, didWriteValueForDescriptor descriptor:CBDescriptor!, error:NSError!) {
    }
    
    // PRIVATE
    func timeoutConnection(sequence:Int) {
        let central = CentralManager.sharedinstance()
        central.delayCallback(PERIPHERAL_CONNECTION_TIMEOUT) {
            if self.state != .Connected && sequence == self.connectionSequence {
                self.currentError = .Timeout
                central.cancelPeripheralConnection(self)
            }
        }
    }
    
    func error() -> NSError! {
        var errorObj : NSError?
        switch(self.currentError) {
        case .Timeout:
            errorObj = NSError(domain: "BlueCap", code: 408, userInfo:[NSLocalizedDescriptionKey:"Connection Timeout"])
        default:
            errorObj = nil
        }
        self.currentError = .None
        return errorObj;
    }
    
    // FRIEND: CentralManager callbacks
    func didDidconnectPeripheral(peripheral:Peripheral) {
        if self.currentError == .None {
            if self.peripheralDisconnected {
                CentralManager.asyncCallback() {
                    self.peripheralDisconnected!(peripheral:self)
                }
            }
        } else {
            if self.peripheralConnected {
                CentralManager.asyncCallback() {
                    self.peripheralConnected!(peripheral:self, error:self.error())
                }
            }
        }
    }

    func didConnectPeripheral(peripheral:Peripheral) {
        if self.peripheralConnected {
            self.peripheralConnected!(peripheral:self, error:nil)
        }
    }
    
    func didFailToConnectPeripheral(peripheral:Peripheral, withError error:NSError!) {
        if self.peripheralConnected {
            self.peripheralConnected!(peripheral:self, error:error)
        }
    }
}
