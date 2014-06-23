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
    
    var servicesDiscoveredCallback          : ((services:Service[]) -> ())?
    var peripheralDiscoveredCallback        : ((error:NSError!) -> ())?

    var connectionSequence = 0
    
    var connectorator   : Connectorator?
    let cbPeripheral    : CBPeripheral!
    let advertisements  : Dictionary<String, String>!
    let rssi            : Int!
    
    var discoveredServices  = Dictionary<CBUUID, Service>()

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
    
    var uuidString : String {
        if let identifier = self.cbPeripheral.identifier {
            return self.cbPeripheral.identifier.UUIDString
        } else {
            return "Unknown"
        }
    }
    
    var services : Service[] {
        return Array(self.discoveredServices.values)
    }
    
    // APPLICATION INTERFACE
    init(cbPeripheral:CBPeripheral, advertisements:Dictionary<String, String>, rssi:Int) {
        self.cbPeripheral = cbPeripheral
        self.advertisements = advertisements
        self.currentError = .None
        self.rssi = rssi
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
    
    // service discovery
    func discoverAllServices(servicesDiscoveredCallback:(services:Service[])->()) {
        Logger.debug("Peripheral#discoverAllServices")
        self.servicesDiscoveredCallback = servicesDiscoveredCallback
        self.cbPeripheral.discoverServices(nil)
    }
    
    func discoverServices(services:CBUUID[]!, servicesDiscoveredCallback:(services:Service[])->()) {
        Logger.debug("Peripheral#discoverAllServices")
        self.servicesDiscoveredCallback = servicesDiscoveredCallback
        self.cbPeripheral.discoverServices(services)
    }
    
    func discoverPeripheral(peripheralDiscovered:(error:NSError!)->()) {
    }
    
    // CBPeripheralDelegate
    // peripheral
    func peripheralDidUpdateName(_:CBPeripheral!) {
        Logger.debug("Peripheral#peripheralDidUpdateName")
    }
    
    func peripheral(_:CBPeripheral!, didModifyServices invalidatedServices:AnyObject[]!) {
        Logger.debug("Peripheral#didModifyServices")
    }
    
    // services
    func peripheral(peripheral:CBPeripheral!, didDiscoverServices error:NSError!) {
        self.discoveredServices.removeAll()
        for cbService : AnyObject in peripheral.services {
            let bcService = Service(cbService:cbService as CBService, peripheral:self)
            self.discoveredServices[bcService.uuid] = bcService
            Logger.debug("Peripheral#didDiscoverServices: uuid=\(bcService.uuid.UUIDString), name=\(bcService.name)")
        }
        if let servicesDiscoveredCallback = self.servicesDiscoveredCallback {
            CentralManager.asyncCallback(){servicesDiscoveredCallback(services:self.services)}
        }
    }
    
    func peripheral(_:CBPeripheral!, didDiscoverIncludedServicesForService service:CBService!, error:NSError!) {
        Logger.debug("Peripheral#didDiscoverIncludedServicesForService")
    }
    
    // characteristics
    func peripheral(_:CBPeripheral!, didDiscoverCharacteristicsForService service:CBService!, error:NSError!) {
        Logger.debug("Peripheral#didDiscoverCharacteristicsForService")
        if let bcService = self.discoveredServices[service.UUID] {
            bcService.didDiscoverCharacteristics()
        }
    }
    
    func peripheral(_:CBPeripheral!, didUpdateNotificationStateForCharacteristic characteristic:CBCharacteristic!, error: NSError!) {
        Logger.debug("Peripheral#didUpdateNotificationStateForCharacteristic")
    }

    func peripheral(_:CBPeripheral!, didUpdateValueForCharacteristic characteristic:CBCharacteristic!, error:NSError!) {
        Logger.debug("Peripheral#didUpdateValueForCharacteristic")
    }

    func peripheral(_:CBPeripheral!, didWriteValueForCharacteristic characteristic:CBCharacteristic!, error: NSError!) {
        Logger.debug("Peripheral#didWriteValueForCharacteristic")
    }
    
    // descriptors
    func peripheral(_:CBPeripheral!, didDiscoverDescriptorsForCharacteristic characteristic:CBCharacteristic!, error:NSError!) {
        Logger.debug("Peripheral#didDiscoverDescriptorsForCharacteristic")
    }
    
    func peripheral(_:CBPeripheral!, didUpdateValueForDescriptor descriptor:CBDescriptor!, error:NSError!) {
        Logger.debug("Peripheral#didUpdateValueForDescriptor")
    }
    
    func peripheral(_:CBPeripheral!, didWriteValueForDescriptor descriptor:CBDescriptor!, error:NSError!) {
        Logger.debug("Peripheral#didWriteValueForDescriptor")
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
                    CentralManager.sharedinstance().discoveredPeripherals.removeAll(keepCapacity:false)
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
