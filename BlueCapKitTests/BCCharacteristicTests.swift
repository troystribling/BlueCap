//
//  BCCharacteristicTests.swift
//  BlueCapKit
//
//  Created by Troy Stribling on 1/7/15.
//  Copyright (c) 2015 Troy Stribling. The MIT License (MIT).
//

import UIKit
import XCTest
import CoreBluetooth
@testable import BlueCapKit

// MARK: - BCCharacteristicTests -
class BCCharacteristicTests: XCTestCase {
    
    var centralManager: BCCentralManager!
    var peripheral: BCPeripheral!
    var service: BCService!
    let mockPerpheral = CBPeripheralMock(state: .Connected)
    let mockService = CBServiceMock(UUID: CBUUID(string: Gnosus.HelloWorldService.UUID))
    let RSSI = -45

    override func setUp() {
        self.centralManager = CentralManagerUT(centralManager: CBCentralManagerMock(state: .PoweredOn))
        self.peripheral = BCPeripheral(cbPeripheral: self.mockPerpheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI)
        self.peripheral.didDiscoverServices([self.mockService], error:nil)
        self.service = self.peripheral.services.first!
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func createCharacteristic(properties: CBCharacteristicProperties, isNotifying:Bool) -> (BCCharacteristic, CBCharacteristicMock) {
        let mockCharacteristic = CBCharacteristicMock(UUID: CBUUID(string: Gnosus.HelloWorldService.Greeting.UUID), properties: properties, isNotifying: isNotifying)
        self.peripheral.didDiscoverCharacteristicsForService(self.mockService, characteristics: [mockCharacteristic], error: nil)
        return (self.service.characteristics.first!, mockCharacteristic)
    }

    // MARK: Write data
    func testWriteDataSuccess() {
        let onSuccessExpectation = expectationWithDescription("onSuccess fulfilled for future")
        let (characteristic, mockCharacteristic) = self.createCharacteristic([.Read, .Write], isNotifying:false)
        let future = characteristic.writeData("aa".dataFromHexString())
        future.onSuccess { _ in
            onSuccessExpectation.fulfill()
            XCTAssert(self.mockPerpheral.writeValueCalled, "writeValue not called")
            XCTAssertEqual(self.mockPerpheral.writeValueCount, 1, "writeValue not called 1 time")
            XCTAssertEqual(self.mockPerpheral.writtenType, .WithResponse, "writtenType is invalid")
            if let data = self.mockPerpheral.writtenData {
                XCTAssertEqual(data, "aa".dataFromHexString(), "writeValue data is invalid")
            } else {
                XCTAssert(false, "writeValue no data available")
            }
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
            XCTAssertEqual(error.code, TestFailure.error.code, "Error code invalid")
            XCTAssert(self.mockPerpheral.writeValueCalled, "writeValue not called")
            XCTAssertEqual(self.mockPerpheral.writeValueCount, 1, "writeValue called more than once")
            XCTAssertEqual(self.mockPerpheral.writtenType, .WithResponse, "writtenType is invalid")
            if let data = self.mockPerpheral.writtenData {
                XCTAssertEqual(data, "aa".dataFromHexString(), "writeValue data is invalid")
            } else {
                XCTAssert(false, "writeValue no data available")
            }
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
            XCTAssertEqual(error.code, BCCharacteristicErrorCode.WriteTimeout.rawValue, "Error code invalid")
            XCTAssert(self.mockPerpheral.writeValueCalled, "writeValue not called")
            XCTAssertEqual(self.mockPerpheral.writeValueCount, 1, "writeValue called more than once")
            XCTAssertEqual(self.mockPerpheral.writtenType, .WithResponse, "writtenType is invalid")
            if let data = self.mockPerpheral.writtenData {
                XCTAssert(data.isEqualToData("aa".dataFromHexString()), "writeValue data is invalid")
            } else {
                XCTAssert(false, "writeValue no data available")
            }
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
            XCTAssertEqual(error.code, BCCharacteristicErrorCode.WriteNotSupported.rawValue, "Error code invalid")
            XCTAssertFalse(self.mockPerpheral.writeValueCalled, "writeValue called")
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
            XCTAssert(self.mockPerpheral.writeValueCalled, "writeValue not called")
            XCTAssertEqual(self.mockPerpheral.writeValueCount, 1, "writeValue called more than once")
            XCTAssertEqual(self.mockPerpheral.writtenType, .WithResponse, "writtenType is invalid")
            if let data = self.mockPerpheral.writtenData, result = NSData.fromString("Good bye") {
                XCTAssertEqual(data, result, "writeValue data is invalid")
            } else {
                XCTAssert(false, "writeValue no data available")
            }
        }
        future.onFailure {error in
            XCTFail("onFailure called")
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
            XCTAssertFalse(self.mockPerpheral.writeValueCalled, "writeValue called")
            XCTAssertEqual(error.code, BCError.characteristicNotSerilaizable.code, "Error code invalid")
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
            XCTAssert(self.mockPerpheral.writeValueCalled, "writeValue not called")
            XCTAssertEqual(self.mockPerpheral.writeValueCount, 1, "writeValue not called 1 time")
            XCTAssertEqual(self.mockPerpheral.writtenType, .WithoutResponse, "writtenType is invalid")
            if let data = self.mockPerpheral.writtenData {
                XCTAssertEqual(data, "aa".dataFromHexString(), "writeValue data is invalid")
            } else {
                XCTAssert(false, "writeValue no data available")
            }
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
        let onSuccessExpectation2 = expectationWithDescription("onSuccess fulfilled for future 2")
        let onSuccessExpectation3 = expectationWithDescription("onSuccess fulfilled for future 3")
        let future1 = characteristic.writeData("aa".dataFromHexString())
        let future2 = characteristic.writeData("bb".dataFromHexString())
        let future3 = characteristic.writeData("cc".dataFromHexString())
        let context = ImmediateContext()
        future1.onSuccess(context) {_ in
            onSuccessExpectation1.fulfill()
            XCTAssert(self.mockPerpheral.writeValueCalled, "writeValue not called")
            XCTAssertEqual(self.mockPerpheral.writeValueCount, 1, "writeValue not called 2 times")
            XCTAssertEqual(self.mockPerpheral.writtenType, .WithResponse, "writtenType is invalid")
            if let data = self.mockPerpheral.writtenData {
                XCTAssertEqual(data, "aa".dataFromHexString())
           } else {
                XCTAssert(false, "writeValue no data available")
            }
        }
        future1.onFailure(context) {error in
            XCTAssert(false, "onFailure called")
        }
        future2.onSuccess(context) {_ in
            onSuccessExpectation2.fulfill()
            XCTAssert(self.mockPerpheral.writeValueCalled, "writeValue not called")
            XCTAssertEqual(self.mockPerpheral.writeValueCount, 2, "writeValue not called 3 times")
            XCTAssertEqual(self.mockPerpheral.writtenType, .WithResponse, "writtenType is invalid")
            if let data = self.mockPerpheral.writtenData {
                XCTAssertEqual(data, "bb".dataFromHexString())
            } else {
                XCTAssert(false, "writeValue no data available")
            }
        }
        future2.onFailure(context) {error in
            XCTAssert(false, "onFailure called")
        }
        future3.onSuccess(context) {_ in
            onSuccessExpectation3.fulfill()
            XCTAssert(self.mockPerpheral.writeValueCalled, "writeValue not called")
            XCTAssertEqual(self.mockPerpheral.writeValueCount, 3, "writeValue not called 3 times")
            XCTAssertEqual(self.mockPerpheral.writtenType, .WithResponse, "writtenType is invalid")
            if let data = self.mockPerpheral.writtenData {
                XCTAssertEqual(data, "cc".dataFromHexString())
            } else {
                XCTAssert(false, "writeValue no data available")
            }
        }
        future3.onFailure(context) {error in
            XCTAssert(false, "onFailure called")
        }
        self.peripheral.didWriteValueForCharacteristic(mockCharacteristic, error:nil)
        self.peripheral.didWriteValueForCharacteristic(mockCharacteristic, error:nil)
        self.peripheral.didWriteValueForCharacteristic(mockCharacteristic, error:nil)
        waitForExpectationsWithTimeout(10) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    // MARK: Read data
    func testReadSuccess() {
        let onSuccessExpectation = expectationWithDescription("onSuccess fulfilled for future")
        let (characteristic, mockCharacteristic) = self.createCharacteristic([.Read, .Write], isNotifying:false)
        let future = characteristic.read()
        future.onSuccess {_ in
            onSuccessExpectation.fulfill()
            XCTAssert(self.mockPerpheral.readValueForCharacteristicCalled, "readValueForCharacteristic not called")
            XCTAssertEqual(self.mockPerpheral.readValueForCharacteristicCount, 1, "readValue not called 1 time")
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
            XCTAssert(self.mockPerpheral.readValueForCharacteristicCalled, "readValueForCharacteristic not called")
            XCTAssertEqual(self.mockPerpheral.readValueForCharacteristicCount, 1, "readValue not called 1 time")
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
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure {error in
            onFailureExpectation.fulfill()
            XCTAssert(self.mockPerpheral.readValueForCharacteristicCalled, "readValueForCharacteristic not called")
            XCTAssertEqual(error.code, BCCharacteristicErrorCode.ReadTimeout.rawValue, "Error code invalid")
            XCTAssertEqual(self.mockPerpheral.readValueForCharacteristicCount, 1, "readValue not called 1 time")
        }
        waitForExpectationsWithTimeout(300) {error in
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
            XCTAssertFalse(self.mockPerpheral.readValueForCharacteristicCalled, "readValueForCharacteristic called")
            XCTAssertEqual(error.code, BCCharacteristicErrorCode.ReadNotSupported.rawValue, "Error code invalid")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testMultipleReadSuccess() {
        let (characteristic, mockCharacteristic) = self.createCharacteristic([.Read, .Write], isNotifying:false)
        let onSuccessExpectation1 = expectationWithDescription("onSuccess fulfilled for future 1")
        let onSuccessExpectation2 = expectationWithDescription("onSuccess fulfilled for future 2")
        let onSuccessExpectation3 = expectationWithDescription("onSuccess fulfilled for future 3")
        let future1 = characteristic.read()
        let future2 = characteristic.read()
        let future3 = characteristic.read()
        let context = ImmediateContext()
        future1.onSuccess(context) {_ in
            onSuccessExpectation1.fulfill()
            XCTAssert(self.mockPerpheral.readValueForCharacteristicCalled, "readValueForCharacteristic not called")
            XCTAssertEqual(self.mockPerpheral.readValueForCharacteristicCount, 1, "readValue not called 2 times")
        }
        future1.onFailure(context) {error in
            XCTAssert(false, "onFailure called")
        }
        future2.onSuccess(context) {_ in
            onSuccessExpectation2.fulfill()
            XCTAssert(self.mockPerpheral.readValueForCharacteristicCalled, "readValueForCharacteristic not called")
            XCTAssertEqual(self.mockPerpheral.readValueForCharacteristicCount, 2, "readValue not called 3 times")
        }
        future2.onFailure(context) {error in
            XCTAssert(false, "onFailure called")
        }
        future3.onSuccess(context) {_ in
            onSuccessExpectation3.fulfill()
            XCTAssert(self.mockPerpheral.readValueForCharacteristicCalled, "readValueForCharacteristic not called")
            XCTAssertEqual(self.mockPerpheral.readValueForCharacteristicCount, 3, "readValue not called 3 times")
        }
        future3.onFailure(context) {error in
            XCTAssert(false, "onFailure called")
        }
        self.peripheral.didUpdateValueForCharacteristic(mockCharacteristic, error:nil)
        self.peripheral.didUpdateValueForCharacteristic(mockCharacteristic, error:nil)
        self.peripheral.didUpdateValueForCharacteristic(mockCharacteristic, error:nil)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    // MARK: Notifications
    func testStartNotifyingSuccess() {
        let onSuccessExpectation = expectationWithDescription("onSuccess fulfilled for future")
        let (characteristic, mockCharacteristic) = self.createCharacteristic([.Notify], isNotifying:false)
        let future = characteristic.startNotifying()
        future.onSuccess {_ in
            onSuccessExpectation.fulfill()
            XCTAssert(self.mockPerpheral.setNotifyValueCalled, "setNotifyValue not called")
            XCTAssertEqual(self.mockPerpheral.setNotifyValueCount, 1, "setNotifyValueCount not called 1 time")
            if let state = self.mockPerpheral.notifyingState {
                XCTAssert(state, "setNotifyValue state not true")
            } else {
                XCTAssert(false, "setNotifyValue state not set")
            }
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
            XCTAssert(self.mockPerpheral.setNotifyValueCalled, "setNotifyValue not called")
            XCTAssertEqual(error.code, TestFailure.error.code, "Error code invalid")
            XCTAssertEqual(self.mockPerpheral.setNotifyValueCount, 1, "setNotifyValueCount not called 1 time")
            if let state = self.mockPerpheral.notifyingState {
                XCTAssert(state, "setNotifyValue state not true")
            } else {
                XCTAssert(false, "setNotifyValue state not set")
            }
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
            XCTAssert(self.mockPerpheral.setNotifyValueCalled, "setNotifyValue not called")
            XCTAssertEqual(self.mockPerpheral.setNotifyValueCount, 1, "setNotifyValueCount not called 1 time")
            if let state = self.mockPerpheral.notifyingState {
                XCTAssert(state, "setNotifyValue state not true")
            } else {
                XCTAssert(false, "setNotifyValue state not set")
            }
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
            XCTAssert(self.mockPerpheral.setNotifyValueCalled, "setNotifyValue not called")
            XCTAssertEqual(self.mockPerpheral.setNotifyValueCount, 1, "setNotifyValueCount not called 1 time")
            if let state = self.mockPerpheral.notifyingState {
                XCTAssert(state, "setNotifyValue state not true")
            } else {
                XCTAssert(false, "setNotifyValue state not set")
            }
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
            XCTAssert(self.mockPerpheral.setNotifyValueCalled, "setNotifyValue not called")
            XCTAssertEqual(self.mockPerpheral.setNotifyValueCount, 1, "setNotifyValueCount not called 1 time")
            if let state = self.mockPerpheral.notifyingState {
                XCTAssert(state, "setNotifyValue state not true")
            } else {
                XCTAssert(false, "setNotifyValue state not set")
            }
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
        let (characteristic, mockCharacteristic) = self.createCharacteristic([.Notify], isNotifying:true)
        let startNotifyingOnSuccessExpectation = expectationWithDescription("onSuccess fulfilled for future start notifying")
        let updateOnSuccessExpectation = expectationWithDescription("onSuccess fulfilled for future on update")

        let startNotifyingFuture = characteristic.startNotifying()
        startNotifyingFuture.onSuccess{_ in
            startNotifyingOnSuccessExpectation.fulfill()
        }
        startNotifyingFuture.onFailure {_ in
            XCTAssert(false, "start notifying onFailure called")
        }
        self.peripheral.didUpdateNotificationStateForCharacteristic(mockCharacteristic, error:nil)

        let updateFuture = startNotifyingFuture.flatmap{ _ -> FutureStream<(characteristic: BCCharacteristic, data: NSData?)> in
            let future = characteristic.receiveNotificationUpdates()
            mockCharacteristic.value = "11".dataFromHexString()
            self.peripheral.didUpdateValueForCharacteristic(mockCharacteristic, error:nil)
            return future
        }
        updateFuture.onSuccess {(_, data) in
            updateOnSuccessExpectation.fulfill()
            if let data = data {
                XCTAssertEqual(data, "11".dataFromHexString(), "characteristic value invalid")
            } else {
                XCTAssert(false, "characteristic value not set")
            }
        }
        updateFuture.onFailure {error in
            XCTAssert(false, "update onFailure called")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testReceiveMultipleNotificationUpdateSuccess() {
        let (characteristic, mockCharacteristic) = self.createCharacteristic([.Notify], isNotifying:true)
        let startNotifyingOnSuccessExpectation = expectationWithDescription("onSuccess fulfilled for future start notifying")
        let updateOnSuccessExpectation = expectationWithDescription("onSuccess fulfilled for future on update")

        var updates = 0
        
        let startNotifyingFuture = characteristic.startNotifying()
        startNotifyingFuture.onSuccess{_ in
            startNotifyingOnSuccessExpectation.fulfill()
        }
        startNotifyingFuture.onFailure {_ in
            XCTAssert(false, "start notifying onFailure called")
        }
        self.peripheral.didUpdateNotificationStateForCharacteristic(mockCharacteristic, error:nil)
        
        let updateFuture = startNotifyingFuture.flatmap{ _ -> FutureStream<(characteristic: BCCharacteristic, data: NSData?)> in
            let future = characteristic.receiveNotificationUpdates()
            mockCharacteristic.value = "00".dataFromHexString()
            self.peripheral.didUpdateValueForCharacteristic(mockCharacteristic, error:nil)
            mockCharacteristic.value = "01".dataFromHexString()
            self.peripheral.didUpdateValueForCharacteristic(mockCharacteristic, error:nil)
            mockCharacteristic.value = "02".dataFromHexString()
            self.peripheral.didUpdateValueForCharacteristic(mockCharacteristic, error:nil)
            mockCharacteristic.value = "03".dataFromHexString()
            self.peripheral.didUpdateValueForCharacteristic(mockCharacteristic, error:nil)
            mockCharacteristic.value = "04".dataFromHexString()
            self.peripheral.didUpdateValueForCharacteristic(mockCharacteristic, error:nil)
            mockCharacteristic.value = "05".dataFromHexString()
            self.peripheral.didUpdateValueForCharacteristic(mockCharacteristic, error:nil)
            return future
        }
        updateFuture.onSuccess {(_, data) in
            if updates == 0 {
                updateOnSuccessExpectation.fulfill()
            }
            if let data = data {
                XCTAssertEqual(data, "0\(updates)".dataFromHexString(), "characteristic value invalid")
            } else {
                XCTAssert(false, "characteristic value not set")
            }
            updates += 1
        }
        updateFuture.onFailure {error in
            XCTAssert(false, "update onFailure called")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testStopNotifyingSuccess() {
        let (characteristic, mockCharacteristic) = self.createCharacteristic([.Notify], isNotifying:true)
        let onSuccessExpectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = characteristic.stopNotifying()
        future.onSuccess {_ in
            onSuccessExpectation.fulfill()
            XCTAssert(self.mockPerpheral.setNotifyValueCalled, "setNotifyValue not called")
            XCTAssertEqual(self.mockPerpheral.setNotifyValueCount, 1, "setNotifyValueCount not called 1 time")
            if let state = self.mockPerpheral.notifyingState {
                XCTAssertFalse(state, "setNotifyValue state not true")
            } else {
                XCTAssert(false, "setNotifyValue state not set")
            }
        }
        future.onFailure {error in
            XCTAssert(false, "onFailure called")
        }
        self.peripheral.didUpdateNotificationStateForCharacteristic(mockCharacteristic, error:nil)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testStopNotifyingFailure() {
        let (characteristic, mockCharacteristic) = self.createCharacteristic([.Notify], isNotifying:true)
        let onFailureExpectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = characteristic.stopNotifying()
        future.onSuccess {_ in
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure {error in
            XCTAssert(self.mockPerpheral.setNotifyValueCalled, "setNotifyValue not called")
            XCTAssertEqual(self.mockPerpheral.setNotifyValueCount, 1, "setNotifyValueCount not called 1 time")
            if let state = self.mockPerpheral.notifyingState {
                XCTAssertFalse(state, "setNotifyValue state not true")
            } else {
                XCTAssert(false, "setNotifyValue state not set")
            }
            onFailureExpectation.fulfill()
        }
        self.peripheral.didUpdateNotificationStateForCharacteristic(mockCharacteristic, error:TestFailure.error)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testStopNotificationUpdates() {
        let (characteristic, mockCharacteristic) = self.createCharacteristic([.Notify], isNotifying:true)
        let startNotifyingOnSuccessExpectation = expectationWithDescription("onSuccess fulfilled for future start notifying")
        let updateOnSuccessExpectation = expectationWithDescription("onSuccess fulfilled for future on update")

        var updates = 0
        let startNotifyingFuture = characteristic.startNotifying()
        startNotifyingFuture.onSuccess{ _ in
            startNotifyingOnSuccessExpectation.fulfill()
        }
        startNotifyingFuture.onFailure { _ in
            XCTAssert(false, "start notifying onFailure called")
        }
        self.peripheral.didUpdateNotificationStateForCharacteristic(mockCharacteristic, error:nil)

        let updateFuture = startNotifyingFuture.flatmap{ _ -> FutureStream<(characteristic: BCCharacteristic, data: NSData?)> in
            let future = characteristic.receiveNotificationUpdates()
            mockCharacteristic.value = "0".dataFromHexString()
            self.peripheral.didUpdateValueForCharacteristic(mockCharacteristic, error:nil)
            characteristic.stopNotificationUpdates()
            self.peripheral.didUpdateValueForCharacteristic(mockCharacteristic, error:nil)
            return future
        }
        updateFuture.onSuccess { (_, data) in
            if updates == 0 {
                updateOnSuccessExpectation.fulfill()
                updates += 1
                if let data = data {
                    XCTAssertEqual(data, "0".dataFromHexString(), "")
                } else {
                    XCTAssert(false, "characteristic value not set")
                }
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
