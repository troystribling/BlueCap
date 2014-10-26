//
//  Peripheral.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/8/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation
import CoreBluetooth

enum PeripheralConnectionError {
    case None
    case Timeout
}

public class Peripheral : NSObject, CBPeripheralDelegate {

    // PRIVATE
    private var servicesDiscoveredSuccessCallback   : (() -> ())?
    private var serviceDiscoveryFailedCallback      : ((error:NSError!) -> ())?
    
    private var connectionSequence          = 0
    private var discoveredServices          = Dictionary<CBUUID, Service>()
    private var discoveredCharacteristics   = Dictionary<CBCharacteristic, Characteristic>()
    private var currentError                = PeripheralConnectionError.None
    private var forcedDisconnect            = false
    
    private let defaultConnectionTimeout    = Double(10.0)

    // INTERNAL
    internal let cbPeripheral    : CBPeripheral!
    internal var connectorator   : Connectorator?

    // PUBLIC
    public let advertisements  : Dictionary<String, String>!
    public let rssi            : Int!

    public var name : String {
        if let name = cbPeripheral.name {
            return name
        } else {
            return "Unknown"
        }
    }
    
    public var state : CBPeripheralState {
        return self.cbPeripheral.state
    }
    
    public var identifier : NSUUID! {
        return self.cbPeripheral.identifier
    }
    
    public var services : [Service] {
        return self.discoveredServices.values.array
    }
    
    public init(cbPeripheral:CBPeripheral, advertisements:Dictionary<String, String>, rssi:Int) {
        super.init()
        self.cbPeripheral = cbPeripheral
        self.cbPeripheral.delegate = self
        self.advertisements = advertisements
        self.currentError = .None
        self.rssi = rssi
    }
    
    // connect
    public func reconnect() {
        if self.state == .Disconnected {
            Logger.debug("Peripheral#reconnect: \(self.name)")
            CentralManager.sharedInstance().connectPeripheral(self)
            self.forcedDisconnect = false
            ++self.connectionSequence
            self.timeoutConnection(self.connectionSequence)
        }
    }
     
    public func connect(connectorator:Connectorator?=nil) {
        Logger.debug("Peripheral#connect: \(self.name)")
        self.connectorator = connectorator
        self.reconnect()
    }
    
    public func disconnect() {
        self.forcedDisconnect = true
        CentralManager.sharedInstance().discoveredPeripherals.removeValueForKey(self.cbPeripheral)
        if self.state == .Connected {
            Logger.debug("Peripheral#disconnect: \(self.name)")
            CentralManager.sharedInstance().cancelPeripheralConnection(self)
        } else {
            self.didDisconnectPeripheral()
        }
    }
    
    public func terminate() {
        self.disconnect()
    }

    
    // service discovery
    public func discoverAllServices(servicesDiscoveredSuccessCallback:()->(), serviceDiscoveryFailedCallback:((error:NSError!) -> ())? = nil) {
        Logger.debug("Peripheral#discoverAllServices: \(self.name)")
        self.servicesDiscoveredSuccessCallback = servicesDiscoveredSuccessCallback
        self.serviceDiscoveryFailedCallback = serviceDiscoveryFailedCallback
        self.discoverIfConnected(nil)
    }

    public func discoverServices(services:[CBUUID]!, servicesDiscoveredSuccessCallback:()->(), serviceDiscoveryFailedCallback:((error:NSError!) -> ())? = nil) {
        Logger.debug("Peripheral#discoverAllServices: \(self.name)")
        self.servicesDiscoveredSuccessCallback = servicesDiscoveredSuccessCallback
        self.serviceDiscoveryFailedCallback = serviceDiscoveryFailedCallback
        self.discoverIfConnected(services)
    }

    public func discoverPeripheral(peripheralDiscoveredCallback:()->(), peripheralDiscoveryFailedCallback:((error:NSError!)->())? = nil) {
        Logger.debug("Peripheral#discoverPeripheral: \(self.name)")
        self.discoverAllServices({
                if self.services.count > 1 {
                    self.discoverService(self.services[0], tail:Array(self.services[1..<self.services.count]),
                        peripheralDiscoveredCallback:peripheralDiscoveredCallback,
                        peripheralDiscoveryFailedCallback:peripheralDiscoveryFailedCallback)
                } else {
                    self.services[0].discoverAllCharacteristics(peripheralDiscoveredCallback, characteristicDiscoveryFailedCallback:peripheralDiscoveryFailedCallback)
                }
            }, serviceDiscoveryFailedCallback:{(error) in
                if let peripheralDiscoveryFailedCallback = peripheralDiscoveryFailedCallback {
                    CentralManager.asyncCallback(){peripheralDiscoveryFailedCallback(error:error)}
                }
            })
    }
    
