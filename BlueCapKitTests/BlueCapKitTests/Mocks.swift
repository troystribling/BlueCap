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

    var connectPeripheralCalled     = false
    var cancelPeripheralConnection  = false
    var scanForPeripheralsWithServicesCalled = false

    var state: CBCentralManagerState
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
    
    func connectPeripheral(peripheral: CBPeripheralInjectable, options: [String: AnyObject]?) {
        self.connectPeripheralCalled = true
    }

    func cancelPeripheralConnection(peripheral: CBPeripheralInjectable) {
        self.cancelPeripheralConnection = true
    }

    func retrieveConnectedPeripheralsWithServices(serviceUUIDs: [CBUUID]) -> [CBPeripheralInjectable] {
        return self.retrieveConnectedPeripheralsWithServices(serviceUUIDs)
    }

    func retrievePeripheralsWithIdentifiers(identifiers: [NSUUID]) -> [CBPeripheralInjectable] {
        return self.retrievePeripheralsWithIdentifiers(identifiers)
    }

}

// MARK: - CentralManagerUT -
class CentralManagerUT: BCCentralManager {

    override init(centralManager: CBCentralManagerInjectable) {
        super.init(centralManager: centralManager)
    }

    override func cancelPeripheralConnection(peripheral: BCPeripheral) {
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

    var services: [CBServiceMock]?

    var bcPeripheral: BCPeripheral?
    var error: NSError?
    var RSSI: Int = -44

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

    func readRSSI() {
        self.readRSSICalled = true
        self.readRSSICalledCount += 1
        self.bcPeripheral?.didReadRSSI(NSNumber(long: self.RSSI), error: self.error)
    }

    func discoverServices(services: [CBUUID]?) {
        self.discoverServicesCalled = true
        self.discoverServicesCalledCount += 1
    }
    
    func discoverCharacteristics(characteristics: [CBUUID]?, forService service: CBServiceInjectable) {
        self.discoverCharacteristicsCalled = true
        self.discoverCharacteristicsCalledCount += 1
    }
    
    func setNotifyValue(state: Bool, forCharacteristic characteristic: CBCharacteristicInjectable) {
        self.setNotifyValueCalled = true
        self.setNotifyValueCount += 1
        self.notifyingState = state
    }
    
    func readValueForCharacteristic(characteristic: CBCharacteristicInjectable) {
        self.readValueForCharacteristicCount += 1
        self.readValueForCharacteristicCalled = true
    }
    
    func writeValue(data:NSData, forCharacteristic characteristic: CBCharacteristicInjectable, type: CBCharacteristicWriteType) {
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
class CBServiceMock: CBServiceInjectable {

    var UUID: CBUUID
    var characteristics: [CBCharacteristicMock]?

    init(UUID:CBUUID = CBUUID(string: NSUUID().UUIDString)) {
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
    var value: NSData?
    var properties: CBCharacteristicProperties
    var isNotifying = false

    init (UUID: CBUUID = CBUUID(string: NSUUID().UUIDString), properties: CBCharacteristicProperties = [.Read, .Write], isNotifying: Bool = false) {
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
    dynamic var isAdvertising : Bool
    dynamic var state: CBPeripheralManagerState
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
    
    func startAdvertising(advertisementData: [String:AnyObject]?) {
        self.startAdvertisingCalled = true
        self.advertisementData = advertisementData
        self.isAdvertising = true
    }
    
    func stopAdvertising() {
        self.stopAdvertisingCalled = true
        self.isAdvertising = false
    }
    
    func addService(service: CBMutableServiceInjectable) {
        self.addServiceCalled = true
        self.addedService = service
        self.addServiceCount += 1
    }
    
    func removeService(service: CBMutableServiceInjectable) {
        self.removeServiceCalled = true
        self.removedService = service
        self.removeServiceCount += 1
    }
    
    func removeAllServices() {
        self.removeAllServicesCalled = true
    }
    
    func respondToRequest(request: CBATTRequestInjectable, withResult result: CBATTError) {
        self.respondToRequestCalled = true
    }
    
    func updateValue(value: NSData, forCharacteristic characteristic: CBMutableCharacteristicInjectable, onSubscribedCentrals centrals: [CBCentralInjectable]?) -> Bool {
        self.updateValueCalled = true
        self.updateValueCount += 1
        return self.updateValueReturn
    }

}

// MARK: - CBMutableServiceMock
class CBMutableServiceMock : CBServiceMock, CBMutableServiceInjectable {

    func setCharacteristics(characteristics: [CBCharacteristicInjectable]?) {
        self.characteristics = characteristics?.map { $0 as! CBMutableCharacteristicMock }
    }
}

// MARK: - CBMutableCharacteristicMock
class CBMutableCharacteristicMock : CBCharacteristicMock, CBMutableCharacteristicInjectable {
    var permissions: CBAttributePermissions

    init (UUID: CBUUID = CBUUID(string: NSUUID().UUIDString), properties: CBCharacteristicProperties = [.Read, .Write], permissions: CBAttributePermissions = [.Readable, .Writeable], isNotifying: Bool = false) {
        self.permissions = permissions
        super.init(UUID: UUID, properties: properties, isNotifying: isNotifying)
    }
}

// MARK: - PeripheralManagerUT -
class PeripheralManagerUT : BCPeripheralManager {
    
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

    override internal func startObserving() {
        guard let cbPeripheralManager = self.cbPeripheralManager as? CBPeripheralManagerMock else {
            return
        }
        let options = NSKeyValueObservingOptions([.New, .Old])
        cbPeripheralManager.addObserver(self, forKeyPath: "state", options: options, context: &BCPeripheralManager.CBPeripheralManagerStateKVOContext)
        cbPeripheralManager.addObserver(self, forKeyPath: "isAdvertising", options: options, context: &BCPeripheralManager.CBPeripheralManagerIsAdvertisingKVOContext)
    }

    override internal func stopObserving() {
        guard let cbPeripheralManager = self.cbPeripheralManager as? CBPeripheralManagerMock else {
            return
        }
        cbPeripheralManager.removeObserver(self, forKeyPath: "state", context: &BCPeripheralManager.CBPeripheralManagerStateKVOContext)
        cbPeripheralManager.removeObserver(self, forKeyPath: "isAdvertising", context: &BCPeripheralManager.CBPeripheralManagerIsAdvertisingKVOContext)
    }

}

// MARK: - CBATTRequestMock -
class CBATTRequestMock : CBATTRequestInjectable {

    let characteristic: CBMutableCharacteristicInjectable
    let offset: Int
    var value: NSData?
    
    init(characteristic: CBMutableCharacteristicInjectable, offset: Int, value: NSData? = nil) {
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
        return [BCMutableService(cbMutableService: CBMutableServiceMock(UUID: CBUUID(string: Gnosus.HelloWorldService.UUID)), profile: helloWoroldService),
                BCMutableService(cbMutableService: CBMutableServiceMock(UUID: CBUUID(string: Gnosus.HelloWorldService.UUID)), profile: locationService)]
    } else {
        return []
    }
}

