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
        GnosusProfiles.create()
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
    func testWriteData_WhenWritableAndNoErrorInAck_CompletesSuccessfilly() {
        let expectation = expectationWithDescription("expectation fulfilled for future")
        let (characteristic, mockCharacteristic) = self.createCharacteristic([.Read, .Write], isNotifying: false)
        let future = characteristic.writeData("aa".dataFromHexString(), timeout: 120.0)
        future.onSuccess { _ in
            expectation.fulfill()
            XCTAssert(self.mockPerpheral.writeValueCalled, "writeValue not called")
            XCTAssertEqual(self.mockPerpheral.writeValueCount, 1, "writeValue not called 1 time")
            XCTAssertEqual(self.mockPerpheral.writtenType, .WithResponse, "writtenType is invalid")
            if let data = self.mockPerpheral.writtenData {
                XCTAssertEqual(data, "aa".dataFromHexString(), "writeValue data is invalid")
            } else {
                XCTFail("writeValue no data available")
            }
        }
        future.onFailure { error in
            expectation.fulfill()
            XCTFail("onFailure called")
        }
        self.peripheral.didWriteValueForCharacteristic(mockCharacteristic, error :nil)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testWriteData_WhenWritableAndErrorInAck_CompletesWithAckError() {
        let expectation = expectationWithDescription("expectation fulfilled for future")
        let (characteristic, mockCharacteristic) = self.createCharacteristic([.Read, .Write], isNotifying: false)
        let future = characteristic.writeData("aa".dataFromHexString(), timeout: 120.0)
        future.onSuccess { _ in
            expectation.fulfill()
            XCTFail("onSuccess called")
        }
        future.onFailure { error in
            expectation.fulfill()
            XCTAssertEqual(error.code, TestFailure.error.code, "Error code invalid")
            XCTAssert(self.mockPerpheral.writeValueCalled, "writeValue not called")
            XCTAssertEqual(self.mockPerpheral.writeValueCount, 1, "writeValue called more than once")
            XCTAssertEqual(self.mockPerpheral.writtenType, .WithResponse, "writtenType is invalid")
            if let data = self.mockPerpheral.writtenData {
                XCTAssertEqual(data, "aa".dataFromHexString(), "writeValue data is invalid")
            } else {
                XCTFail("writeValue no data available")
            }
        }
        self.peripheral.didWriteValueForCharacteristic(mockCharacteristic, error:TestFailure.error)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testWriteData_WhenWritableAndNoAckReceivedBeforeTimeout_CompletesWithTimeoutError() {
        let expectation = expectationWithDescription("expectation fulfilled for future")
        let (characteristic, _) = self.createCharacteristic([.Read, .Write], isNotifying: false)
        let future = characteristic.writeData("aa".dataFromHexString(), timeout:1.0)
        future.onSuccess { _ in
            XCTFail("onFailure called")
        }
        future.onFailure { error in
            expectation.fulfill()
            XCTAssertEqual(error.code, BCCharacteristicErrorCode.WriteTimeout.rawValue, "Error code invalid")
            XCTAssert(self.mockPerpheral.writeValueCalled, "writeValue not called")
            XCTAssertEqual(self.mockPerpheral.writeValueCount, 1, "writeValue called more than once")
            XCTAssertEqual(self.mockPerpheral.writtenType, .WithResponse, "writtenType is invalid")
            if let data = self.mockPerpheral.writtenData {
                XCTAssert(data.isEqualToData("aa".dataFromHexString()), "writeValue data is invalid")
            } else {
                XCTFail("writeValue no data available")
            }
        }
        waitForExpectationsWithTimeout(20) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testWriteData_WhenNotWriteable_CompletesWithErrorWriteNotSupported() {
        let expectation = expectationWithDescription("expectation fulfilled for future")
        let (characteristic, _) = self.createCharacteristic([.Read], isNotifying: false)
        let future = characteristic.writeData("aa".dataFromHexString(), timeout: 120.0)
        future.onSuccess { _ in
            expectation.fulfill()
            XCTFail("onSuccess called")
        }
        future.onFailure { error in
            expectation.fulfill()
            XCTAssertEqual(error.code, BCCharacteristicErrorCode.WriteNotSupported.rawValue, "Error code invalid")
            XCTAssertFalse(self.mockPerpheral.writeValueCalled, "writeValue called")
        }
        waitForExpectationsWithTimeout(120) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testWriteString_WhenWritableAndNoErrorOnAck_CompletesSuccessfully() {
        let expectation = expectationWithDescription("expectation fulfilled for future")
        let (characteristic, mockCharacteristic) = self.createCharacteristic([.Read, .Write], isNotifying: false)
        let future = characteristic.writeString(["Hello World Greeting":"Good bye"], timeout: 120.0)
        future.onSuccess { _ in
            expectation.fulfill()
            XCTAssert(self.mockPerpheral.writeValueCalled, "writeValue not called")
            XCTAssertEqual(self.mockPerpheral.writeValueCount, 1, "writeValue called more than once")
            XCTAssertEqual(self.mockPerpheral.writtenType, .WithResponse, "writtenType is invalid")
            if let data = self.mockPerpheral.writtenData, result = NSData.fromString("Good bye") {
                XCTAssertEqual(data, result, "writeValue data is invalid")
            } else {
                XCTFail("writeValue no data available")
            }
        }
        future.onFailure { error in
            expectation.fulfill()
            XCTFail("onFailure called")
        }
        self.peripheral.didWriteValueForCharacteristic(mockCharacteristic, error:nil)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testWriteString_WhenStringIsNotSerializable_CompletesWithErrorNotSerailizable() {
        let expectation = expectationWithDescription("expectation fulfilled for future")
        let (characteristic, _) = self.createCharacteristic([.Read, .Write], isNotifying:  false)
        let future = characteristic.writeString(["bad name":"Invalid"], timeout: 120.0)
        future.onSuccess { _ in
            expectation.fulfill()
            XCTFail("onSuccess called")
        }
        future.onFailure { error in
            expectation.fulfill()
            XCTAssertFalse(self.mockPerpheral.writeValueCalled, "writeValue called")
            XCTAssertEqual(error.code, BCError.characteristicNotSerilaizable.code, "Error code invalid")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testWriteData_WhenWriteTypeIsWithoutResponseAndNoError_CompletesSuccessfilly() {
        let expectation = expectationWithDescription("expectation fulfilled for future")
        let (characteristic, mockCharacteristic) = self.createCharacteristic([.Read, .Write], isNotifying: false)
        let future = characteristic.writeData("aa".dataFromHexString(), timeout: 120.0, type: .WithoutResponse)
        future.onSuccess { _ in
            expectation.fulfill()
            XCTAssert(self.mockPerpheral.writeValueCalled, "writeValue not called")
            XCTAssertEqual(self.mockPerpheral.writeValueCount, 1, "writeValue not called 1 time")
            XCTAssertEqual(self.mockPerpheral.writtenType, .WithoutResponse, "writtenType is invalid")
            if let data = self.mockPerpheral.writtenData {
                XCTAssertEqual(data, "aa".dataFromHexString(), "writeValue data is invalid")
            } else {
                XCTFail("writeValue no data available")
            }
        }
        future.onFailure { error in
            expectation.fulfill()
            XCTFail("onFailure called")
        }
        self.peripheral.didWriteValueForCharacteristic(mockCharacteristic, error:nil)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testWriteData_WhenMultipleWritesAreMadeBeforeFirstAckIsReceived_AllCompleteSuccessfully() {
        let (characteristic, mockCharacteristic) = self.createCharacteristic([.Read, .Write], isNotifying: false)
        let expectation1 = expectationWithDescription("expectation fulfilled for future 1")
        let expectation2 = expectationWithDescription("expectation fulfilled for future 2")
        let expectation3 = expectationWithDescription("expectation fulfilled for future 3")
        let future1 = characteristic.writeData("aa".dataFromHexString(), timeout: 120.0)
        let future2 = characteristic.writeData("bb".dataFromHexString(), timeout: 120.0)
        let future3 = characteristic.writeData("cc".dataFromHexString(), timeout: 120.0)
        let context = ImmediateContext()
        future1.onSuccess(context) { _ in
            expectation1.fulfill()
            XCTAssert(self.mockPerpheral.writeValueCalled, "writeValue not called")
            XCTAssertEqual(self.mockPerpheral.writeValueCount, 1, "writeValue not called 2 times")
            XCTAssertEqual(self.mockPerpheral.writtenType, .WithResponse, "writtenType is invalid")
            if let data = self.mockPerpheral.writtenData {
                XCTAssertEqual(data, "aa".dataFromHexString())
           } else {
                XCTFail("writeValue no data available")
            }
        }
        future1.onFailure(context) { error in
            expectation1.fulfill()
            XCTFail("onFailure called")
        }
        future2.onSuccess(context) { _ in
            expectation2.fulfill()
            XCTAssert(self.mockPerpheral.writeValueCalled, "writeValue not called")
            XCTAssertEqual(self.mockPerpheral.writeValueCount, 2, "writeValue not called 3 times")
            XCTAssertEqual(self.mockPerpheral.writtenType, .WithResponse, "writtenType is invalid")
            if let data = self.mockPerpheral.writtenData {
                XCTAssertEqual(data, "bb".dataFromHexString())
            } else {
                XCTFail("writeValue no data available")
            }
        }
        future2.onFailure(context) { error in
            expectation2.fulfill()
            XCTFail("onFailure called")
        }
        future3.onSuccess(context) { _ in
            expectation3.fulfill()
            XCTAssert(self.mockPerpheral.writeValueCalled, "writeValue not called")
            XCTAssertEqual(self.mockPerpheral.writeValueCount, 3, "writeValue not called 3 times")
            XCTAssertEqual(self.mockPerpheral.writtenType, .WithResponse, "writtenType is invalid")
            if let data = self.mockPerpheral.writtenData {
                XCTAssertEqual(data, "cc".dataFromHexString())
            } else {
                XCTFail("writeValue no data available")
            }
        }
        future3.onFailure(context) {error in
            expectation3.fulfill()
            XCTFail("onFailure called")
        }
        self.peripheral.didWriteValueForCharacteristic(mockCharacteristic, error:nil)
        self.peripheral.didWriteValueForCharacteristic(mockCharacteristic, error:nil)
        self.peripheral.didWriteValueForCharacteristic(mockCharacteristic, error:nil)
        waitForExpectationsWithTimeout(10) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    // MARK: Read data
    func testRead_WhenReadableAndNoErrorInResponse_CompletesSuccessfully() {
        let expectation = expectationWithDescription("expectation fulfilled for future")
        let (characteristic, mockCharacteristic) = self.createCharacteristic([.Read, .Write], isNotifying: false)
        let future = characteristic.read(120.0)
        future.onSuccess { _ in
            expectation.fulfill()
            XCTAssert(self.mockPerpheral.readValueForCharacteristicCalled, "readValueForCharacteristic not called")
            XCTAssertEqual(self.mockPerpheral.readValueForCharacteristicCount, 1, "readValue not called 1 time")
        }
        future.onFailure { error in
            expectation.fulfill()
            XCTFail("onFailure called")
        }
        self.peripheral.didUpdateValueForCharacteristic(mockCharacteristic, error:nil)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testRead_WhenReadableAnResponseHasError_CompletesWithResponseError() {
        let expectation = expectationWithDescription("expectation fulfilled for future")
        let (characteristic, mockCharacteristic) = self.createCharacteristic([.Read, .Write], isNotifying: false)
        let future = characteristic.read(120.0)
        future.onSuccess { _ in
            expectation.fulfill()
            XCTFail("onSuccess called")
        }
        future.onFailure { error in
            expectation.fulfill()
            XCTAssert(self.mockPerpheral.readValueForCharacteristicCalled, "readValueForCharacteristic not called")
            XCTAssertEqual(self.mockPerpheral.readValueForCharacteristicCount, 1, "readValue not called 1 time")
        }
        self.peripheral.didUpdateValueForCharacteristic(mockCharacteristic, error:TestFailure.error)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testRead_WhenReadableAndNoResponsdeReceivedBeforeTimeout_CompletesWithTimeoutError() {
        let expectation = expectationWithDescription("expectation fulfilled for future")
        let (characteristic, _) = self.createCharacteristic([.Read, .Write], isNotifying: false)
        let future = characteristic.read(1.0)
        future.onSuccess { _ in
            XCTFail("onSuccess called")
            expectation.fulfill()
        }
        future.onFailure { error in
            expectation.fulfill()
            XCTAssert(self.mockPerpheral.readValueForCharacteristicCalled, "readValueForCharacteristic not called")
            XCTAssertEqual(error.code, BCCharacteristicErrorCode.ReadTimeout.rawValue, "Error code invalid")
            XCTAssertEqual(self.mockPerpheral.readValueForCharacteristicCount, 1, "readValue not called 1 time")
        }
        waitForExpectationsWithTimeout(300) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testRead_WhenNotReadable_CompletesWithReadNotSupported() {
        let expectation = expectationWithDescription("expectation fulfilled for future")
        let (characteristic, _) = self.createCharacteristic([.Write], isNotifying: false)
        let future = characteristic.read()
        future.onSuccess { _ in
            XCTFail("onSuccess called")
        }
        future.onFailure { error in
            expectation.fulfill()
            XCTAssertFalse(self.mockPerpheral.readValueForCharacteristicCalled, "readValueForCharacteristic called")
            XCTAssertEqual(error.code, BCCharacteristicErrorCode.ReadNotSupported.rawValue, "Error code invalid")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testRead_WhenMultipleReadsAreMadeBeforeFirstResponseIsReceived_AllCompleteSuccessfully() {
        let (characteristic, mockCharacteristic) = self.createCharacteristic([.Read, .Write], isNotifying: false)
        let future1 = characteristic.read()
        let future2 = characteristic.read()
        let future3 = characteristic.read()
        let context = ImmediateContext()
        future1.onSuccess(context) { _ in
            XCTAssert(self.mockPerpheral.readValueForCharacteristicCalled, "readValueForCharacteristic not called")
            XCTAssertEqual(self.mockPerpheral.readValueForCharacteristicCount, 1, "readValue not called 2 times")
        }
        future1.onFailure(context) { error in
            XCTFail("onFailure called")
        }
        future2.onSuccess(context) { _ in
            XCTAssert(self.mockPerpheral.readValueForCharacteristicCalled, "readValueForCharacteristic not called")
            XCTAssertEqual(self.mockPerpheral.readValueForCharacteristicCount, 2, "readValue not called 3 times")
        }
        future2.onFailure(context) {error in
            XCTFail("onFailure called")
        }
        future3.onSuccess(context) { _ in
            XCTAssert(self.mockPerpheral.readValueForCharacteristicCalled, "readValueForCharacteristic not called")
            XCTAssertEqual(self.mockPerpheral.readValueForCharacteristicCount, 3, "readValue not called 3 times")
        }
        future3.onFailure(context) { error in
            XCTFail("onFailure called")
        }
        self.peripheral.didUpdateValueForCharacteristic(mockCharacteristic, error:nil)
        self.peripheral.didUpdateValueForCharacteristic(mockCharacteristic, error:nil)
        self.peripheral.didUpdateValueForCharacteristic(mockCharacteristic, error:nil)
    }

    // MARK: Notifications
    func testStartNotifying_WhenNotifiableAndNoErrorOnAck_CompletesSuccessfully() {
        let expectation = expectationWithDescription("expectation fulfilled for future")
        let (characteristic, mockCharacteristic) = self.createCharacteristic([.Notify], isNotifying: false)
        let future = characteristic.startNotifying()
        future.onSuccess { _ in
            expectation.fulfill()
            XCTAssert(self.mockPerpheral.setNotifyValueCalled, "setNotifyValue not called")
            XCTAssertEqual(self.mockPerpheral.setNotifyValueCount, 1, "setNotifyValueCount not called 1 time")
            if let state = self.mockPerpheral.notifyingState {
                XCTAssert(state, "setNotifyValue state not true")
            } else {
                XCTFail("setNotifyValue state not set")
            }
        }
        future.onFailure { error in
            expectation.fulfill()
            XCTFail("onFailure called")
        }
        self.peripheral.didUpdateNotificationStateForCharacteristic(mockCharacteristic, error:nil)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testStartNotifying_WhenNotifiableAndErrorInAck_CompletesWithAckError() {
        let expectation = expectationWithDescription("expectation fulfilled for future")
        let (characteristic, mockCharacteristic) = self.createCharacteristic([.Notify], isNotifying: false)
        let future = characteristic.startNotifying()
        future.onSuccess { _ in
            expectation.fulfill()
            XCTFail("onSuccess called")
        }
        future.onFailure { error in
            expectation.fulfill()
            XCTAssert(self.mockPerpheral.setNotifyValueCalled, "setNotifyValue not called")
            XCTAssertEqual(error.code, TestFailure.error.code, "Error code invalid")
            XCTAssertEqual(self.mockPerpheral.setNotifyValueCount, 1, "setNotifyValueCount not called 1 time")
            if let state = self.mockPerpheral.notifyingState {
                XCTAssert(state, "setNotifyValue state not true")
            } else {
                XCTFail("setNotifyValue state not set")
            }
        }
        self.peripheral.didUpdateNotificationStateForCharacteristic(mockCharacteristic, error: TestFailure.error)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testStartNotifying_WhenIndicatableAndNoErrorOnAck_CompletesSuccessfully() {
        let expectation = expectationWithDescription("expectation fulfilled for future")
        let (characteristic, mockCharacteristic) = self.createCharacteristic([.Indicate], isNotifying: false)
        let future = characteristic.startNotifying()
        future.onSuccess { _ in
            expectation.fulfill()
            XCTAssert(self.mockPerpheral.setNotifyValueCalled, "setNotifyValue not called")
            XCTAssertEqual(self.mockPerpheral.setNotifyValueCount, 1, "setNotifyValueCount not called 1 time")
            if let state = self.mockPerpheral.notifyingState {
                XCTAssert(state, "setNotifyValue state not true")
            } else {
                XCTFail("setNotifyValue state not set")
            }
        }
        future.onFailure { error in
            expectation.fulfill()
            XCTFail("onFailure called")
        }
        self.peripheral.didUpdateNotificationStateForCharacteristic(mockCharacteristic, error: nil)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testStartNotify_WhenNotifyEncryptionRequiredAndNoErrorOnAck_CompletesSuccessfully() {
        let expectation = expectationWithDescription("expectation fulfilled for future")
        let (characteristic, mockCharacteristic) = self.createCharacteristic([.NotifyEncryptionRequired], isNotifying: false)
        let future = characteristic.startNotifying()
        future.onSuccess { _ in
            expectation.fulfill()
            XCTAssert(self.mockPerpheral.setNotifyValueCalled, "setNotifyValue not called")
            XCTAssertEqual(self.mockPerpheral.setNotifyValueCount, 1, "setNotifyValueCount not called 1 time")
            if let state = self.mockPerpheral.notifyingState {
                XCTAssert(state, "setNotifyValue state not true")
            } else {
                XCTFail("setNotifyValue state not set")
            }
        }
        future.onFailure { error in
            expectation.fulfill()
            XCTFail("onFailure called")
        }
        self.peripheral.didUpdateNotificationStateForCharacteristic(mockCharacteristic, error: nil)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testStartNotify_WhenIndicateEncryptionRequiredAndNoErrorOnAck_CompletesSuccessfully() {
        let expectation = expectationWithDescription("expectation fulfilled for future")
        let (characteristic, mockCharacteristic) = self.createCharacteristic([.IndicateEncryptionRequired], isNotifying: false)
        let future = characteristic.startNotifying()
        future.onSuccess { _ in
            expectation.fulfill()
            XCTAssert(self.mockPerpheral.setNotifyValueCalled, "setNotifyValue not called")
            XCTAssertEqual(self.mockPerpheral.setNotifyValueCount, 1, "setNotifyValueCount not called 1 time")
            if let state = self.mockPerpheral.notifyingState {
                XCTAssert(state, "setNotifyValue state not true")
            } else {
                XCTFail("setNotifyValue state not set")
            }
        }
        future.onFailure { error in
            expectation.fulfill()
            XCTFail("onFailure called")
        }
        self.peripheral.didUpdateNotificationStateForCharacteristic(mockCharacteristic, error: nil)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testStartNotifying_WhenNotNotifiable_CompletesWithNotifyNotSupportedError() {
        let expectation = expectationWithDescription("expectation fulfilled for future")
        let (characteristic, _) = self.createCharacteristic([], isNotifying: false)
        let future = characteristic.startNotifying()
        future.onSuccess { _ in
            expectation.fulfill()
            XCTFail("onSuccess called")
        }
        future.onFailure { error in
            expectation.fulfill()
            XCTAssertFalse(self.mockPerpheral.setNotifyValueCalled, "setNotifyValue not called")
            XCTAssertEqual(error.code, BCError.characteristicNotifyNotSupported.code, "Error code invalid")
            if let state = self.mockPerpheral.notifyingState {
                XCTAssertFalse(state, "setNotifyValue state not true")
            }
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testReceiveNotificationUpdates_WhenNotifiableAndUpdateIsReceivedWithoutError_CompletesSuccessfully() {
        let (characteristic, mockCharacteristic) = self.createCharacteristic([.Notify], isNotifying: true)
        let expectation1 = expectationWithDescription("expectation fulfilled for future 1")
        let expectation2 = expectationWithDescription("expectation fulfilled for future 2")

        let startNotifyingFuture = characteristic.startNotifying()
        startNotifyingFuture.onSuccess{_ in
            expectation1.fulfill()
        }
        startNotifyingFuture.onFailure {_ in
            expectation1.fulfill()
            XCTFail("start notifying onFailure called")
        }
        self.peripheral.didUpdateNotificationStateForCharacteristic(mockCharacteristic, error: nil)

        let updateFuture = startNotifyingFuture.flatmap{ _ -> FutureStream<(characteristic: BCCharacteristic, data: NSData?)> in
            let future = characteristic.receiveNotificationUpdates()
            mockCharacteristic.value = "11".dataFromHexString()
            self.peripheral.didUpdateValueForCharacteristic(mockCharacteristic, error: nil)
            return future
        }
        updateFuture.onSuccess { (_, data) in
            expectation2.fulfill()
            if let data = data {
                XCTAssertEqual(data, "11".dataFromHexString(), "characteristic value invalid")
            } else {
                XCTFail("characteristic value not set")
            }
        }
        updateFuture.onFailure {error in
            expectation2.fulfill()
            XCTFail("update onFailure called")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testReceiveNotificationUpdates_WhenNotifiableUpdateIsReceivedWitfError_CompletesWithReceivedError() {
        let (characteristic, mockCharacteristic) = self.createCharacteristic([.Notify], isNotifying: true)
        let expectation1 = expectationWithDescription("expectation fulfilled for future 1")
        let expectation2 = expectationWithDescription("expectation fulfilled for future 2")

        let startNotifyingFuture = characteristic.startNotifying()
        startNotifyingFuture.onSuccess{ _ in
            expectation1.fulfill()
        }
        startNotifyingFuture.onFailure { _ in
            expectation1.fulfill()
            XCTFail("start notifying onFailure called")
        }
        self.peripheral.didUpdateNotificationStateForCharacteristic(mockCharacteristic, error: nil)

        let updateFuture = startNotifyingFuture.flatmap{ _ -> FutureStream<(characteristic: BCCharacteristic, data: NSData?)> in
            let future = characteristic.receiveNotificationUpdates()
            mockCharacteristic.value = "11".dataFromHexString()
            self.peripheral.didUpdateValueForCharacteristic(mockCharacteristic, error: TestFailure.error)
            return future
        }
        updateFuture.onSuccess { (_, data) in
            expectation2.fulfill()
            XCTFail("update onSuccess called")
        }
        updateFuture.onFailure {error in
            expectation2.fulfill()
            XCTAssertEqual(error.code, TestFailure.error.code, "Error code invalid")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testReceiveNotificationUpdates_WhenNotNotifiableUpdateIsReceivedWitfError_CompletesWithNotifyNotSupported() {
        let (characteristic, _) = self.createCharacteristic([], isNotifying: true)
        let expectation = expectationWithDescription("expectation fulfilled for future")

        let future = characteristic.receiveNotificationUpdates()
        future.onSuccess {(_, data) in
            expectation.fulfill()
            XCTFail("update onFailure called")
        }
        future.onFailure {error in
            expectation.fulfill()
            XCTAssertEqual(error.code, BCError.characteristicNotifyNotSupported.code, "Error code invalid")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testReceiveNotificationUpdates_WhenNotifiableAndMultipleUpdatesAreReceivedWithoutErrot_CompletesSuccessfully() {
        let (characteristic, mockCharacteristic) = self.createCharacteristic([.Notify], isNotifying: true)
        let expectation1 = expectationWithDescription("expectation fulfilled for future 1")
        let expectation2 = expectationWithDescription("expectation fulfilled for future 2")

        var updates = 0
        
        let startNotifyingFuture = characteristic.startNotifying()
        startNotifyingFuture.onSuccess{_ in
            expectation1.fulfill()
        }
        startNotifyingFuture.onFailure {_ in
            expectation1.fulfill()
            XCTFail("start notifying onFailure called")
        }
        self.peripheral.didUpdateNotificationStateForCharacteristic(mockCharacteristic, error: nil)
        
        let updateFuture = startNotifyingFuture.flatmap{ _ -> FutureStream<(characteristic: BCCharacteristic, data: NSData?)> in
            let future = characteristic.receiveNotificationUpdates()
            mockCharacteristic.value = "00".dataFromHexString()
            self.peripheral.didUpdateValueForCharacteristic(mockCharacteristic, error: nil)
            mockCharacteristic.value = "01".dataFromHexString()
            self.peripheral.didUpdateValueForCharacteristic(mockCharacteristic, error: nil)
            mockCharacteristic.value = "02".dataFromHexString()
            self.peripheral.didUpdateValueForCharacteristic(mockCharacteristic, error: nil)
            mockCharacteristic.value = "03".dataFromHexString()
            self.peripheral.didUpdateValueForCharacteristic(mockCharacteristic, error: nil)
            mockCharacteristic.value = "04".dataFromHexString()
            self.peripheral.didUpdateValueForCharacteristic(mockCharacteristic, error: nil)
            mockCharacteristic.value = "05".dataFromHexString()
            self.peripheral.didUpdateValueForCharacteristic(mockCharacteristic, error: nil)
            return future
        }
        updateFuture.onSuccess {(_, data) in
            if updates == 0 {
                expectation2.fulfill()
            }
            if let data = data {
                XCTAssertEqual(data, "0\(updates)".dataFromHexString(), "characteristic value invalid")
            } else {
                XCTFail("characteristic value not set")
            }
            updates += 1
        }
        updateFuture.onFailure {error in
            expectation2.fulfill()
            XCTFail("update onFailure called")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testStopNotifying_WhenNotifyingAndNoErrorOnAck_CompletesSuccessfully() {
        let (characteristic, mockCharacteristic) = self.createCharacteristic([.Notify], isNotifying: true)
        let expectation = expectationWithDescription("expectation fulfilled for future")
        let future = characteristic.stopNotifying()
        future.onSuccess { _ in
            expectation.fulfill()
            XCTAssert(self.mockPerpheral.setNotifyValueCalled, "setNotifyValue not called")
            XCTAssertEqual(self.mockPerpheral.setNotifyValueCount, 1, "setNotifyValueCount not called 1 time")
            if let state = self.mockPerpheral.notifyingState {
                XCTAssertFalse(state, "setNotifyValue state not true")
            } else {
                XCTFail("setNotifyValue state not set")
            }
        }
        future.onFailure {error in
            expectation.fulfill()
            XCTFail("onFailure called")
        }
        self.peripheral.didUpdateNotificationStateForCharacteristic(mockCharacteristic, error: nil)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testStopNotifying_WhenNotifyingAndErrorOnAck_CompletesWithAckError() {
        let (characteristic, mockCharacteristic) = self.createCharacteristic([.Notify], isNotifying: true)
        let expectation = expectationWithDescription("expectation fulfilled for future")
        let future = characteristic.stopNotifying()
        future.onSuccess { _ in
            expectation.fulfill()
            XCTFail("onSuccess called")
        }
        future.onFailure { error in
            expectation.fulfill()
            XCTAssert(self.mockPerpheral.setNotifyValueCalled, "setNotifyValue not called")
            XCTAssertEqual(self.mockPerpheral.setNotifyValueCount, 1, "setNotifyValueCount not called 1 time")
            XCTAssertEqual(error.code, TestFailure.error.code, "Error code invalid")
            if let state = self.mockPerpheral.notifyingState {
                XCTAssertFalse(state, "setNotifyValue state not true")
            } else {
                XCTFail("setNotifyValue state not set")
            }
        }
        self.peripheral.didUpdateNotificationStateForCharacteristic(mockCharacteristic, error: TestFailure.error)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testStopNotifying_WhenNotNotifiable_CompletesWithNotifyNotSupported() {
        let (characteristic, _) = self.createCharacteristic([], isNotifying: true)
        let expectation = expectationWithDescription("expectation fulfilled for future")
        let future = characteristic.stopNotifying()
        future.onSuccess { _ in
            expectation.fulfill()
            XCTFail("onSuccess called")
        }
        future.onFailure {error in
            expectation.fulfill()
            XCTAssertFalse(self.mockPerpheral.setNotifyValueCalled, "setNotifyValue not called")
            XCTAssertEqual(error.code, BCError.characteristicNotifyNotSupported.code, "Error code invalid")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testStopNotifying_WhenNotifying_StopsNotificationUpdates() {
        let (characteristic, mockCharacteristic) = self.createCharacteristic([.Notify], isNotifying: true)
        let expectation1 = expectationWithDescription("expectation fulfilled for future 1")
        let expectation2 = expectationWithDescription("expectation fulfilled for future 2")

        var updates = 0
        let startNotifyingFuture = characteristic.startNotifying()
        startNotifyingFuture.onSuccess{ _ in
            expectation1.fulfill()
        }
        startNotifyingFuture.onFailure { _ in
            expectation1.fulfill()
            XCTFail("start notifying onFailure called")
        }
        self.peripheral.didUpdateNotificationStateForCharacteristic(mockCharacteristic, error: nil)

        let updateFuture = startNotifyingFuture.flatmap{ _ -> FutureStream<(characteristic: BCCharacteristic, data: NSData?)> in
            let future = characteristic.receiveNotificationUpdates()
            mockCharacteristic.value = "0".dataFromHexString()
            self.peripheral.didUpdateValueForCharacteristic(mockCharacteristic, error: nil)
            characteristic.stopNotificationUpdates()
            self.peripheral.didUpdateValueForCharacteristic(mockCharacteristic, error: nil)
            return future
        }
        updateFuture.onSuccess { (_, data) in
            if updates == 0 {
                expectation2.fulfill()
                updates += 1
                if let data = data {
                    XCTAssertEqual(data, "0".dataFromHexString(), "")
                } else {
                    XCTFail("characteristic value not set")
                }
            } else {
                XCTFail("update onSuccess called more than once")
            }
        }
        updateFuture.onFailure {error in
            expectation2.fulfill()
            XCTFail("update onFailure called")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
}