    // CBPeripheralDelegate
    // peripheral
    public func peripheralDidUpdateName(_:CBPeripheral!) {
        Logger.debug("Peripheral#peripheralDidUpdateName")
    }
    
    public func peripheral(_:CBPeripheral!, didModifyServices invalidatedServices:[AnyObject]!) {
        Logger.debug("Peripheral#didModifyServices")
    }
    
    // services
    public func peripheral(peripheral:CBPeripheral!, didDiscoverServices error:NSError!) {
        Logger.debug("Peripheral#didDiscoverServices: \(self.name)")
        self.clearAll()
        if let cbServices = peripheral.services {
            for cbService : AnyObject in cbServices {
                let bcService = Service(cbService:cbService as CBService, peripheral:self)
                self.discoveredServices[bcService.uuid] = bcService
                Logger.debug("Peripheral#didDiscoverServices: uuid=\(bcService.uuid.UUIDString), name=\(bcService.name)")
            }
            if let servicesDiscoveredSuccessCallback = self.servicesDiscoveredSuccessCallback {
                CentralManager.asyncCallback(servicesDiscoveredSuccessCallback)
            }
        }
    }
    
    public func peripheral(_:CBPeripheral!, didDiscoverIncludedServicesForService service:CBService!, error:NSError!) {
        Logger.debug("Peripheral#didDiscoverIncludedServicesForService: \(self.name)")
    }
    
    // characteristics
    public func peripheral(_:CBPeripheral!, didDiscoverCharacteristicsForService service:CBService!, error:NSError!) {
        Logger.debug("Peripheral#didDiscoverCharacteristicsForService: \(self.name)")
        if let service = service {
            if let bcService = self.discoveredServices[service.UUID] {
                if let cbCharacteristic = service.characteristics {
                    bcService.didDiscoverCharacteristics()
                    for characteristic : AnyObject in cbCharacteristic {
                        let cbCharacteristic = characteristic as CBCharacteristic
                        self.discoveredCharacteristics[cbCharacteristic] = bcService.discoveredCharacteristics[characteristic.UUID]
                    }
                }
            }
        }
    }
    
    public func peripheral(_:CBPeripheral!, didUpdateNotificationStateForCharacteristic characteristic:CBCharacteristic!, error:NSError!) {
        Logger.debug("Peripheral#didUpdateNotificationStateForCharacteristic")
        if let characteristic = characteristic {
            if let bcCharacteristic = self.discoveredCharacteristics[characteristic] {
                Logger.debug("Peripheral#didUpdateNotificationStateForCharacteristic: uuid=\(bcCharacteristic.uuid.UUIDString), name=\(bcCharacteristic.name)")
                bcCharacteristic.didUpdateNotificationState(error)
            }
        }
    }

    public func peripheral(_:CBPeripheral!, didUpdateValueForCharacteristic characteristic:CBCharacteristic!, error:NSError!) {
        Logger.debug("Peripheral#didUpdateValueForCharacteristic")
        if let characteristic = characteristic {
            if let bcCharacteristic = self.discoveredCharacteristics[characteristic] {
                Logger.debug("Peripheral#didUpdateValueForCharacteristic: uuid=\(bcCharacteristic.uuid.UUIDString), name=\(bcCharacteristic.name)")
                bcCharacteristic.didUpdate(error)
            }
        }
    }

    public func peripheral(_:CBPeripheral!, didWriteValueForCharacteristic characteristic:CBCharacteristic!, error: NSError!) {
        Logger.debug("Peripheral#didWriteValueForCharacteristic")
        if let characteristic = characteristic {
            if let bcCharacteristic = self.discoveredCharacteristics[characteristic] {
                Logger.debug("Peripheral#didWriteValueForCharacteristic: uuid=\(bcCharacteristic.uuid.UUIDString), name=\(bcCharacteristic.name)")
                bcCharacteristic.didWrite(error)
            }
        }
    }
    
