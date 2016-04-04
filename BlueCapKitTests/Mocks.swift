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

 // MARK: - Error -
struct TestFailure {
    static let error = NSError(domain:"BlueCapKit Tests", code:100, userInfo:[NSLocalizedDescriptionKey:"Testing"])
}

// MARK: - Advertisements -
let peripheralAdvertisements = [CBAdvertisementDataLocalNameKey:"Test Peripheral",
                                CBAdvertisementDataTxPowerLevelKey:NSNumber(integer:-45)]

// MARK: - CBCentralManagerMock -
class CBCentralManagerMock: CBCentralManagerInjectable {
    
    var state: CBCentralManagerState
    var scanForPeripheralsWithServicesCalled = false
    var stopScanCalled = false
    var delegate: CBCentralManagerDelegate?
    
    init(state: CBCentralManagerState = .PoweredOn) {
        self.state = state
    }
    
    func scanForPeripheralsWithServices(uuids: [CBUUID]?, options:[ String:AnyObject]?) {
        self.scanForPeripheralsWithServicesCalled = true
    }
    
    func stopScan() {
        self.stopScanCalled = true
    }
    
    func connectPeripheral(peripheral: CBPeripheral, options: [String:AnyObject]?) {
    }
    
    func cancelPeripheralConnection(peripheral: CBPeripheral) {
    }

    func retrieveConnectedPeripheralsWithServices(serviceUUIDs: [CBUUID]) -> [CBPeripheral] {
        return []
    }

    func retrievePeripheralsWithIdentifiers(identifiers: [NSUUID]) -> [CBPeripheral] {
        return []
    }

}

// MARK: - CentralManagerUT -
class CentralManagerUT: BCCentralManager {
    
    var connectPeripheralCalled     = false
    var cancelPeripheralConnection  = false

    override init(centralManager: CBCentralManagerInjectable) {
        super.init(centralManager: centralManager)
    }

    override func connectPeripheral(peripheral: BCPeripheral, options: [String: AnyObject]? = nil) {
        self.connectPeripheralCalled = true
    }
    
