//
//  Mocks.swift
//  BlueCapKit
//
//  Created by Troy Stribling on 5/2/15.
//  Copyright (c) 2015 Troy Stribling. The MIT License (MIT).
//

import CoreBluetooth
import CoreLocation

// MARK: - Advertisements -

public let peripheralAdvertisements: [String : Any] = [CBAdvertisementDataLocalNameKey : "Test Peripheral", CBAdvertisementDataTxPowerLevelKey : NSNumber(value: -45)]

// MARK: - ProfileManager -

public let profileManager = ProfileManager()

// MARK: - CBCentralManagerMock -

public class CBCentralManagerMock: CBCentralManagerInjectable {

    var connectPeripheralCalled = false
    var connectPeripheralCount = 0
    var cancelPeripheralConnectionCalled = false
    var cancelPeripheralConnectionCount = 0
    var scanForPeripheralsWithServicesCalled = false

    var retrievedPeripherals: [CBPeripheralInjectable] = []

    var state: ManagerState
    var stopScanCalled = false
    public var delegate: CBCentralManagerDelegate?

    public init(state: ManagerState = .poweredOn) {
        self.state = state
    }

    public var managerState: ManagerState {
        return state
    }

    public func scanForPeripherals(withServices uuids: [CBUUID]?, options:[String : Any]?) {
        scanForPeripheralsWithServicesCalled = true
    }
    
    public func stopScan() {
        stopScanCalled = true
    }
    
    public func connect(_ peripheral: CBPeripheralInjectable, options: [String : Any]?) {
        connectPeripheralCalled = true
        connectPeripheralCount += 1
    }

    public func cancelPeripheralConnection(_ peripheral: CBPeripheralInjectable) {
        cancelPeripheralConnectionCalled = true
        cancelPeripheralConnectionCount += 1
    }

    public func retrieveConnectedPeripherals(withServices serviceUUIDs: [CBUUID]) -> [CBPeripheralInjectable] {
        return retrievedPeripherals
    }

    public func retrievePeripherals(withIdentifiers identifiers: [UUID]) -> [CBPeripheralInjectable] {
        return retrievedPeripherals
    }

}

// MARK: - CentralManagerUT -

public class CentralManagerUT: CentralManager {

    public override init(centralManager: CBCentralManagerInjectable, profileManager: ProfileManager? = nil) {
        super.init(centralManager: centralManager, profileManager: profileManager)
    }

}

// MARK: - CBPeripheralMock -

public class CBPeripheralMock: CBPeripheralInjectable {
   
    public var state: CBPeripheralState
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
    
    public let identifier: UUID

    var services: [CBServiceMock]?

    var bcPeripheral: Peripheral?
    var error: Error?
    var RSSI: Int = -44

    public init(state: CBPeripheralState = .disconnected, identifier: UUID = UUID()) {
        self.state = state
        self.identifier = identifier
    }
    
    public var delegate: CBPeripheralDelegate? {
        get {
            return self._delegate
        }
        set {
            self._delegate = newValue
            self.setDelegateCalled = true
        }
    }
    
    public var name: String? {
        return "Test Peripheral"
    }

    public func readRSSI() {
        self.readRSSICalled = true
        self.readRSSICalledCount += 1
        self.bcPeripheral?.didReadRSSI(NSNumber(value: self.RSSI), error: self.error)
    }

    public func discoverServices(_ services: [CBUUID]?) {
        self.discoverServicesCalled = true
        self.discoverServicesCalledCount += 1
    }
    
    public func discoverCharacteristics(_ characteristics: [CBUUID]?, forService service: CBServiceInjectable) {
        self.discoverCharacteristicsCalled = true
        self.discoverCharacteristicsCalledCount += 1
    }
    
    public func setNotifyValue(_ state: Bool, forCharacteristic characteristic: CBCharacteristicInjectable) {
        self.setNotifyValueCalled = true
        self.setNotifyValueCount += 1
        self.notifyingState = state
    }
    
    public func readValueForCharacteristic(_ characteristic: CBCharacteristicInjectable) {
        self.readValueForCharacteristicCount += 1
        self.readValueForCharacteristicCalled = true
    }
    
