//
//  Injectables.swift
//  BlueCapKit
//
//  Created by Troy Stribling on 4/20/16.
//  Copyright © 2016 Troy Stribling. All rights reserved.
//

import Foundation
import CoreBluetooth

// MARK: - ManagerState -
public enum ManagerState: CustomStringConvertible {
    case unauthorized, unknown, unsupported, resetting, poweredOff, poweredOn

    public var description: String {
        switch self {
        case .unauthorized:
            return "unauthorized"
        case .unknown:
            return "unknown"
        case .unsupported:
            return "unsupported"
        case .resetting:
            return "resetting"
        case .poweredOff:
            return "poweredOff"
        case .poweredOn:
            return "poweredOn"
        }
    }
}

// MARK: - CBCentralManagerInjectable -
protocol CBCentralManagerInjectable: class {
    var managerState : ManagerState { get }
    var delegate: CBCentralManagerDelegate? { get set }
    func scanForPeripherals(withServices serviceUUIDs: [CBUUID]?, options: [String : Any]?)
    func stopScan()
    func connect(_ peripheral: CBPeripheralInjectable, options: [String : Any]?)
    func cancelPeripheralConnection(_ peripheral: CBPeripheralInjectable)
    func retrieveConnectedPeripherals(withServices serviceUUIDs: [CBUUID]) -> [CBPeripheralInjectable]
    func retrievePeripherals(withIdentifiers identifiers: [UUID]) -> [CBPeripheralInjectable]
}

extension CBCentralManager : CBCentralManagerInjectable {

    var managerState: ManagerState {
        switch state {
        case .unauthorized:
            return .unauthorized
        case .unknown:
            return .unknown
        case .unsupported:
            return .unsupported
        case .resetting:
            return .resetting
        case .poweredOff:
            return .poweredOff
        case .poweredOn:
            return .poweredOn
        }
    }

    func connect(_ peripheral: CBPeripheralInjectable, options: [String : Any]?) {
        self.connect(peripheral as! CBPeripheral, options: options)
    }

    func cancelPeripheralConnection(_ peripheral: CBPeripheralInjectable) {
        self.cancelPeripheralConnection(peripheral as! CBPeripheral)
    }

    func retrieveConnectedPeripherals(withServices serviceUUIDs: [CBUUID]) -> [CBPeripheralInjectable] {
        let peripherals = self.retrieveConnectedPeripherals(withServices: serviceUUIDs) as [CBPeripheral]
        return  peripherals.map { $0 as CBPeripheralInjectable }
    }

    func retrievePeripherals(withIdentifiers identifiers: [UUID]) -> [CBPeripheralInjectable] {
        let peripherals = self.retrievePeripherals(withIdentifiers: identifiers) as [CBPeripheral]
        return  peripherals.map { $0 as CBPeripheralInjectable }
    }
}

// MARK: - CBPeripheralInjectable -
protocol CBPeripheralInjectable: class {
    var name: String? { get }
    var state: CBPeripheralState { get }
    var identifier: UUID { get }
    var delegate: CBPeripheralDelegate? { get set }

    func readRSSI()
    func discoverServices(_ services: [CBUUID]?)
    func discoverCharacteristics(_ characteristics: [CBUUID]?, forService service: CBServiceInjectable)
    func setNotifyValue(_ enabled:Bool, forCharacteristic characteristic: CBCharacteristicInjectable)
    func readValueForCharacteristic(_ characteristic: CBCharacteristicInjectable)
    func writeValue(_ data:Data, forCharacteristic characteristic: CBCharacteristicInjectable, type: CBCharacteristicWriteType)

    func getServices() -> [CBServiceInjectable]?
}

extension CBPeripheral: CBPeripheralInjectable {

    func discoverCharacteristics(_ characteristics:[CBUUID]?, forService service: CBServiceInjectable) {
        self.discoverCharacteristics(characteristics, for: service as! CBService)
    }

    func setNotifyValue(_ enabled: Bool, forCharacteristic characteristic: CBCharacteristicInjectable) {
        self.setNotifyValue(enabled, for: characteristic as! CBCharacteristic)
    }

    func readValueForCharacteristic(_ characteristic: CBCharacteristicInjectable) {
        self.readValue(for: characteristic as! CBCharacteristic)
    }

