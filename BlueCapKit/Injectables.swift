//
//  Injectables.swift
//  BlueCapKit
//
//  Created by Troy Stribling on 4/20/16.
//  Copyright © 2016 Troy Stribling. All rights reserved.
//

import Foundation
import CoreBluetooth

// MARK: - CBCentralManagerInjectable -
public protocol CBCentralManagerInjectable {
    var state : CBCentralManagerState { get }
    var delegate: CBCentralManagerDelegate? { get set }
    func scanForPeripheralsWithServices(uuids: [CBUUID]?, options: [String: AnyObject]?)
    func stopScan()
    func connectPeripheral(peripheral: CBPeripheralInjectable, options: [String: AnyObject]?)
    func cancelPeripheralConnection(peripheral: CBPeripheralInjectable)
    func retrieveConnectedPeripheralsWithServices(serviceUUIDs: [CBUUID]) -> [CBPeripheralInjectable]
    func retrievePeripheralsWithIdentifiers(identifiers: [NSUUID]) -> [CBPeripheralInjectable]
}

extension CBCentralManager : CBCentralManagerInjectable {

    public func connectPeripheral(peripheral: CBPeripheralInjectable, options: [String: AnyObject]?) {
        self.connectPeripheral(peripheral as! CBPeripheral, options: options)
    }

    public func cancelPeripheralConnection(peripheral: CBPeripheralInjectable) {
        self.cancelPeripheralConnection(peripheral as! CBPeripheral)
    }

    public func retrieveConnectedPeripheralsWithServices(serviceUUIDs: [CBUUID]) -> [CBPeripheralInjectable] {
        let peripherals = self.retrieveConnectedPeripheralsWithServices(serviceUUIDs) as [CBPeripheral]
        return  peripherals.map { $0 as CBPeripheralInjectable }
    }

    public func retrievePeripheralsWithIdentifiers(identifiers: [NSUUID]) -> [CBPeripheralInjectable] {
        let peripherals = self.retrievePeripheralsWithIdentifiers(identifiers) as [CBPeripheral]
        return  peripherals.map { $0 as CBPeripheralInjectable }
    }
}

// MARK: - CBPeripheralInjectable -
public protocol CBPeripheralInjectable {
    var name: String? { get }
    var state: CBPeripheralState { get }
    var identifier: NSUUID { get }
    var delegate: CBPeripheralDelegate? { get set }

    func readRSSI()
    func discoverServices(services: [CBUUID]?)
    func discoverCharacteristics(characteristics: [CBUUID]?, forService service: CBServiceInjectable)
    func setNotifyValue(enabled:Bool, forCharacteristic characteristic: CBCharacteristicInjectable)
    func readValueForCharacteristic(characteristic: CBCharacteristicInjectable)
    func writeValue(data:NSData, forCharacteristic characteristic: CBCharacteristicInjectable, type: CBCharacteristicWriteType)

    func getServices() -> [CBServiceInjectable]?
}

extension CBPeripheral : CBPeripheralInjectable {

    public func discoverCharacteristics(characteristics:[CBUUID]?, forService service: CBServiceInjectable) {
        self.discoverCharacteristics(characteristics, forService: service as! CBService)
    }

    public func setNotifyValue(enabled: Bool, forCharacteristic characteristic: CBCharacteristicInjectable) {
        self.setNotifyValue(enabled, forCharacteristic: characteristic as! CBCharacteristic)
    }

    public func readValueForCharacteristic(characteristic: CBCharacteristicInjectable) {
        self.readValueForCharacteristic(characteristic as! CBCharacteristic)
    }

    public func writeValue(data: NSData, forCharacteristic characteristic: CBCharacteristicInjectable, type: CBCharacteristicWriteType) {
        self.writeValue(data, forCharacteristic: characteristic as! CBCharacteristic, type: type)
    }

    public func getServices() -> [CBServiceInjectable]? {
        guard let services = self.services else { return nil }
        return services.map{ $0 as CBServiceInjectable }
    }
    
}

// MARK: - CBServiceInjectable -
public protocol CBServiceInjectable {
    var UUID: CBUUID { get }
    func getCharacteristics() -> [CBCharacteristicInjectable]?
}

extension CBService : CBServiceInjectable {
    public func getCharacteristics() -> [CBCharacteristicInjectable]? {
        guard let characteristics = self.characteristics else { return nil }
        return characteristics.map{ $0 as CBCharacteristicInjectable }
    }
}

// MARK: - CBCharacteristicInjectable -
public protocol CBCharacteristicInjectable {
    var UUID: CBUUID { get }
    var value: NSData? { get }
    var properties: CBCharacteristicProperties { get }
    var isNotifying: Bool { get }
}

extension CBCharacteristic : CBCharacteristicInjectable {}

// MARK: - CBPeripheralManagerInjectable -
public protocol CBPeripheralManagerInjectable {
    var delegate: CBPeripheralManagerDelegate? { get set }
    var isAdvertising: Bool { get }
    var state: CBPeripheralManagerState { get }
    func startAdvertising(advertisementData:[String:AnyObject]?)
    func stopAdvertising()
    func addService(service: CBMutableServiceInjectable)
    func removeService(service: CBMutableServiceInjectable)
    func removeAllServices()
    func respondToRequest(request: CBATTRequestInjectable, withResult result: CBATTError)
    func updateValue(value: NSData, forCharacteristic characteristic: CBMutableCharacteristicInjectable, onSubscribedCentrals centrals: [CBCentralInjectable]?) -> Bool
}

extension CBPeripheralManager: CBPeripheralManagerInjectable {

    public func addService(service: CBMutableServiceInjectable) {
        self.addService(service as! CBMutableService)
    }

    public func removeService(service: CBMutableServiceInjectable) {
        self.removeService(service as! CBMutableService)
    }

    public func respondToRequest(request: CBATTRequestInjectable, withResult result: CBATTError) {
        self.respondToRequest(request as! CBATTRequest, withResult: result)
    }

    public func updateValue(value: NSData, forCharacteristic characteristic: CBMutableCharacteristicInjectable, onSubscribedCentrals centrals: [CBCentralInjectable]?) -> Bool {
        return self.updateValue(value, forCharacteristic: characteristic as! CBMutableCharacteristic, onSubscribedCentrals: centrals as! [CBCentral]?)
    }

}

// MARK: - CBMutableServiceInjectable -
public protocol CBMutableServiceInjectable : CBServiceInjectable {
    func setCharacteristics(characteristics: [CBCharacteristicInjectable]?)
}

extension CBMutableService : CBMutableServiceInjectable {
    public func setCharacteristics(characteristics: [CBCharacteristicInjectable]?) {
        self.characteristics = characteristics?.map { $0 as! CBCharacteristic }
    }
}

// MARK: - CBMutableCharacteristicInjectable -
public protocol CBMutableCharacteristicInjectable : CBCharacteristicInjectable {
    var permissions: CBAttributePermissions { get }
}

extension CBMutableCharacteristic : CBMutableCharacteristicInjectable {}


// MARK: - CBATTRequestInjectable -
public protocol CBATTRequestInjectable {
    var offset: Int { get }
    var value: NSData? { get set }
    func getCharacteristic() -> CBCharacteristicInjectable
}

extension CBATTRequest: CBATTRequestInjectable {
    public func getCharacteristic() -> CBCharacteristicInjectable {
        return self.characteristic
    }
}

// MARK: - CBCentralInjectable -
public protocol CBCentralInjectable {
    var identifier: NSUUID { get }
    var maximumUpdateValueLength: Int { get }
}

extension CBCentral: CBCentralInjectable {}

