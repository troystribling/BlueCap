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
import BlueCapKit

struct TestFailure {
    static let error = NSError(domain:"BlueCapKit Tests", code:100, userInfo:[NSLocalizedDescriptionKey:"Testing"])
}

let peripheralAdvertisements = [CBAdvertisementDataLocalNameKey:"Test Peripheral",
                                CBAdvertisementDataTxPowerLevelKey:NSNumber(integer:-45)]

class CBCentralManagerMock : CBCentralManagerWrappable {
    
    var state : CBCentralManagerState
    var scanForPeripheralsWithServicesCalled = false
    var stopScanCalled = false
    
    init(state:CBCentralManagerState = .PoweredOn) {
        self.state = state
    }
    
    func scanForPeripheralsWithServices(uuids:[CBUUID]?, options:[String:AnyObject]?) {
        self.scanForPeripheralsWithServicesCalled = true
    }
    
    func stopScan() {
        self.stopScanCalled = true
    }
    
    func connectPeripheral(peripheral:CBPeripheral, options:[String:AnyObject]?) {
    }
    
    func cancelPeripheralConnection(peripheral:CBPeripheral) {
    }
    
}

class CentralManagerUT : CentralManager {
    
    override func connectPeripheral(peripheral:Peripheral, options:[String:AnyObject]? = nil) {
    }
    
    override func cancelPeripheralConnection(peripheral:Peripheral) {
        peripheral.didDisconnectPeripheral()
    }

}

class CBPeripheralMock : CBPeripheralWrappable {
   
    var state : CBPeripheralState

    var _delegate : CBPeripheralDelegate?   = nil
    
    var setDelegateCalled                       = false
    var discoverServicesCalled                  = false
    var discoverCharacteristicsCalled           = false
    
    var discoverServicesCalledCount         = 0
    var discoverCharacteristicsCalledCount  = 0
    
    let identifier                          = NSUUID()

    init(state:CBPeripheralState = .Disconnected) {
        self.state = state
    }
    
    var delegate : CBPeripheralDelegate? {
        get {
            return self._delegate
        }
        set {
            self._delegate = newValue
            self.setDelegateCalled = self._delegate == nil ? false : true
        }
    }
    
    var name : String? {
        return "Test Peripheral"
    }

    var services : [CBService]? {
        return nil
    }
    
    func discoverServices(services:[CBUUID]?) {
        self.discoverServicesCalled = true
        self.discoverServicesCalledCount++
    }
    
    func discoverCharacteristics(characteristics:[CBUUID]?, forService:CBService) {
        self.discoverCharacteristicsCalled = true
        self.discoverCharacteristicsCalledCount++
    }
    
    func setNotifyValue(state:Bool, forCharacteristic:CBCharacteristic) {
    }
    
    func readValueForCharacteristic(characteristic:CBCharacteristic) {
    }
    
    func writeValue(data:NSData, forCharacteristic:CBCharacteristic, type:CBCharacteristicWriteType) {
    }

}

class PeripheralUT : Peripheral {
    
    let error:NSError?
    
    init(cbPeripheral:CBPeripheralWrappable, centralManager:CentralManager, advertisements:[String:AnyObject], rssi:Int, error:NSError?) {
        self.error = error
        super.init(cbPeripheral:cbPeripheral, centralManager:centralManager, advertisements:advertisements, rssi:rssi)
    }
    
    override func discoverService(head:Service, tail:[Service], promise:Promise<Peripheral>) {
        if let error = self.error {
            promise.failure(error)
        } else {
            promise.success(self)
            
        }
    }

}

class CBServiceMock : CBServiceWrappable {
    
    let UUID : CBUUID
    
    var characteristics : [CBCharacteristic]? {
        return nil
    }
    
    init(UUID:CBUUID = CBUUID(string:"2f0a0017-69aa-f316-3e78-4194989a6ccc")) {
        self.UUID = UUID
    }
    
}

class ServiceUT : Service {
    
    let error : NSError?
    
    let mockCharacteristics : [CBCharacteristicWrappable]
    
    init(cbService:CBServiceWrappable, peripheral:Peripheral, mockCharacteristics:[CBCharacteristicWrappable], error:NSError?) {
        self.mockCharacteristics = mockCharacteristics
        self.error = error
        super.init(cbService:cbService, peripheral:peripheral)
    }
    
    override func discoverAllCharacteristics() -> Future<Service> {
        self.didDiscoverCharacteristics(self.mockCharacteristics, error:self.error)
        return self.characteristicsDiscoveredPromise.future
    }
}

class CBCharacteristicMock : CBCharacteristicWrappable {
    
    let UUID : CBUUID
    let properties : CBCharacteristicProperties

    var isNotifying : Bool
    var value : NSData?

    init (properties:CBCharacteristicProperties, UUID:CBUUID, isNotifying:Bool) {
        self.properties = properties
        self.UUID = UUID
        self.isNotifying = isNotifying
    }
    
}

//class TimedScanneratorMock : TimedScanneratorWrappable {
//    
//    let impl = TimedScanneratorImpl<TimedScanneratorMock>()
//    
//    var promise     = StreamPromise<PeripheralMock>()
//    var _perpherals : [PeripheralMock]
//    
//    var peripherals : [PeripheralMock] {
//        return self._perpherals
//    }
//    
//    init(peripherals:[PeripheralMock] = [PeripheralMock]()) {
//        self._perpherals = peripherals
//    }
//    
//    func startScanning(capacity:Int?) -> FutureStream<PeripheralMock> {
//        return self.startScanningForServiceUUIDs(nil, capacity:capacity)
//    }
//    
//    func startScanningForServiceUUIDs(uuids:[CBUUID]!, capacity:Int?) -> FutureStream<PeripheralMock> {
//        return self.promise.future
//    }
//    
//    func wrappedStopScanning() {
//    }
//    
//    func timeout() {
//        self.promise.failure(BCError.peripheralDiscoveryTimeout)
//    }
//    
//    func didDiscoverPeripheral(peripheral:PeripheralMock) {
//        self._perpherals.append(peripheral)
//        self.promise.success(peripheral)
//    }
//    
//}

