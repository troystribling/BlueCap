//
//  Peripheral.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/8/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation
import CoreBluetooth

let PERIPHERAL_CONNECTION_TIMEOUT   : Float = 10.0

enum PeripheralConnectionError {
    case None
    case Timeout
}

class Peripheral : NSObject, CBPeripheralDelegate {
    
    var servicesDiscovered          : ((services:Service[]) -> ())?
    var peripheralDiscovered        : ((peripheral:Peripheral, error:NSError!) -> ())?

    var connectionSequence = 0
    
    var connectorator   : Connectorator?
    let cbPeripheral    : CBPeripheral!
    let advertisement   : NSDictionary!
    
    var discoveredServices  : Dictionary<String, Service> = [:]
    var discoveredObjects   : Dictionary<String, AnyObject> = [:]
    var currentError        : PeripheralConnectionError
    
    var name : String {
        if let name = cbPeripheral.name {
            return name
        } else {
            return "Unknown"
        }
    }
    
    var state : CBPeripheralState {
        return self.cbPeripheral.state
    }
    
    // APPLICATION INTERFACE
    init(cbPeripheral:CBPeripheral, advertisement:NSDictionary) {
        self.cbPeripheral = cbPeripheral
        self.advertisement = advertisement
        self.currentError = .None
    }
    
    // connect
    func reconnect() {
        if self.state == .Disconnected {
            Logger.debug("Peripheral#reconnect")
            CentralManager.sharedinstance().connectPeripheral(self)
            ++self.connectionSequence
            self.timeoutConnection(self.connectionSequence)
        }
    }
    
    func connect() {
        Logger.debug("Peripheral#connect")
        self.connectorator = nil
        self.reconnect()
    }
    
    func connect(connectorator:Connectorator) {
        Logger.debug("Peripheral#connect")
        self.connectorator = connectorator
        self.reconnect()
    }
    
    func disconnect() {
        if self.state == .Connected {
            Logger.debug("Peripheral#disconnect")
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
    
    // CBPeripheralDelegate
    // peripheral
    func peripheralDidUpdateName(peripheral:CBPeripheral!) {
    }
    
    func peripheral(peripheral:CBPeripheral!, didModifyServices invalidatedServices:AnyObject[]!) {
    }

    // services
    func peripheral(peripheral:CBPeripheral!, didDiscoverServices error:NSError!) {
    }
    
    func peripheral(peripheral:CBPeripheral!, didDiscoverIncludedServicesForService service:CBService!, error:NSError!) {
    }
    
    // characteristics
    func peripheral(peripheral:CBPeripheral!, didDiscoverCharacteristicsForService service:CBService!, error:NSError!) {
    }
    
    func peripheral(peripheral:CBPeripheral!, didUpdateNotificationStateForCharacteristic characteristic:CBCharacteristic!, error: NSError!) {
    }

    func peripheral(peripheral:CBPeripheral!, didUpdateValueForCharacteristic characteristic:CBCharacteristic!, error:NSError!) {
    }

    func peripheral(peripheral:CBPeripheral!, didWriteValueForCharacteristic characteristic:CBCharacteristic!, error: NSError!) {
    }
    
    // descriptors
    func peripheral(peripheral:CBPeripheral!, didDiscoverDescriptorsForCharacteristic characteristic:CBCharacteristic!, error:NSError!) {
    }
    
    func peripheral(peripheral:CBPeripheral!, didUpdateValueForDescriptor descriptor:CBDescriptor!, error:NSError!) {
    }
    
    func peripheral(peripheral:CBPeripheral!, didWriteValueForDescriptor descriptor:CBDescriptor!, error:NSError!) {
    }
    
    // PRIVATE INTERFACE
    func timeoutConnection(sequence:Int) {
        let central = CentralManager.sharedinstance()
        Logger.debug("Periphearl#timeoutConnection: sequence \(sequence)")
        central.delayCallback(PERIPHERAL_CONNECTION_TIMEOUT) {
            if self.state != .Connected && sequence == self.connectionSequence {
                Logger.debug("Periphearl#timeoutConnection: timing out sequence=\(sequence), current connectionSequence=\(self.connectionSequence)")
                self.currentError = .Timeout
                central.cancelPeripheralConnection(self)
            } else {
                Logger.debug("Periphearl#timeoutConnection: expired")
            }
        }
    }
    
    // INTERNAL INTERFACE
    func didDisconnectPeripheral() {
        Logger.debug("Periphearl#didDisconnectPeripheral")
        if let connectorator = self.connectorator {
            switch(self.currentError) {
            case .None:
                    CentralManager.asyncCallback() {
                        Logger.debug("Periphearl#didFailToConnectPeripheral: No errors disconnecting")
                        connectorator.didDisconnect(self)
                    }
            case .Timeout:
                    CentralManager.asyncCallback() {
                        Logger.debug("Periphearl#didFailToConnectPeripheral: Timeout reconnecting")
                        connectorator.didTimeout(self)
                    }
            }
        }
    }

    func didConnectPeripheral() {
        Logger.debug("PeripheralConnectionError#didConnectPeripheral")
        if let connectorator = self.connectorator {
            connectorator.didConnect(self)
        }
    }
    
    func didFailToConnectPeripheral(error:NSError!) {
        Logger.debug("PeripheralConnectionError#didFailToConnectPeripheral")
        if let connectorator = self.connectorator {
            connectorator.didFailConnect(self, error:error)
        }
    }
}