    public func writeValue(_ data:Data, forCharacteristic characteristic: CBCharacteristicInjectable, type: CBCharacteristicWriteType) {
        self.writeValueCount += 1
        self.writeValueCalled = true
        self.writtenData = data
        self.writtenType = type
    }

    public func getServices() -> [CBServiceInjectable]? {
        guard let services = self.services else { return nil }
        return services.map{ $0 as CBServiceInjectable }
    }

}

// MARK: - PeripheralUT -

public class PeripheralUT: Peripheral {
    
    override func cancelPeripheralConnection(withTerminationStatus terminationStatus: PeripheralTerminationStatus) {
        super.cancelPeripheralConnection(withTerminationStatus: terminationStatus)
        didDisconnectPeripheral(nil)
    }
}

// MARK: - CBServiceMock -

public class CBServiceMock: CBServiceInjectable {

    public var uuid: CBUUID
    var characteristics: [CBCharacteristicMock]?

    init(uuid: CBUUID = CBUUID(nsuuid: UUID())) {
        self.uuid = uuid
    }

    public func getCharacteristics() -> [CBCharacteristicInjectable]? {
        guard let characteristics = self.characteristics else { return nil }
        return characteristics.map{ $0 as CBCharacteristicInjectable }
    }

}

// MARK: - CBCharacteristicMock -

public class CBCharacteristicMock: CBCharacteristicInjectable {
    
    public var uuid: CBUUID
    public var value: Data?
    public var properties: CBCharacteristicProperties
    public var isNotifying = false

    public init (uuid: CBUUID = CBUUID(string: Foundation.UUID().uuidString), properties: CBCharacteristicProperties = [.read, .write], isNotifying: Bool = false) {
        self.uuid = uuid
        self.properties = properties
        self.isNotifying = isNotifying
    }
    
}

// MARK: - CBPeripheralManagerMock -

public class CBPeripheralManagerMock: NSObject, CBPeripheralManagerInjectable {

    var services: [CBServiceMock]?

    var updateValueReturn = true
    
    var startAdvertisingCalled = false
    var stopAdvertisingCalled = false
    var addServiceCalled = false
    var removeServiceCalled = false
    var removeAllServicesCalled = false
    var respondToRequestCalled = false
    var updateValueCalled = false

    var advertisementData: [String : Any]?
    var isAdvertising : Bool
    let stopAdvertiseFail: Bool
    var state: ManagerState
    var addedService: CBMutableServiceInjectable?
    var removedService: CBMutableServiceInjectable?
    var delegate: CBPeripheralManagerDelegate?

    var removeServiceCount = 0
    var addServiceCount = 0
    var updateValueCount = 0

    init(isAdvertising: Bool, state: ManagerState, stopAdvertiseFail: Bool = false) {
        self.isAdvertising = isAdvertising
        self.state = state
        self.stopAdvertiseFail = stopAdvertiseFail
    }

    var managerState: ManagerState {
        return state
    }

    func startAdvertising(_ advertisementData: [String : Any]?) {
        self.startAdvertisingCalled = true
        self.advertisementData = advertisementData
        self.isAdvertising = true
    }
    
    func stopAdvertising() {
        self.stopAdvertisingCalled = true
        guard !stopAdvertiseFail else {
            return
        }
        self.isAdvertising = false
    }
    
    func add(_ service: CBMutableServiceInjectable) {
        self.addServiceCalled = true
        self.addedService = service
        self.addServiceCount += 1
    }
    
