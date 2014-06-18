//
//  Peripheral.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/8/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation
import CoreBluetooth

let PERIPHERAL_CONNECTION_TIMEOUT : Float  = 10.0
let RSSI_UPDATE_PERIOD            : Float  = 1.0

enum PeripheralConnectionError {
    case None
    case Timeout
}

class Peripheral : NSObject, CBPeripheralDelegate {
    
    var servicesDiscovered          : ((services:Service[]) -> ())?
    var peripheralDiscovered        : ((peripheral:Peripheral, error:NSError!) -> ())?
    var rssiUpdate                  : ((rssi:Int) -> ())?

    var connectionSequence = 0
    
    var connectorator   : Connectorator?
    let cbPeripheral    : CBPeripheral!
    let advertisement   : NSDictionary!
    
    var discoveredServices  : Dictionary<String, Service>   = [:]
    var discoveredObjects   : Dictionary<String, AnyObject> = [:]

    var currentError        = PeripheralConnectionError.None
    var forcedDisconnect    = false
    
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
    
    var rssi : Int {
        var rssiInt = -1
        if let rssiNumber = cbPeripheral.RSSI {
            rssiInt = rssiNumber.integerValue
        }
        return rssiInt
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
            self.forcedDisconnect = false
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
            self.forcedDisconnect = true
            Logger.debug("Peripheral#disconnect")
            CentralManager.sharedinstance().cancelPeripheralConnection(self)
        }
    }
    
    // rssi
    func readRSSI(rssiUpdate:(rssi:Int) -> ()) {
        if self.state == .Connected {
            self.rssiUpdate = rssiUpdate
            self.cbPeripheral.readRSSI()
        }
    }
    
    func pollRSSI(rssiUpdate:(rssi:Int) -> ()) {
        if self.state == .Connected {
            self.rssiUpdate = rssiUpdate
            CentralManager.sharedinstance().delayCallback(RSSI_UPDATE_PERIOD) {
                if let rssiUpdate = self.rssiUpdate {
                    self.readRSSI(rssiUpdate)
                    self.pollRSSI(rssiUpdate)
                }
            }
        }
    }
    
    func stopPollingRSSI() {
        self.rssiUpdate = nil
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
    func peripheralDidUpdateName(_:CBPeripheral!) {
    }
    
    func peripheral(_:CBPeripheral!, didModifyServices invalidatedServices:AnyObject[]!) {
    }
    
    func peripheralDidUpdateRSSI(_:CBPeripheral!, error: NSError!) {
        if let rssiUpdate = self.rssiUpdate {
            CentralManager.sharedinstance().asyncCallback(){rssiUpdate(rssi:self.rssi)}
        }
    }
    
    // services
    func peripheral(_:CBPeripheral!, didDiscoverServices error:NSError!) {
    }
    
    func peripheral(_:CBPeripheral!, didDiscoverIncludedServicesForService service:CBService!, error:NSError!) {
    }
    
    // characteristics
    func peripheral(_:CBPeripheral!, didDiscoverCharacteristicsForService service:CBService!, error:NSError!) {
    }
    
    func peripheral(_:CBPeripheral!, didUpdateNotificationStateForCharacteristic characteristic:CBCharacteristic!, error: NSError!) {
    }

    func peripheral(_:CBPeripheral!, didUpdateValueForCharacteristic characteristic:CBCharacteristic!, error:NSError!) {
    }

    func peripheral(_:CBPeripheral!, didWriteValueForCharacteristic characteristic:CBCharacteristic!, error: NSError!) {
    }
    
    // descriptors
    func peripheral(_:CBPeripheral!, didDiscoverDescriptorsForCharacteristic characteristic:CBCharacteristic!, error:NSError!) {
    }
    
    func peripheral(_:CBPeripheral!, didUpdateValueForDescriptor descriptor:CBDescriptor!, error:NSError!) {
    }
    
    func peripheral(_:CBPeripheral!, didWriteValueForDescriptor descriptor:CBDescriptor!, error:NSError!) {
    }
    
    // PRIVATE INTERFACE
    func timeoutConnection(sequence:Int) {
        let central = CentralManager.sharedinstance()
        Logger.debug("Periphearl#timeoutConnection: sequence \(sequence)")
        central.delayCallback(PERIPHERAL_CONNECTION_TIMEOUT) {
            if self.state != .Connected && sequence == self.connectionSequence && !self.forcedDisconnect {
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
            if (self.forcedDisconnect) {
                CentralManager.asyncCallback() {
                    Logger.debug("Periphearl#didFailToConnectPeripheral: forced disconnect")
                    connectorator.didForceDisconnect(self)
                }
            } else {
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
