//
//  Mocks.swift
//  BlueCapKit
//
//  Created by Troy Stribling on 5/2/15.
//  Copyright (c) 2015 Troy Stribling. The MIT License (MIT).
//

import UIKit
import CoreBluetooth
import CoreLocation
@testable import BlueCapKit

// MARK: - Advertisements -
let peripheralAdvertisements = [CBAdvertisementDataLocalNameKey:"Test Peripheral",
                                CBAdvertisementDataTxPowerLevelKey:NSNumber(value:-45)] as [String : Any]

// MARK: - CBCentralManagerMock -
class CBCentralManagerMock: CBCentralManagerInjectable {

    var connectPeripheralCalled     = false
    var cancelPeripheralConnection  = false
    var scanForPeripheralsWithServicesCalled = false

    var state: CBCentralManagerState
    var stopScanCalled = false
    var delegate: CBCentralManagerDelegate?

    init(state: CBCentralManagerState = .poweredOn) {
        self.state = state
    }
    
    func scanForPeripheralsWithServices(_ uuids: [CBUUID]?, options:[ String:AnyObject]?) {
        self.scanForPeripheralsWithServicesCalled = true
    }
    
    func stopScan() {
        self.stopScanCalled = true
    }
    
    func connectPeripheral(_ peripheral: CBPeripheralInjectable, options: [String: AnyObject]?) {
        self.connectPeripheralCalled = true
    }

    func cancelPeripheralConnection(_ peripheral: CBPeripheralInjectable) {
        self.cancelPeripheralConnection = true
    }

    func retrieveConnectedPeripheralsWithServices(_ serviceUUIDs: [CBUUID]) -> [CBPeripheralInjectable] {
        return self.retrieveConnectedPeripheralsWithServices(serviceUUIDs)
    }

    func retrievePeripheralsWithIdentifiers(_ identifiers: [NSUUID]) -> [CBPeripheralInjectable] {
        return self.retrievePeripheralsWithIdentifiers(identifiers)
    }

}

// MARK: - CentralManagerUT -
class CentralManagerUT: CentralManager {

    override init(centralManager: CBCentralManagerInjectable) {
        super.init(centralManager: centralManager)
    }

    override func cancelPeripheralConnection(_ peripheral: Peripheral) {
        peripheral.didDisconnectPeripheral(nil)
    }
}

// MARK: - CBPeripheralMock -
class CBPeripheralMock: CBPeripheralInjectable {
   
    var state: CBPeripheralState
    var _delegate: CBPeripheralDelegate? = nil
    
    var setDelegateCalled = false
    var discoverServicesCalled = false
    var discoverCharacteristicsCalled = false
    var setNotifyValueCalled = false
    var readValueForCharacteristicCalled = false
    var writeValueCalled = false
    var readRSSICalled = false
    
    var writtenData: Data?
    var writtenType: CBCharacteristicWriteType?
    var notifyingState: Bool?
    
    var discoverServicesCalledCount = 0
    var discoverCharacteristicsCalledCount = 0
    var readRSSICalledCount = 0
    
    var setNotifyValueCount = 0
    var readValueForCharacteristicCount = 0
    var writeValueCount = 0
    
    let identifier: UUID

    var services: [CBServiceMock]?

    var bcPeripheral: Peripheral?
    var error: NSError?
    var RSSI: Int = -44

    init(state: CBPeripheralState = .disconnected, identifier: UUID = UUID()) {
        self.state = state
        self.identifier = identifier
    }
    
    var delegate: CBPeripheralDelegate? {
        get {
            return self._delegate
        }
        set {
            self._delegate = newValue
            self.setDelegateCalled = true
        }
    }
    
    var name: String? {
        return "Test Peripheral"
    }

    func readRSSI() {
        self.readRSSICalled = true
        self.readRSSICalledCount += 1
        self.bcPeripheral?.didReadRSSI(NSNumber(long: self.RSSI), error: self.error)
    }

    func discoverServices(_ services: [CBUUID]?) {
        self.discoverServicesCalled = true
        self.discoverServicesCalledCount += 1
    }
    
