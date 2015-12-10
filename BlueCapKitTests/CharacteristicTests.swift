//
//  CharacteristicTests.swift
//  BlueCapKit
//
//  Created by Troy Stribling on 1/7/15.
//  Copyright (c) 2015 Troy Stribling. The MIT License (MIT).
//

import UIKit
import XCTest
import CoreBluetooth
import CoreLocation
import BlueCapKit

class CharacteristicTests: XCTestCase {
    
    var centralManager : CentralManager!
    var peripheral : Peripheral!
    var service : Service!
    let mockPerpheral = CBPeripheralMock(state:.Connected)
    let mockService = CBServiceMock(UUID:CBUUID(string:Gnosus.HelloWorldService.uuid))

    override func setUp() {
        GnosusProfiles.create()
        self.centralManager = CentralManagerUT(centralManager:CBCentralManagerMock(state:.PoweredOn))
        self.peripheral = Peripheral(cbPeripheral:self.mockPerpheral, centralManager:self.centralManager, advertisements:peripheralAdvertisements, rssi:-45)
        self.peripheral.didDiscoverServices([self.mockService], error:nil)
        self.service = self.peripheral.services.first!
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func createCharacteristic(properties:CBCharacteristicProperties, isNotifying:Bool) -> (Characteristic, CBCharacteristicMock) {
        let mockCharacteristic = CBCharacteristicMock(properties:properties, UUID:CBUUID(string:Gnosus.HelloWorldService.Greeting.uuid), isNotifying:isNotifying)
        self.peripheral.didDiscoverCharacteristicsForService(self.mockService, characteristics:[mockCharacteristic], error:nil)
        return (self.service.characteristics.first!, mockCharacteristic)
    }
    
    func testAfterDiscovered() {
        let mockCharacteristic = CBCharacteristicMock(properties:[.Read, .Write], UUID:CBUUID(string:Gnosus.HelloWorldService.Greeting.uuid), isNotifying:false)
        let service  = ServiceUT(cbService:self.mockService, peripheral:peripheral, mockCharacteristics:[mockCharacteristic], error:nil)
        let onSuccessExpectation = expectationWithDescription("onSuccess fulfilled for future")
        let serviceProfile = ProfileManager.sharedInstance.service[CBUUID(string:Gnosus.HelloWorldService.uuid)]
        let characteristicProfile = serviceProfile?.characteristic[CBUUID(string:Gnosus.HelloWorldService.Greeting.uuid)]
        characteristicProfile?.afterDiscovered(nil).onSuccess {_ in
            onSuccessExpectation.fulfill()
        }
        characteristicProfile?.afterDiscovered(nil).onFailure {error in
            XCTAssert(false, "onFailure called")
        }
        service.didDiscoverCharacteristics([mockCharacteristic], error:nil)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testWriteDataSuccess() {
        let onSuccessExpectation = expectationWithDescription("onSuccess fulfilled for future")
        let (characteristic, mockCharacteristic) = self.createCharacteristic([.Read, .Write], isNotifying:false)
        let future = characteristic.writeData("aa".dataFromHexString())
        future.onSuccess {_ in
            onSuccessExpectation.fulfill()
        }
        future.onFailure {error in
            XCTAssert(false, "onFailure called")
        }
        self.peripheral.didWriteValueForCharacteristic(mockCharacteristic, error:nil)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testWriteDataFailed() {
        let onFailureExpectation = expectationWithDescription("onFailure fulfilled for future")
        let (characteristic, mockCharacteristic) = self.createCharacteristic([.Read, .Write], isNotifying:false)
        let future = characteristic.writeData("aa".dataFromHexString())
        future.onSuccess {_ in
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure {error in
            onFailureExpectation.fulfill()
            XCTAssert(error.code == TestFailure.error.code, "Error code invalid")
        }
        self.peripheral.didWriteValueForCharacteristic(mockCharacteristic, error:TestFailure.error)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testWriteDataTimeOut() {
        let onFailureExpectation = expectationWithDescription("onFailure fulfilled for future")
        let (characteristic, _) = self.createCharacteristic([.Read, .Write], isNotifying:false)
        let future = characteristic.writeData("aa".dataFromHexString(), timeout:2.0)
        future.onSuccess {_ in
            XCTAssert(false, "onFailure called")
        }
        future.onFailure {error in
            onFailureExpectation.fulfill()
            XCTAssert(error.code == CharacteristicError.WriteTimeout.rawValue, "Error code invalid")
        }
        waitForExpectationsWithTimeout(20) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testWriteDataNotWriteable() {
        let onFailureExpectation = expectationWithDescription("onFailure fulfilled for future")
        let (characteristic, _) = self.createCharacteristic([.Read], isNotifying:false)
        let future = characteristic.writeData("aa".dataFromHexString())
        future.onSuccess {_ in
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure {error in
            onFailureExpectation.fulfill()
            XCTAssert(error.code == CharacteristicError.WriteNotSupported.rawValue, "Error code invalid")
        }
        waitForExpectationsWithTimeout(120) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testWriteStringSuccess() {
        let onSuccessExpectation = expectationWithDescription("onSuccess fulfilled for future")
        let (characteristic, mockCharacteristic) = self.createCharacteristic([.Read, .Write], isNotifying:false)
        let future = characteristic.writeString(["Hello World Greeting":"Good bye"])
        future.onSuccess {_ in
            onSuccessExpectation.fulfill()
        }
        future.onFailure {error in
            XCTAssert(false, "onFailure called")
        }
        self.peripheral.didWriteValueForCharacteristic(mockCharacteristic, error:nil)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testWriteStringNotSerializable() {
        let onFailureExpectation = expectationWithDescription("onFailure fulfilled for future")
        let (characteristic, _) = self.createCharacteristic([.Read, .Write], isNotifying:false)
        let future = characteristic.writeString(["bad name":"Invalid"])
        future.onSuccess {_ in
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure {error in
            onFailureExpectation.fulfill()
            XCTAssert(error.code == BCError.characteristicNotSerilaizable.code, "Error cod einvalid")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testWriteDataWithoutResponseSuccess() {
        let onSuccessExpectation = expectationWithDescription("onSuccess fulfilled for future")
        let (characteristic, mockCharacteristic) = self.createCharacteristic([.Read, .Write], isNotifying:false)
        let future = characteristic.writeData("aa".dataFromHexString(), type:.WithoutResponse)
        future.onSuccess {_ in
            onSuccessExpectation.fulfill()
        }
        future.onFailure {error in
            XCTAssert(false, "onFailure called")
        }
        self.peripheral.didWriteValueForCharacteristic(mockCharacteristic, error:nil)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testMultipleWritesSuccess() {
        let (characteristic, mockCharacteristic) = self.createCharacteristic([.Read, .Write], isNotifying:false)
        let onSuccessExpectation1 = expectationWithDescription("onSuccess fulfilled for future 1")
        let future1 = characteristic.writeData("aa".dataFromHexString())
        future1.onSuccess {_ in
            onSuccessExpectation1.fulfill()
        }
        future1.onFailure {error in
            XCTAssert(false, "onFailure called")
        }
        let onSuccessExpectation2 = expectationWithDescription("onSuccess fulfilled for future 2")
        let future2 = characteristic.writeData("bb".dataFromHexString())
        future2.onSuccess {_ in
            onSuccessExpectation2.fulfill()
        }
        future2.onFailure {error in
            XCTAssert(false, "onFailure called")
        }
        self.peripheral.didWriteValueForCharacteristic(mockCharacteristic, error:nil)
        self.peripheral.didWriteValueForCharacteristic(mockCharacteristic, error:nil)
        waitForExpectationsWithTimeout(10) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testReadSuccess() {
        let onSuccessExpectation = expectationWithDescription("onSuccess fulfilled for future")
        let (characteristic, mockCharacteristic) = self.createCharacteristic([.Read, .Write], isNotifying:false)
        let future = characteristic.read()
        future.onSuccess {_ in
            onSuccessExpectation.fulfill()
        }
        future.onFailure {error in
            XCTAssert(false, "onFailure called")
        }
        self.peripheral.didUpdateValueForCharacteristic(mockCharacteristic, error:nil)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testReadFailure() {
        let onFailureExpectation = expectationWithDescription("onFailure fulfilled for future")
        let (characteristic, mockCharacteristic) = self.createCharacteristic([.Read, .Write], isNotifying:false)
        let future = characteristic.read()
        future.onSuccess {_ in
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure {error in
            onFailureExpectation.fulfill()
        }
        self.peripheral.didUpdateValueForCharacteristic(mockCharacteristic, error:TestFailure.error)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testReadTimeout() {
        let onFailureExpectation = expectationWithDescription("onFailure fulfilled for future")
        let (characteristic, _) = self.createCharacteristic([.Read, .Write], isNotifying:false)
        let future = characteristic.read(2.0)
        future.onSuccess {_ in
            XCTAssert(false, "onFailure called")
        }
        future.onFailure {error in
            onFailureExpectation.fulfill()
            XCTAssert(error.code == CharacteristicError.ReadTimeout.rawValue, "Error code invalid")
        }
        waitForExpectationsWithTimeout(120) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testReadNotReadable() {
        let onFailureExpectation = expectationWithDescription("onFailure fulfilled for future")
        let (characteristic, _) = self.createCharacteristic([.Write], isNotifying:false)
        let future = characteristic.read()
        future.onSuccess {_ in
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure {error in
            onFailureExpectation.fulfill()
            XCTAssert(error.code == CharacteristicError.ReadNotSupported.rawValue, "Error code invalid")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testMultipleReadSuccess() {
        let (characteristic, mockCharacteristic) = self.createCharacteristic([.Read, .Write], isNotifying:false)
        let onSuccessExpectation1 = expectationWithDescription("onSuccess fulfilled for future 1")
        let future1 = characteristic.read()
        future1.onSuccess {_ in
            onSuccessExpectation1.fulfill()
        }
        future1.onFailure {error in
            XCTAssert(false, "onFailure called")
        }
        let onSuccessExpectation2 = expectationWithDescription("onSuccess fulfilled for future 2")
        let future2 = characteristic.read()
        future2.onSuccess {_ in
            onSuccessExpectation2.fulfill()
        }
        future2.onFailure {error in
            XCTAssert(false, "onFailure called")
        }
        self.peripheral.didUpdateValueForCharacteristic(mockCharacteristic, error:nil)
        self.peripheral.didUpdateValueForCharacteristic(mockCharacteristic, error:nil)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testStartNotifyingSuccess() {
        let onSuccessExpectation = expectationWithDescription("onSuccess fulfilled for future")
        let (characteristic, mockCharacteristic) = self.createCharacteristic([.Notify], isNotifying:false)
        let future = characteristic.startNotifying()
        future.onSuccess {_ in
            onSuccessExpectation.fulfill()
        }
        future.onFailure {error in
            XCTAssert(false, "onFailure called")
        }
        self.peripheral.didUpdateNotificationStateForCharacteristic(mockCharacteristic, error:nil)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testStartNotifyingFailure() {
        let onFailureExpectation = expectationWithDescription("onFailure fulfilled for future")
        let (characteristic, mockCharacteristic) = self.createCharacteristic([.Notify], isNotifying:false)
        let future = characteristic.startNotifying()
        future.onSuccess {_ in
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure {error in
            onFailureExpectation.fulfill()
            XCTAssert(error.code == TestFailure.error.code, "Error code invalid")
        }
        self.peripheral.didUpdateNotificationStateForCharacteristic(mockCharacteristic, error:TestFailure.error)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testStartIndicateSuccess() {
        let onSuccessExpectation = expectationWithDescription("onSuccess fulfilled for future")
        let (characteristic, mockCharacteristic) = self.createCharacteristic([.Indicate], isNotifying:false)
        let future = characteristic.startNotifying()
        future.onSuccess {_ in
            onSuccessExpectation.fulfill()
        }
        future.onFailure {error in
            XCTAssert(false, "onFailure called")
        }
        self.peripheral.didUpdateNotificationStateForCharacteristic(mockCharacteristic, error:nil)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testStartNotifyEncryptionRequiredSuccess() {
        let onSuccessExpectation = expectationWithDescription("onSuccess fulfilled for future")
        let (characteristic, mockCharacteristic) = self.createCharacteristic([.NotifyEncryptionRequired], isNotifying:false)
        let future = characteristic.startNotifying()
        future.onSuccess {_ in
            onSuccessExpectation.fulfill()
        }
        future.onFailure {error in
            XCTAssert(false, "onFailure called")
        }
        self.peripheral.didUpdateNotificationStateForCharacteristic(mockCharacteristic, error:nil)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testStartIndicateEncryptionRequiredSuccess() {
        let onSuccessExpectation = expectationWithDescription("onSuccess fulfilled for future")
        let (characteristic, mockCharacteristic) = self.createCharacteristic([.IndicateEncryptionRequired], isNotifying:false)
        let future = characteristic.startNotifying()
        future.onSuccess {_ in
            onSuccessExpectation.fulfill()
        }
        future.onFailure {error in
            XCTAssert(false, "onFailure called")
        }
        self.peripheral.didUpdateNotificationStateForCharacteristic(mockCharacteristic, error:nil)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testReceiveNotificationUpdateSuccess() {
        let (characteristic, _) = self.createCharacteristic([.IndicateEncryptionRequired], isNotifying:true)
        let startNotifyingOnSuccessExpectation = expectationWithDescription("onSuccess fulfilled for future start notifying")
        let updateOnSuccessExpectation = expectationWithDescription("onSuccess fulfilled for future on update")

        let startNotifyingFuture = characteristic.startNotifying()
        characteristic.didUpdateNotificationState(nil)
        
        startNotifyingFuture.onSuccess{_ in
            startNotifyingOnSuccessExpectation.fulfill()
        }
        startNotifyingFuture.onFailure{_ in
            XCTAssert(false, "start notifying onFailure called")
        }
        let updateFuture = startNotifyingFuture.flatmap{_ -> FutureStream<Characteristic> in
            let future = characteristic.recieveNotificationUpdates()
            characteristic.didUpdate(nil)
            return future
        }
        updateFuture.onSuccess {characteristic in
            updateOnSuccessExpectation.fulfill()
        }
        updateFuture.onFailure {error in
            XCTAssert(false, "update onFailure called")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testReceiveNotificationUpdateFailure() {
        let (characteristic, _) = self.createCharacteristic([.IndicateEncryptionRequired], isNotifying:true)
        let startNotifyingOnSuccessExpectation = expectationWithDescription("onSuccess fulfilled for future start notifying")
        let updateOnFailureExpectation = expectationWithDescription("onSuccess fulfilled for future on update")
        
        let startNotifyingFuture = characteristic.startNotifying()
        characteristic.didUpdateNotificationState(nil)
        
        startNotifyingFuture.onSuccess{_ in
            startNotifyingOnSuccessExpectation.fulfill()
        }
        startNotifyingFuture.onFailure{_ in
            XCTAssert(false, "start notifying onFailure called")
        }
        let updateFuture = startNotifyingFuture.flatmap{_ -> FutureStream<Characteristic> in
            let future = characteristic.recieveNotificationUpdates()
            characteristic.didUpdate(TestFailure.error)
            return future
        }
        updateFuture.onSuccess {characteristic in
            XCTAssert(false, "update onSuccess called")
        }
        updateFuture.onFailure {error in
            updateOnFailureExpectation.fulfill()
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testStopNotifyingSuccess() {
        let (characteristic, _) = self.createCharacteristic([.IndicateEncryptionRequired], isNotifying:true)
        let onSuccessExpectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = characteristic.stopNotifying()
        future.onSuccess {_ in
            onSuccessExpectation.fulfill()
        }
        future.onFailure {error in
            XCTAssert(false, "onFailure called")
        }
        characteristic.didUpdateNotificationState(nil)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testStopNotifyingFailure() {
        let (characteristic, _) = self.createCharacteristic([.IndicateEncryptionRequired], isNotifying:true)
        let onFailureExpectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = characteristic.stopNotifying()
        future.onSuccess {_ in
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure {error in
            onFailureExpectation.fulfill()
        }
        characteristic.didUpdateNotificationState(TestFailure.error)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testStopNotificationUpdates() {
        let (characteristic, _) = self.createCharacteristic([.IndicateEncryptionRequired], isNotifying:true)
        let startNotifyingOnSuccessExpectation = expectationWithDescription("onSuccess fulfilled for future start notifying")
        let updateOnSuccessExpectation = expectationWithDescription("onSuccess fulfilled for future on update")

        var updates = 0
        let startNotifyingFuture = characteristic.startNotifying()
        characteristic.didUpdateNotificationState(nil)
        
        startNotifyingFuture.onSuccess{_ in
            startNotifyingOnSuccessExpectation.fulfill()
        }
        startNotifyingFuture.onFailure{_ in
            XCTAssert(false, "start notifying onFailure called")
        }
        let updateFuture = startNotifyingFuture.flatmap{_ -> FutureStream<Characteristic> in
            let future = characteristic.recieveNotificationUpdates()
            characteristic.didUpdate(nil)
            characteristic.stopNotificationUpdates()
            characteristic.didUpdate(nil)
            return future
        }
        updateFuture.onSuccess {characteristic in
            if updates == 0 {
                updateOnSuccessExpectation.fulfill()
                ++updates
            } else {
                XCTAssert(false, "update onSuccess called more than once")
            }
        }
        updateFuture.onFailure {error in
            XCTAssert(false, "update onFailure called")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
}