    func writeValue(_ data: Data, forCharacteristic characteristic: CBCharacteristicInjectable, type: CBCharacteristicWriteType) {
        self.writeValue(data, for: characteristic as! CBCharacteristic, type: type)
    }

    func getServices() -> [CBServiceInjectable]? {
        guard let services = services else { return nil }
        return services.map{ $0 as CBServiceInjectable }
    }
    
}

// MARK: - CBServiceInjectable -
protocol CBServiceInjectable: class {
    var uuid: CBUUID { get }
    func getCharacteristics() -> [CBCharacteristicInjectable]?
}

extension CBService : CBServiceInjectable {
    func getCharacteristics() -> [CBCharacteristicInjectable]? {
        guard let characteristics = self.characteristics else { return nil }
        return characteristics.map{ $0 as CBCharacteristicInjectable }
    }
}

// MARK: - CBCharacteristicInjectable -
public protocol CBCharacteristicInjectable: class {
    var uuid: CBUUID { get }
    var value: Data? { get }
    var properties: CBCharacteristicProperties { get }
    var isNotifying: Bool { get }
}

extension CBCharacteristic : CBCharacteristicInjectable {}

// MARK: - CBPeripheralManagerInjectable -
protocol CBPeripheralManagerInjectable {
    var delegate: CBPeripheralManagerDelegate? { get set }
    var isAdvertising: Bool { get }
    var managerState: ManagerState { get }
    func startAdvertising(_ advertisementData : [String : Any]?)
    func stopAdvertising()
    func add(_ service: CBMutableServiceInjectable)
    func remove(_ service: CBMutableServiceInjectable)
    func removeAllServices()
    func respondToRequest(_ request: CBATTRequestInjectable, withResult result: CBATTError.Code)
    func updateValue(_ value: Data, forCharacteristic characteristic: CBMutableCharacteristicInjectable, onSubscribedCentrals centrals: [CBCentralInjectable]?) -> Bool
}

extension CBPeripheralManager: CBPeripheralManagerInjectable {

    var managerState: ManagerState {
        switch state {
        case .unauthorized:
            return .unauthorized
        case .unknown:
            return .unknown
        case .unsupported:
            return .unsupported
        case .resetting:
            return .resetting
        case .poweredOff:
            return .poweredOff
        case .poweredOn:
            return .poweredOn
        }
    }

    func add(_ service: CBMutableServiceInjectable) {
        self.add(service as! CBMutableService)
    }

    func remove(_ service: CBMutableServiceInjectable) {
        self.remove(service as! CBMutableService)
    }

    func respondToRequest(_ request: CBATTRequestInjectable, withResult result: CBATTError.Code) {
        self.respond(to: request as! CBATTRequest, withResult: result)
    }

    func updateValue(_ value: Data, forCharacteristic characteristic: CBMutableCharacteristicInjectable, onSubscribedCentrals centrals: [CBCentralInjectable]?) -> Bool {
        return self.updateValue(value, for: characteristic as! CBMutableCharacteristic, onSubscribedCentrals: centrals as! [CBCentral]?)
    }

}

// MARK: - CBMutableServiceInjectable -
protocol CBMutableServiceInjectable: CBServiceInjectable {
    func setCharacteristics(_ characteristics: [CBCharacteristicInjectable]?)
}

extension CBMutableService: CBMutableServiceInjectable {
    func setCharacteristics(_ characteristics: [CBCharacteristicInjectable]?) {
        self.characteristics = characteristics?.map { $0 as! CBCharacteristic }
    }
}

// MARK: - CBMutableCharacteristicInjectable -
protocol CBMutableCharacteristicInjectable: CBCharacteristicInjectable {
    var permissions: CBAttributePermissions { get }
}

extension CBMutableCharacteristic : CBMutableCharacteristicInjectable {}


// MARK: - CBATTRequestInjectable -
public protocol CBATTRequestInjectable {
    var offset: Int { get }
    var value: Data? { get set }
    func getCharacteristic() -> CBCharacteristicInjectable
}

extension CBATTRequest: CBATTRequestInjectable {
    public func getCharacteristic() -> CBCharacteristicInjectable {
        return self.characteristic
    }
}

// MARK: - CBCentralInjectable -
public protocol CBCentralInjectable {
    var identifier: UUID { get }
    var maximumUpdateValueLength: Int { get }
}

extension CBCentral: CBCentralInjectable {}