    override func cancelPeripheralConnection(peripheral: BCPeripheral) {
        peripheral.didDisconnectPeripheral(nil)
        self.cancelPeripheralConnection = true
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
    
    var writtenData: NSData?
    var writtenType: CBCharacteristicWriteType?
    var notifyingState: Bool?
    
    var discoverServicesCalledCount = 0
    var discoverCharacteristicsCalledCount = 0
    var readRSSICalledCount = 0
    
    var setNotifyValueCount = 0
    var readValueForCharacteristicCount = 0
    var writeValueCount = 0
    
    let identifier: NSUUID

    init(state: CBPeripheralState = .Disconnected, identifier: NSUUID = NSUUID()) {
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

    var services: [CBService]? {
        return nil
    }

    func readRSSI() {
        self.readRSSICalled = true
    }

    func discoverServices(services: [CBUUID]?) {
        self.discoverServicesCalled = true
        self.discoverServicesCalledCount += 1
    }
    
    func discoverCharacteristics(characteristics: [CBUUID]?, forService: CBService) {
        self.discoverCharacteristicsCalled = true
        self.discoverCharacteristicsCalledCount += 1
    }
    
    func setNotifyValue(state: Bool, forCharacteristic: CBCharacteristic) {
        self.setNotifyValueCalled = true
        self.setNotifyValueCount += 1
        self.notifyingState = state
    }
    
    func readValueForCharacteristic(characteristic: CBCharacteristic) {
        self.readValueForCharacteristicCount += 1
        self.readValueForCharacteristicCalled = true
    }
    
    func writeValue(data:NSData, forCharacteristic: CBCharacteristic, type: CBCharacteristicWriteType) {
        self.writeValueCount += 1
        self.writeValueCalled = true
        self.writtenData = data
        self.writtenType = type
    }

}

// MARK: - PeripheralUT -
class PeripheralUT: BCPeripheral {
    
    let error:NSError?
    
    init(cbPeripheral: CBPeripheralInjectable, centralManager: BCCentralManager, advertisements: [String: AnyObject], rssi: Int, error: NSError?) {
        self.error = error
        super.init(cbPeripheral: cbPeripheral, centralManager: centralManager, advertisements: advertisements, RSSI: rssi)
    }
    
    override func discoverService(head: BCService, tail: [BCService], promise: Promise<BCPeripheral>) {
        if let error = self.error {
            promise.failure(error)
        } else {
            promise.success(self)
            
        }
    }

}

// MARK: - CBServiceMock -
class CBServiceMock: CBMutableService {
    
    init(UUID:CBUUID = CBUUID(string: "2f0a0017-69aa-f316-3e78-4194989a6ccc")) {
        super.init(type: UUID, primary: true)
    }
    
}

// MARK: - ServiceUT -
class ServiceUT: BCService {
    
    let error: NSError?
    let mockCharacteristics: [CBCharacteristic]
    
    init(cbService: CBServiceMock, peripheral: BCPeripheral, mockCharacteristics: [CBCharacteristic], error: NSError?) {
        self.error = error
        self.mockCharacteristics = mockCharacteristics
        cbService.characteristics = mockCharacteristics
        super.init(cbService:cbService, peripheral:peripheral)
    }
    
    override func discoverAllCharacteristics(timout: NSTimeInterval? = nil) -> Future<BCService> {
        self.didDiscoverCharacteristics(self.mockCharacteristics, error: self.error)
        return self.characteristicsDiscoveredPromise!.future
    }
}

// MARK: - CBCharacteristicMock -
class CBCharacteristicMock: CBMutableCharacteristic {
    
    var _isNotifying = false
    
    override var isNotifying: Bool {
        get {
            return self._isNotifying
        }
        set {
            self._isNotifying = newValue
        }
    }

    init (UUID: CBUUID, properties: CBCharacteristicProperties, permissions: CBAttributePermissions, isNotifying: Bool) {
        super.init(type: UUID, properties: properties, value: nil, permissions: permissions)
        self._isNotifying = isNotifying
    }
    
}

// MARK: - CBPeripheralManagerMock -
class CBPeripheralManagerMock: CBPeripheralManagerInjectable {

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
    var addedService: CBMutableService?
    var removedService: CBMutableService?
    var delegate: CBPeripheralManagerDelegate?
    
    var removeServiceCount = 0
    var addServiceCount = 0
    var updateValueCount = 0
    
    init(isAdvertising: Bool, state: CBPeripheralManagerState) {
        self.isAdvertising = isAdvertising
        self.state = state
    }
    
    func startAdvertising(advertisementData: [String:AnyObject]?) {
        self.startAdvertisingCalled = true
        self.advertisementData = advertisementData
        self.isAdvertising = true
    }
    
    func stopAdvertising() {
        self.stopAdvertisingCalled = true
        self.isAdvertising = false
    }
    
    func addService(service: CBMutableService) {
        self.addServiceCalled = true
        self.addedService = service
        self.addServiceCount += 1
    }
    
    func removeService(service: CBMutableService) {
        self.removeServiceCalled = true
        self.removedService = service
        self.removeServiceCount += 1
    }
    
    func removeAllServices() {
        self.removeAllServicesCalled = true
    }
    
    func respondToRequest(request: CBATTRequest, withResult result: CBATTError) {
        self.respondToRequestCalled = true
    }
    
    func updateValue(value: NSData, forCharacteristic characteristic: CBMutableCharacteristic, onSubscribedCentrals centrals: [CBCentral]?) -> Bool {
        self.updateValueCalled = true
        self.updateValueCount += 1
        return self.updateValueReturn
    }
}

// MARK: - PeripheralManagerUT -
class PeripheralManagerUT: BCPeripheralManager {
    
    var respondToRequestCalled = false

    var error: NSError?
    var result: CBATTError?
    var request: CBATTRequestInjectable?
    
    override func addServices(promise: Promise<Void>, services: [BCMutableService]) {
        super.addServices(promise, services: services)
        if let service = services.first {
            self.didAddService(service.cbMutableService, error: self.error)
        }
    }
    
    override func respondToRequest(request: CBATTRequestInjectable, withResult result: CBATTError) {
        self.respondToRequestCalled = true
        self.result = result
        self.request = request
    }
}

// MARK: - CBATTRequestMock -
class CBATTRequestMock : CBATTRequestInjectable {

    let characteristic: CBCharacteristic
    let offset: Int
    var value: NSData?
    
    init(characteristic: CBMutableCharacteristic, offset: Int, value: NSData? = nil) {
        self.value = value
        self.characteristic = characteristic
        self.offset = offset
    }
    
}

// MARK: - CBCentralMock -
class CBCentralMock : CBCentralInjectable {

    let identifier: NSUUID
    let maximumUpdateValueLength: Int

    init(identifier: NSUUID, maximumUpdateValueLength: Int) {
        self.identifier = identifier
        self.maximumUpdateValueLength = maximumUpdateValueLength
    }
}

// MARK: - Utilities -
func createPeripheralManager(isAdvertising: Bool, state: CBPeripheralManagerState) -> (CBPeripheralManagerMock, PeripheralManagerUT) {
    let mock = CBPeripheralManagerMock(isAdvertising: isAdvertising, state: state)
    return (mock, PeripheralManagerUT(peripheralManager:mock))
}

func createPeripheralManagerServices(peripheral: BCPeripheralManager) -> [BCMutableService] {
    let profileManager = BCProfileManager.sharedInstance
    if let helloWoroldService = profileManager.services[CBUUID(string: Gnosus.HelloWorldService.UUID)],
           locationService = profileManager.services[CBUUID(string: Gnosus.LocationService.UUID)] {
        return [BCMutableService(profile: helloWoroldService),
                BCMutableService(profile: locationService)]
    } else {
        return []
    }
}