    func remove(_ service: CBMutableServiceInjectable) {
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
public class CBMutableServiceMock : CBServiceMock, CBMutableServiceInjectable {

    func setCharacteristics(_ characteristics: [CBCharacteristicInjectable]?) {
        self.characteristics = characteristics?.map { $0 as! CBMutableCharacteristicMock }
    }
}

// MARK: - CBMutableCharacteristicMock
public class CBMutableCharacteristicMock : CBCharacteristicMock, CBMutableCharacteristicInjectable {
    var permissions: CBAttributePermissions

    init (uuid: CBUUID = CBUUID(string: Foundation.UUID().uuidString), properties: CBCharacteristicProperties = [.read, .write], permissions: CBAttributePermissions = [.readable, .writeable], isNotifying: Bool = false) {
        self.permissions = permissions
        super.init(uuid: uuid, properties: properties, isNotifying: isNotifying)
    }
}

// MARK: - PeripheralManagerUT -
public class PeripheralManagerUT : PeripheralManager {
    
    var respondToRequestCalled = false

    var error: Error?
    var result: CBATTError.Code?
    var request: CBATTRequestInjectable?
        
    public override func respondToRequest(_ request: CBATTRequestInjectable, withResult result: CBATTError.Code) {
        self.respondToRequestCalled = true
        self.result = result
        self.request = request
    }

}

// MARK: - CBATTRequestMock -
public class CBATTRequestMock : CBATTRequestInjectable {

    let characteristic: CBMutableCharacteristicInjectable
    public let offset: Int
    public var value: Data?
    
    init(characteristic: CBMutableCharacteristicInjectable, offset: Int, value: Data? = nil) {
        self.value = value
        self.characteristic = characteristic
        self.offset = offset
    }

    public func getCharacteristic() -> CBCharacteristicInjectable {
        return self.characteristic
    }

}

// MARK: - CBCentralMock -
public class CBCentralMock : CBCentralInjectable {

    public let identifier: UUID
    public let maximumUpdateValueLength: Int

    init(maximumUpdateValueLength: Int, identifier: UUID = UUID()) {
        self.identifier = identifier
        self.maximumUpdateValueLength = maximumUpdateValueLength
    }
}

// MARK: - Utilities -
public func createPeripheralManager(_ isAdvertising: Bool, state: ManagerState, stopAdvertiseFail: Bool = false) -> (CBPeripheralManagerMock, PeripheralManagerUT) {
    let mock = CBPeripheralManagerMock(isAdvertising: isAdvertising, state: state, stopAdvertiseFail: stopAdvertiseFail)
    return (mock, PeripheralManagerUT(peripheralManager:mock))
}

public func createPeripheralManagerService(_ peripheralManager: PeripheralManager) -> MutableService {
    let helloWoroldService = profileManager.services[CBUUID(string: Gnosus.HelloWorldService.uuid)]!
    let mockService = CBMutableServiceMock(uuid: CBUUID(string: Gnosus.HelloWorldService.uuid))
    let service = MutableService(cbMutableService: mockService, profile: helloWoroldService)
    service.peripheralManager = peripheralManager
    peripheralManager.configuredServices = [service.uuid: [service]]
    return service
}

public func createPeripheralManagerService() -> MutableService {
    let helloWoroldService = profileManager.services[CBUUID(string: Gnosus.HelloWorldService.uuid)]!
    let mockService = CBMutableServiceMock(uuid: CBUUID(string: Gnosus.HelloWorldService.uuid))
    let service = MutableService(cbMutableService: mockService, profile: helloWoroldService)
    return service
}

public func createDuplicatePeripheralManagerServices() -> [MutableService] {
    let helloWoroldService = profileManager.services[CBUUID(string: Gnosus.HelloWorldService.uuid)]!
    let mockService1 = CBMutableServiceMock(uuid: CBUUID(string: Gnosus.HelloWorldService.uuid))
    let mockService2 = CBMutableServiceMock(uuid: CBUUID(string: Gnosus.HelloWorldService.uuid))
    let services = [MutableService(cbMutableService: mockService1, profile: helloWoroldService),
                    MutableService(cbMutableService: mockService2, profile: helloWoroldService)]
    return services
}

public func createPeripheralManagerCharacteristic(_ service: MutableService) -> MutableCharacteristic {
    service.characteristics = service.profile.characteristics.map { profile in
        let characteristic = CBMutableCharacteristicMock(uuid: profile.uuid, properties: profile.properties, permissions: profile.permissions, isNotifying: false)
        return MutableCharacteristic(cbMutableCharacteristic: characteristic, profile: profile)
    }
    return service.characteristics[0]
}