    func discoverCharacteristics(_ characteristics: [CBUUID]?, forService service: CBServiceInjectable) {
        self.discoverCharacteristicsCalled = true
        self.discoverCharacteristicsCalledCount += 1
    }
    
    func setNotifyValue(_ state: Bool, forCharacteristic characteristic: CBCharacteristicInjectable) {
        self.setNotifyValueCalled = true
        self.setNotifyValueCount += 1
        self.notifyingState = state
    }
    
    func readValueForCharacteristic(_ characteristic: CBCharacteristicInjectable) {
        self.readValueForCharacteristicCount += 1
        self.readValueForCharacteristicCalled = true
    }
    
    func writeValue(_ data:Data, forCharacteristic characteristic: CBCharacteristicInjectable, type: CBCharacteristicWriteType) {
        self.writeValueCount += 1
        self.writeValueCalled = true
        self.writtenData = data
        self.writtenType = type
    }

    func getServices() -> [CBServiceInjectable]? {
        guard let services = self.services else { return nil }
        return services.map{ $0 as CBServiceInjectable }
    }

}

// MARK: - PeripheralUT -
class PeripheralUT: Peripheral {
    
    let error:NSError?
    
    init(cbPeripheral: CBPeripheralInjectable, centralManager: CentralManager, advertisements: [String: AnyObject], rssi: Int, error: NSError?) {
        self.error = error
        super.init(cbPeripheral: cbPeripheral, centralManager: centralManager, advertisements: advertisements, RSSI: rssi)
    }
    
    override func discoverService(_ head: Service, tail: [Service], promise: Promise<Peripheral>) {
        if let error = self.error {
            promise.failure(error)
        } else {
            promise.success(self)
            
        }
    }

}

// MARK: - CBServiceMock -
class CBServiceMock: CBServiceInjectable {

    var UUID: CBUUID
    var characteristics: [CBCharacteristicMock]?

    init(UUID:CBUUID = CBUUID(string: Foundation.UUID().uuidString)) {
        self.UUID = UUID
    }

    func getCharacteristics() -> [CBCharacteristicInjectable]? {
        guard let characteristics = self.characteristics else { return nil }
        return characteristics.map{ $0 as CBCharacteristicInjectable }
    }

}

// MARK: - CBCharacteristicMock -
class CBCharacteristicMock: CBCharacteristicInjectable {
    
    var UUID: CBUUID
    var value: Data?
    var properties: CBCharacteristicProperties
    var isNotifying = false

    init (UUID: CBUUID = CBUUID(string: Foundation.UUID().uuidString), properties: CBCharacteristicProperties = [.read, .write], isNotifying: Bool = false) {
        self.UUID = UUID
        self.properties = properties
        self.isNotifying = isNotifying
    }
    
}

// MARK: - CBPeripheralManagerMock -
class CBPeripheralManagerMock: NSObject, CBPeripheralManagerInjectable {

    var services: [CBServiceMock]?

    var updateValueReturn = true
    
    var startAdvertisingCalled = false
    var stopAdvertisingCalled = false
    var addServiceCalled = false
    var removeServiceCalled = false
    var removeAllServicesCalled = false
    var respondToRequestCalled = false
    var updateValueCalled = false

    var advertisementData: [String:AnyObject]?
    var isAdvertising : Bool
    var state: CBPeripheralManagerState
    var addedService: CBMutableServiceInjectable?
    var removedService: CBMutableServiceInjectable?
    var delegate: CBPeripheralManagerDelegate?

    var removeServiceCount = 0
    var addServiceCount = 0
    var updateValueCount = 0

    init(isAdvertising: Bool, state: CBPeripheralManagerState) {
        self.isAdvertising = isAdvertising
        self.state = state
    }
    
    func startAdvertising(_ advertisementData: [String:AnyObject]?) {
        self.startAdvertisingCalled = true
        self.advertisementData = advertisementData
        self.isAdvertising = true
    }
    
    func stopAdvertising() {
        self.stopAdvertisingCalled = true
        self.isAdvertising = false
    }
    
    func addService(_ service: CBMutableServiceInjectable) {
        self.addServiceCalled = true
        self.addedService = service
        self.addServiceCount += 1
    }
    
