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

class CBPeripheralMock : CBPeripheralWrappable {
   
    var state : CBPeripheralState
    var writeValueData : NSData?
    var setNotifyState : Bool?

    var _delegate : CBPeripheralDelegate?   = nil
    
    var setDelegateCalled                   = false
    var discoverServicesCalled              = false
    var discoverCharacteristicsCalled       = false
    var setNotifyValueCalled                = false
    var readValueForCharacteristicCalled    = false
    var writeValueCalled                    = false
    
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
    }
    
    func discoverCharacteristics(characteristics:[CBUUID]?, forService:CBService) {
        self.discoverCharacteristicsCalled = true
    }
    
    func setNotifyValue(state:Bool, forCharacteristic:CBCharacteristic) {
        self.setNotifyValueCalled = true
        self.setNotifyState = state
    }
    
    func readValueForCharacteristic(characteristic:CBCharacteristic) {
        self.readValueForCharacteristicCalled = true
    }
    
    func writeValue(data:NSData, forCharacteristic:CBCharacteristic, type:CBCharacteristicWriteType) {
        self.writeValueCalled = true
        self.writeValueData = data
    }

}

struct CBServiceMock : CBServiceWrappable {
    
    let UUID : CBUUID
    
    var characteristics : [CBCharacteristic]? {
        return nil
    }
    
    init(UUID:CBUUID = CBUUID(string:"2f0a0017-69aa-f316-3e78-4194989a6ccc")) {
        self.UUID = UUID
    }
    
}

//final class CharacteristicMock : CharacteristicWrappable {
//    
//    var _isNotifying             = false
//    var _stringValues            = [String]()
//    var _propertyEnabled         = true
//    var _stringValue             = ["Mock":"1"]
//    var _dataFromStringValue     = "01".dataFromHexString()
//    var _afterDiscoveredPromise  = StreamPromise<CharacteristicMock>()
//    
//    let impl = CharacteristicImpl<CharacteristicMock>()
//    
//    var uuid : CBUUID {
//        return CBUUID(string:"2f0a0017-69aa-f316-3e78-4194989a6c1a")
//    }
//    
//    init (propertyEnabled:Bool = true) {
//        self._propertyEnabled = propertyEnabled
//    }
//    
//    var name : String {
//        return "Mock"
//    }
//    
//    var isNotifying : Bool {
//        return self._isNotifying
//    }
//    
//    var stringValues : [String] {
//        return self._stringValues
//    }
//    
//    var afterDiscoveredPromise  : StreamPromise<CharacteristicMock>? {
//        return self._afterDiscoveredPromise
//    }
//    
//    func stringValue(data:NSData?) -> [String:String]? {
//        return self._stringValue
//    }
//    
//    func dataFromStringValue(stringValue:[String:String]) -> NSData? {
//        return self._dataFromStringValue
//    }
//    
//    func setNotifyValue(state:Bool) {
//        self._isNotifying = state
//    }
//    
//    func propertyEnabled(property:CBCharacteristicProperties) -> Bool {
//        return self._propertyEnabled
//    }
//    
//    func readValueForCharacteristic() {
//    }
//    
//    func writeValue(value:NSData) {
//    }
//}
//
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