    // descriptors
    public func peripheral(_:CBPeripheral!, didDiscoverDescriptorsForCharacteristic characteristic:CBCharacteristic!, error:NSError!) {
        Logger.debug("Peripheral#didDiscoverDescriptorsForCharacteristic")
    }
    
    public func peripheral(_:CBPeripheral!, didUpdateValueForDescriptor descriptor:CBDescriptor!, error:NSError!) {
        Logger.debug("Peripheral#didUpdateValueForDescriptor")
    }
    
    public func peripheral(_:CBPeripheral!, didWriteValueForDescriptor descriptor:CBDescriptor!, error:NSError!) {
        Logger.debug("Peripheral#didWriteValueForDescriptor")
    }
    
    // PRIVATE
    private func timeoutConnection(sequence:Int) {
        let central = CentralManager.sharedInstance()
        var timeout = self.defaultConnectionTimeout
        if let connectorator = self.connectorator {
            timeout = connectorator.connectionTimeout
        }
        Logger.debug("Peripheral#timeoutConnection: sequence \(sequence), timeout:\(timeout)")
        central.delayCallback(timeout) {
            if self.state != .Connected && sequence == self.connectionSequence && !self.forcedDisconnect {
                Logger.debug("Peripheral#timeoutConnection: timing out sequence=\(sequence), current connectionSequence=\(self.connectionSequence)")
                self.currentError = .Timeout
                central.cancelPeripheralConnection(self)
            } else {
                Logger.debug("Peripheral#timeoutConnection: expired")
            }
        }
    }
    
    private func discoverIfConnected(services:[CBUUID]!) {
        if self.state == .Connected {
            self.cbPeripheral.discoverServices(services)
        } else {
            if let serviceDiscoveryFailedCallback = self.serviceDiscoveryFailedCallback {
                CentralManager.asyncCallback(){serviceDiscoveryFailedCallback(error:
                    NSError(domain:BCError.domain, code:BCError.PeripheralDisconnected.code, userInfo:[NSLocalizedDescriptionKey:BCError.PeripheralDisconnected.description]))}
            }
        }
    }
    
    private func clearAll() {
        self.discoveredServices.removeAll()
        self.discoveredCharacteristics.removeAll()
    }
    
    // INTERNAL
    internal func didDisconnectPeripheral() {
        Logger.debug("Peripheral#didDisconnectPeripheral")
        if let connectorator = self.connectorator {
            if (self.forcedDisconnect) {
                self.forcedDisconnect = false
                CentralManager.asyncCallback() {
                    Logger.debug("Peripheral#didFailToConnectPeripheral: forced disconnect")
                    connectorator.didForceDisconnect(self)
                }
            } else {
                switch(self.currentError) {
                case .None:
                        CentralManager.asyncCallback() {
                            Logger.debug("Peripheral#didFailToConnectPeripheral: No errors disconnecting")
                            connectorator.didDisconnect(self)
                        }
                case .Timeout:
                        CentralManager.asyncCallback() {
                            Logger.debug("Peripheral#didFailToConnectPeripheral: Timeout reconnecting")
                            connectorator.didTimeout(self)
                        }
                }
            }
        }
    }

    internal func didConnectPeripheral() {
        Logger.debug("PeripheralConnectionError#didConnectPeripheral")
        if let connectorator = self.connectorator {
            connectorator.didConnect(self)
        }
    }
    
    internal func didFailToConnectPeripheral(error:NSError!) {
        Logger.debug("PeripheralConnectionError#didFailToConnectPeripheral")
        if let connectorator = self.connectorator {
            connectorator.didFailConnect(self, error:error)
        }
    }
    
    internal func discoverService(head:Service, tail:[Service], peripheralDiscoveredCallback:()->(), peripheralDiscoveryFailedCallback:((error:NSError!)->())? = nil) {
        if tail.count > 1 {
            head.discoverAllCharacteristics({
                self.discoverService(tail[0], tail:Array(tail[1..<tail.count]), peripheralDiscoveredCallback:peripheralDiscoveredCallback, peripheralDiscoveryFailedCallback: peripheralDiscoveryFailedCallback)
                }, characteristicDiscoveryFailedCallback:peripheralDiscoveryFailedCallback)
        } else {
            tail[0].discoverAllCharacteristics(peripheralDiscoveredCallback, characteristicDiscoveryFailedCallback:peripheralDiscoveryFailedCallback)
        }
    }
}