    func removeService(_ service: CBMutableServiceInjectable) {
        self.removeServiceCalled = true
        self.removedService = service
        self.removeServiceCount += 1
    }
    
    func removeAllServices() {
        self.removeAllServicesCalled = true
    }
    
    func respondToRequest(_ request: CBATTRequestInjectable, withResult result: CBATTError.Code) {
        self.respondToRequestCalled = true
    }
    
    func updateValue(_ value: Data, forCharacteristic characteristic: CBMutableCharacteristicInjectable, onSubscribedCentrals centrals: [CBCentralInjectable]?) -> Bool {
        self.updateValueCalled = true
        self.updateValueCount += 1
        return self.updateValueReturn
    }

}

// MARK: - CBMutableServiceMock
class CBMutableServiceMock : CBServiceMock, CBMutableServiceInjectable {

    func setCharacteristics(_ characteristics: [CBCharacteristicInjectable]?) {
        self.characteristics = characteristics?.map { $0 as! CBMutableCharacteristicMock }
    }
}

// MARK: - CBMutableCharacteristicMock
class CBMutableCharacteristicMock : CBCharacteristicMock, CBMutableCharacteristicInjectable {
    var permissions: CBAttributePermissions

    init (UUID: CBUUID = CBUUID(string: Foundation.UUID().uuidString), properties: CBCharacteristicProperties = [.read, .write], permissions: CBAttributePermissions = [.readable, .writeable], isNotifying: Bool = false) {
        self.permissions = permissions
        super.init(UUID: UUID, properties: properties, isNotifying: isNotifying)
    }
}

// MARK: - PeripheralManagerUT -
class PeripheralManagerUT : PeripheralManager {
    
    var respondToRequestCalled = false

    var error: NSError?
    var result: CBATTError.Code?
    var request: CBATTRequestInjectable?
    
    override func addServices(_ promise: Promise<Void>, services: [MutableService]) {
        super.addServices(promise, services: services)
        if let service = services.first {
            self.didAddService(service.cbMutableService, error: self.error)
        }
    }
    
    override func respondToRequest(_ request: CBATTRequestInjectable, withResult result: CBATTError.Code) {
        self.respondToRequestCalled = true
        self.result = result
        self.request = request
    }

}

// MARK: - CBATTRequestMock -
class CBATTRequestMock : CBATTRequestInjectable {

    let characteristic: CBMutableCharacteristicInjectable
    let offset: Int
    var value: Data?
    
    init(characteristic: CBMutableCharacteristicInjectable, offset: Int, value: Data? = nil) {
        self.value = value
        self.characteristic = characteristic
        self.offset = offset
    }

    func getCharacteristic() -> CBCharacteristicInjectable {
        return self.characteristic
    }

}

// MARK: - CBCentralMock -
class CBCentralMock : CBCentralInjectable {

    let identifier: UUID
    let maximumUpdateValueLength: Int

    init(maximumUpdateValueLength: Int, identifier: UUID = UUID()) {
        self.identifier = identifier
        self.maximumUpdateValueLength = maximumUpdateValueLength
    }
}

// MARK: - Utilities -
func createPeripheralManager(_ isAdvertising: Bool, state: CBManagerState) -> (CBPeripheralManagerMock, PeripheralManagerUT) {
    let mock = CBPeripheralManagerMock(isAdvertising: isAdvertising, state: state)
    return (mock, PeripheralManagerUT(peripheralManager:mock))
}

func createPeripheralManagerServices(_ peripheral: PeripheralManager) -> [MutableService] {
    let profileManager = ProfileManager.sharedInstance
    if let helloWoroldService = profileManager.services[CBUUID(string: Gnosus.HelloWorldService.UUID)], let locationService = profileManager.services[CBUUID(string: Gnosus.LocationService.UUID)] {
        return [MutableService(cbMutableService: CBMutableServiceMock(UUID: CBUUID(string: Gnosus.HelloWorldService.UUID)), profile: helloWoroldService),
                MutableService(cbMutableService: CBMutableServiceMock(UUID: CBUUID(string: Gnosus.HelloWorldService.UUID)), profile: locationService)]
    } else {
        return []
    }
}

