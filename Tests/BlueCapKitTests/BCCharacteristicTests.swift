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
    let immediateContext = ImmediateContext()

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
    func testWriteData_WithTypeWithResponseWritableAndNoErrorInAck_QueuesRequestAndCompletesSuccessfilly() {
        let (characteristic, mockCharacteristic) = self.createCharacteristic([.Read, .Write], isNotifying: false)
        let future = characteristic.writeData("aa".dataFromHexString())

        XCTAssert(self.mockPerpheral.writeValueCalled, "CBPeripheral#writeValue not called")
        XCTAssertEqual(self.mockPerpheral.writeValueCount, 1, "CBPeripheral#writeValue called count invalid")
        XCTAssertEqual(self.mockPerpheral.writtenData!, "aa".dataFromHexString())
        XCTAssertEqual(characteristic.writePromises.count, 1, "CBCharateristic#writePromises count invalid")
        XCTAssertEqual(self.mockPerpheral.writtenType, .WithResponse, "writtenType is invalid")

        self.peripheral.didWriteValueForCharacteristic(mockCharacteristic, error :nil)
        XCTAssertFutureSucceeds(future, context: self.immediateContext) { _ in
            XCTAssertEqual(characteristic.writePromises.count, 0, "CBCharateristic#writePromises count invalid")
        }
    }

    func testWriteData_WithTypeWithoutResponseAndWriteable_DoesNotQueueRequestsAndCompleteSuccessfully() {
        let (characteristic, _) = self.createCharacteristic([.Read, .Write], isNotifying: false)
        let future = characteristic.writeData("aa".dataFromHexString(), type: .WithoutResponse)
        XCTAssert(self.mockPerpheral.writeValueCalled, "CBPeripheral#writeValue not called")
        XCTAssertEqual(self.mockPerpheral.writeValueCount, 1, "CBPeripheral#writeValue called count invalid")
        XCTAssertEqual(self.mockPerpheral.writtenType, .WithoutResponse, "writtenType is invalid")
        XCTAssertEqual(self.mockPerpheral.writtenData!, "aa".dataFromHexString())
        XCTAssertEqual(characteristic.writePromises.count, 0, "CBCharateristic#writePromises count invalid")
        XCTAssertFutureSucceeds(future, context: self.immediateContext)
    }

    func testWriteData_WithTypeWithResponseWritableAndErrorInAck_CompletesWithAckError() {
        let (characteristic, mockCharacteristic) = self.createCharacteristic([.Read, .Write], isNotifying: false)
        let future = characteristic.writeData("aa".dataFromHexString())
        self.peripheral.didWriteValueForCharacteristic(mockCharacteristic, error:TestFailure.error)
        XCTAssertFutureFails(future, context: self.immediateContext) { error in
            XCTAssertEqual(error.code, TestFailure.error.code, "Error code invalid")
            XCTAssert(self.mockPerpheral.writeValueCalled, "CBPeripheral#writeValue not called")
            XCTAssertEqual(self.mockPerpheral.writeValueCount, 1, "CBPeripheral#writeValue called more than once")
            XCTAssertEqual(self.mockPerpheral.writtenType, .WithResponse, "writtenType is invalid")
        }
    }

    func testWriteData_WithTypeWithResponseWritableAndOnTimeout_CompletesWithTimeoutError() {
        let (characteristic, _) = self.createCharacteristic([.Read, .Write], isNotifying: false)
        let future = characteristic.writeData("aa".dataFromHexString(), timeout:1.0)
        XCTAssertFutureFails(future) { error in
            XCTAssertEqual(error.code, BCCharacteristicErrorCode.WriteTimeout.rawValue, "Error code invalid")
            XCTAssert(self.mockPerpheral.writeValueCalled, "CBPeripheral#writeValue not called")
            XCTAssertEqual(self.mockPerpheral.writeValueCount, 1, "CBPeripheral#writeValue called more than once")
            XCTAssertEqual(self.mockPerpheral.writtenType, .WithResponse, "writtenType is invalid")
        }
    }

    func testWriteData_WhenNotWriteable_CompletesWithErrorWriteNotSupported() {
        let (characteristic, _) = self.createCharacteristic([.Read], isNotifying: false)
        let future = characteristic.writeData("aa".dataFromHexString())
        XCTAssertFutureFails(future, context: self.immediateContext) { error in
            XCTAssertEqual(error.code, BCCharacteristicErrorCode.WriteNotSupported.rawValue, "Error code invalid")
            XCTAssertFalse(self.mockPerpheral.writeValueCalled, "CBPeripheral#writeValue called")
        }
    }

    func testWriteString_WithTypeWithResponseWritableAndNoErrorOnAck_CompletesSuccessfully() {
        let (characteristic, mockCharacteristic) = self.createCharacteristic([.Read, .Write], isNotifying: false)
        let future = characteristic.writeString(["Hello World Greeting":"Good bye"])
        self.peripheral.didWriteValueForCharacteristic(mockCharacteristic, error:nil)
        XCTAssertFutureSucceeds(future, context: self.immediateContext) { _ in
            XCTAssert(self.mockPerpheral.writeValueCalled, "CBPeripheral#writeValue not called")
            XCTAssertEqual(self.mockPerpheral.writeValueCount, 1, "CBPeripheral#writeValue called more than once")
            XCTAssertEqual(self.mockPerpheral.writtenType, .WithResponse, "writtenType is invalid")
            if let data = self.mockPerpheral.writtenData, result = NSData.fromString("Good bye") {
                XCTAssertEqual(data, result, "writeValue data is invalid")
            } else {
                XCTFail("writeValue no data available")
            }
        }
    }
    
    func testWriteString_WhenStringIsNotSerializable_CompletesWithErrorNotSerailizable() {
        let (characteristic, _) = self.createCharacteristic([.Read, .Write], isNotifying:  false)
        let future = characteristic.writeString(["bad name":"Invalid"])
        XCTAssertFutureFails(future, context: self.immediateContext) { error in
            XCTAssertFalse(self.mockPerpheral.writeValueCalled, "CBPeripheral#writeValue called")
            XCTAssertEqual(error.code, BCError.characteristicNotSerilaizable.code, "Error code invalid")
        }
    }

    func testWriteData_WhenMultipleWithTypeWithResponseBeforeFirstAckReceived_QueuesRequestsAndCompleteSuccessfully() {
        let (characteristic, mockCharacteristic) = self.createCharacteristic([.Read, .Write], isNotifying: false)
        let future1 = characteristic.writeData("aa".dataFromHexString(), type: .WithResponse)
        let future2 = characteristic.writeData("bb".dataFromHexString(), type: .WithResponse)
        let future3 = characteristic.writeData("cc".dataFromHexString(), type: .WithResponse)

        XCTAssert(self.mockPerpheral.writeValueCalled, "CBPeripheral#writeValue not called")
        XCTAssertEqual(self.mockPerpheral.writeValueCount, 1, "CBPeripheral#writeValue called count invalid")
        XCTAssertEqual(self.mockPerpheral.writtenData!, "aa".dataFromHexString())
        XCTAssertEqual(characteristic.writePromises.count, 3, "CBCharateristic#writePromises count invalid")

        self.peripheral.didWriteValueForCharacteristic(mockCharacteristic, error:nil)
        XCTAssertFutureSucceeds(future1, context: self.immediateContext) { characteristic in
            XCTAssertEqual(self.mockPerpheral.writeValueCount, 2, "CBPeripheral#writeValue called count invalid")
            XCTAssertEqual(self.mockPerpheral.writtenData!, "bb".dataFromHexString())
            XCTAssertEqual(characteristic.writePromises.count, 2, "CBCharateristic#writePromises count invalid")
        }
        self.peripheral.didWriteValueForCharacteristic(mockCharacteristic, error:nil)
        XCTAssertFutureSucceeds(future2, context: self.immediateContext) { characteristic in
            XCTAssertEqual(self.mockPerpheral.writeValueCount, 3, "CBPeripheral#writeValue called count invalid")
            XCTAssertEqual(self.mockPerpheral.writtenData!, "cc".dataFromHexString())
            XCTAssertEqual(characteristic.writePromises.count, 1, "CBCharateristic#writePromises count invalid")
        }
        self.peripheral.didWriteValueForCharacteristic(mockCharacteristic, error:nil)
        XCTAssertFutureSucceeds(future3, context: self.immediateContext) { characteristic in
            XCTAssertEqual(characteristic.writePromises.count, 0, "CBCharateristic#writePromises count invalid")
        }
    }

   // MARK: Read data
    func testRead_WhenReadableAndNoErrorInResponse_CompletesSuccessfully() {
        let (characteristic, mockCharacteristic) = self.createCharacteristic([.Read, .Write], isNotifying: false)
        let future = characteristic.read()
        self.peripheral.didUpdateValueForCharacteristic(mockCharacteristic, error:nil)
        XCTAssertFutureSucceeds(future, context: self.immediateContext) { _ in
            XCTAssert(self.mockPerpheral.readValueForCharacteristicCalled, "CBPeripheral#readValueForCharacteristic not called")
            XCTAssertEqual(self.mockPerpheral.readValueForCharacteristicCount, 1, "CBPeripheral#readValue not called 1 time")
        }
    }
    
    func testRead_WhenReadableAnResponseHasError_CompletesWithResponseError() {
        let (characteristic, mockCharacteristic) = self.createCharacteristic([.Read, .Write], isNotifying: false)
        let future = characteristic.read()
        self.peripheral.didUpdateValueForCharacteristic(mockCharacteristic, error:TestFailure.error)
        XCTAssertFutureFails(future, context: self.immediateContext) { error in
            XCTAssert(self.mockPerpheral.readValueForCharacteristicCalled, "CBPeripheral#readValueForCharacteristic not called")
            XCTAssertEqual(self.mockPerpheral.readValueForCharacteristicCount, 1, "CBPeripheral#readValue not called 1 time")
        }
    }
    
    func testRead_WhenReadableAndNoResponsdeReceivedBeforeTimeout_CompletesWithTimeoutError() {
        let (characteristic, _) = self.createCharacteristic([.Read, .Write], isNotifying: false)
        let future = characteristic.read(1.0)
        XCTAssertFutureFails(future) { error in
            XCTAssert(self.mockPerpheral.readValueForCharacteristicCalled, "CBPeripheral#readValueForCharacteristic not called")
            XCTAssertEqual(error.code, BCCharacteristicErrorCode.ReadTimeout.rawValue, "Error code invalid")
            XCTAssertEqual(self.mockPerpheral.readValueForCharacteristicCount, 1, "CBPeripheral#readValue not called 1 time")
        }
    }
    
    func testRead_WhenNotReadable_CompletesWithReadNotSupported() {
        let (characteristic, _) = self.createCharacteristic([.Write], isNotifying: false)
        let future = characteristic.read()
        XCTAssertFutureFails(future, context: self.immediateContext) { error in
            XCTAssertFalse(self.mockPerpheral.readValueForCharacteristicCalled, "CBPeripheral#readValueForCharacteristic called")
            XCTAssertEqual(error.code, BCCharacteristicErrorCode.ReadNotSupported.rawValue, "Error code invalid")
        }
    }
    
    func testRead_WhenMultipleReadsAreMadeBeforeFirstResponseIsReceived_AllCompleteSuccessfully() {
        let (characteristic, mockCharacteristic) = self.createCharacteristic([.Read, .Write], isNotifying: false)
        let future1 = characteristic.read()
        let future2 = characteristic.read()
        let future3 = characteristic.read()

        XCTAssertEqual(self.mockPerpheral.readValueForCharacteristicCount, 1, "CBPeripheral#readValue called count invalid")
        XCTAssertEqual(characteristic.readPromises.count, 3, "CBCharateristic#readPromises count invalid")
        XCTAssert(self.mockPerpheral.readValueForCharacteristicCalled, "CBPeripheral#readValueForCharacteristic not called")

        self.peripheral.didUpdateValueForCharacteristic(mockCharacteristic, error:nil)
        XCTAssertFutureSucceeds(future1, context: self.immediateContext) { chracteristic in
            XCTAssertEqual(self.mockPerpheral.readValueForCharacteristicCount, 2, "CBPeripheral#readValue called count invalid")
            XCTAssertEqual(characteristic.readPromises.count, 2, "CBCharateristic#readPromises count invalid")
        }
        self.peripheral.didUpdateValueForCharacteristic(mockCharacteristic, error:nil)
        XCTAssertFutureSucceeds(future2, context: self.immediateContext) { _ in
            XCTAssertEqual(self.mockPerpheral.readValueForCharacteristicCount, 3, "CBPeripheral#readValue called count invalid")
            XCTAssertEqual(characteristic.readPromises.count, 1, "CBCharateristic#readPromises count invalid")
        }
        self.peripheral.didUpdateValueForCharacteristic(mockCharacteristic, error:nil)
        XCTAssertFutureSucceeds(future3, context: self.immediateContext) { _ in
            XCTAssertEqual(self.mockPerpheral.readValueForCharacteristicCount, 3, "CBPeripheral#readValue called count invalid")
            XCTAssertEqual(characteristic.readPromises.count, 0, "CBCharateristic#readPromises count invalid")
        }
    }

    // MARK: Notifications
    func testStartNotifying_WhenNotifiableAndNoErrorOnAck_CompletesSuccessfully() {
        let (characteristic, mockCharacteristic) = self.createCharacteristic([.Notify], isNotifying: false)
        let future = characteristic.startNotifying()
        self.peripheral.didUpdateNotificationStateForCharacteristic(mockCharacteristic, error:nil)
        XCTAssertFutureSucceeds(future, context: self.immediateContext) { _ in
            XCTAssert(self.mockPerpheral.setNotifyValueCalled, "CBPeripheral#setNotifyValue not called")
            XCTAssertEqual(self.mockPerpheral.setNotifyValueCount, 1, "CBPeripheral#setNotifyValueCount not called 1 time")
            if let state = self.mockPerpheral.notifyingState {
                XCTAssert(state, "setNotifyValue state not true")
            } else {
                XCTFail("setNotifyValue state not set")
            }
        }
    }

    func testStartNotifying_WhenNotifiableAndErrorInAck_CompletesWithAckError() {
        let (characteristic, mockCharacteristic) = self.createCharacteristic([.Notify], isNotifying: false)
        let future = characteristic.startNotifying()
        self.peripheral.didUpdateNotificationStateForCharacteristic(mockCharacteristic, error: TestFailure.error)
        XCTAssertFutureFails(future, context:self.immediateContext) { error in
            XCTAssert(self.mockPerpheral.setNotifyValueCalled, "CBPeripheral#setNotifyValue not called")
            XCTAssertEqual(error.code, TestFailure.error.code, "Error code invalid")
            XCTAssertEqual(self.mockPerpheral.setNotifyValueCount, 1, "CBPeripheral#setNotifyValueCount not called 1 time")
            if let state = self.mockPerpheral.notifyingState {
                XCTAssert(state, "setNotifyValue state not true")
            } else {
                XCTFail("setNotifyValue state not set")
            }
        }
    }

    func testStartNotifying_WhenIndicatableAndNoErrorOnAck_CompletesSuccessfully() {
        let (characteristic, mockCharacteristic) = self.createCharacteristic([.Indicate], isNotifying: false)
        let future = characteristic.startNotifying()
        self.peripheral.didUpdateNotificationStateForCharacteristic(mockCharacteristic, error: nil)
        XCTAssertFutureSucceeds(future, context: self.immediateContext) { _ in
            XCTAssert(self.mockPerpheral.setNotifyValueCalled, "setNotifyValue not called")
            XCTAssertEqual(self.mockPerpheral.setNotifyValueCount, 1, "CBPeripheral#setNotifyValueCount not called 1 time")
            if let state = self.mockPerpheral.notifyingState {
                XCTAssert(state, "setNotifyValue state not true")
            } else {
                XCTFail("setNotifyValue state not set")
            }
        }
    }

    func testStartNotify_WhenNotifyEncryptionRequiredAndNoErrorOnAck_CompletesSuccessfully() {
        let (characteristic, mockCharacteristic) = self.createCharacteristic([.NotifyEncryptionRequired], isNotifying: false)
        let future = characteristic.startNotifying()
        self.peripheral.didUpdateNotificationStateForCharacteristic(mockCharacteristic, error: nil)
        XCTAssertFutureSucceeds(future, context: self.immediateContext) { _ in
            XCTAssert(self.mockPerpheral.setNotifyValueCalled, "CBPeripheral#setNotifyValue not called")
            XCTAssertEqual(self.mockPerpheral.setNotifyValueCount, 1, "CBPeripheral#setNotifyValueCount not called 1 time")
            if let state = self.mockPerpheral.notifyingState {
                XCTAssert(state, "setNotifyValue state not true")
            } else {
                XCTFail("setNotifyValue state not set")
            }
        }
    }

    func testStartNotify_WhenIndicateEncryptionRequiredAndNoErrorOnAck_CompletesSuccessfully() {
        let (characteristic, mockCharacteristic) = self.createCharacteristic([.IndicateEncryptionRequired], isNotifying: false)
        let future = characteristic.startNotifying()
        self.peripheral.didUpdateNotificationStateForCharacteristic(mockCharacteristic, error: nil)
        XCTAssertFutureSucceeds(future, context: self.immediateContext) { _ in
            XCTAssert(self.mockPerpheral.setNotifyValueCalled, "CBPeripheral#setNotifyValue not called")
            XCTAssertEqual(self.mockPerpheral.setNotifyValueCount, 1, "CBPeripheral#setNotifyValueCount not called 1 time")
            if let state = self.mockPerpheral.notifyingState {
                XCTAssert(state, "setNotifyValue state not true")
            } else {
                XCTFail("setNotifyValue state not set")
            }
        }
    }

    func testStartNotifying_WhenNotNotifiable_CompletesWithNotifyNotSupportedError() {
        let (characteristic, _) = self.createCharacteristic([], isNotifying: false)
        let future = characteristic.startNotifying()
        XCTAssertFutureFails(future, context: self.immediateContext) { error in
            XCTAssertFalse(self.mockPerpheral.setNotifyValueCalled, "CBPeripheral#setNotifyValue not called")
            XCTAssertEqual(error.code, BCError.characteristicNotifyNotSupported.code, "Error code invalid")
            if let state = self.mockPerpheral.notifyingState {
                XCTAssertFalse(state, "setNotifyValue state not true")
            }
        }
    }

    func testReceiveNotificationUpdates_WhenNotifiableAndUpdateIsReceivedWithoutError_CompletesSuccessfully() {
        let (characteristic, mockCharacteristic) = self.createCharacteristic([.Notify], isNotifying: true)
        let startNotifyingFuture = characteristic.startNotifying()
        let updateFuture = startNotifyingFuture.flatmap(self.immediateContext) { _ -> FutureStream<(characteristic: BCCharacteristic, data: NSData?)> in
            characteristic.receiveNotificationUpdates()
        }
        self.peripheral.didUpdateNotificationStateForCharacteristic(mockCharacteristic, error: nil)
        mockCharacteristic.value = "11".dataFromHexString()
        self.peripheral.didUpdateValueForCharacteristic(mockCharacteristic, error: nil)
        XCTAssertFutureSucceeds(startNotifyingFuture, context: self.immediateContext)
        XCTAssertFutureStreamSucceeds(updateFuture, context: self.immediateContext, validations: [
            { (_, data) in
                if let data = data {
                    XCTAssertEqual(data, "11".dataFromHexString(), "characteristic value invalid")
                } else {
                    XCTFail("characteristic value not set")
                }
            }
        ])
    }

    func testReceiveNotificationUpdates_WhenNotifiableUpdateIsReceivedWitfError_CompletesWithReceivedError() {
        let (characteristic, mockCharacteristic) = self.createCharacteristic([.Notify], isNotifying: true)
        let startNotifyingFuture = characteristic.startNotifying()
        let updateFuture = startNotifyingFuture.flatmap(self.immediateContext) { _ -> FutureStream<(characteristic: BCCharacteristic, data: NSData?)> in
            characteristic.receiveNotificationUpdates()
        }
        self.peripheral.didUpdateNotificationStateForCharacteristic(mockCharacteristic, error: nil)
        mockCharacteristic.value = "11".dataFromHexString()
        self.peripheral.didUpdateValueForCharacteristic(mockCharacteristic, error: TestFailure.error)
        XCTAssertFutureSucceeds(startNotifyingFuture, context: self.immediateContext)
        XCTAssertFutureStreamFails(updateFuture, context: self.immediateContext, validations: [
            { error in
                XCTAssertEqual(error.code, TestFailure.error.code, "Error code invalid")
            }
        ])
    }

    func testReceiveNotificationUpdates_WhenNotNotifiableUpdateIsReceivedWithError_CompletesWithNotifyNotSupported() {
        let (characteristic, _) = self.createCharacteristic([], isNotifying: true)
        let future = characteristic.receiveNotificationUpdates()
        XCTAssertFutureStreamFails(future, context: self.immediateContext, validations: [
            { error in
                XCTAssertEqual(error.code, BCError.characteristicNotifyNotSupported.code, "Error code invalid")
            }
        ])
    }

    func testReceiveNotificationUpdates_WhenNotifiableAndMultipleUpdatesAreReceivedWithoutErrot_CompletesSuccessfully() {
        let (characteristic, mockCharacteristic) = self.createCharacteristic([.Notify], isNotifying: true)

        let startNotifyingFuture = characteristic.startNotifying()

        let updateFuture = startNotifyingFuture.flatmap (self.immediateContext) { _ -> FutureStream<(characteristic: BCCharacteristic, data: NSData?)> in
            characteristic.receiveNotificationUpdates()
        }
        self.peripheral.didUpdateNotificationStateForCharacteristic(mockCharacteristic, error: nil)

        mockCharacteristic.value = "00".dataFromHexString()
        self.peripheral.didUpdateValueForCharacteristic(mockCharacteristic, error: nil)
        mockCharacteristic.value = "01".dataFromHexString()
        self.peripheral.didUpdateValueForCharacteristic(mockCharacteristic, error: nil)
        mockCharacteristic.value = "02".dataFromHexString()
        self.peripheral.didUpdateValueForCharacteristic(mockCharacteristic, error: nil)

        XCTAssertFutureSucceeds(startNotifyingFuture, context: self.immediateContext)
        XCTAssertFutureStreamSucceeds(updateFuture, context: self.immediateContext, validations: [
            { (_, data) in
                if let data = data {
                    XCTAssertEqual(data, "00".dataFromHexString(), "characteristic value invalid")
                } else {
                    XCTFail("characteristic value not set")
                }
            },
            { (_, data) in
                if let data = data {
                    XCTAssertEqual(data, "01".dataFromHexString(), "characteristic value invalid")
                } else {
                    XCTFail("characteristic value not set")
                }
            },
            { (_, data) in
                if let data = data {
                    XCTAssertEqual(data, "02".dataFromHexString(), "characteristic value invalid")
                } else {
                    XCTFail("characteristic value not set")
                }
            }
        ])
    }
    
    func testStopNotifying_WhenNotifyingAndNoErrorOnAck_CompletesSuccessfully() {
        let (characteristic, mockCharacteristic) = self.createCharacteristic([.Notify], isNotifying: true)
        let future = characteristic.stopNotifying()
        self.peripheral.didUpdateNotificationStateForCharacteristic(mockCharacteristic, error: nil)
        XCTAssertFutureSucceeds(future, context: self.immediateContext) { _ in
            XCTAssert(self.mockPerpheral.setNotifyValueCalled, "CBPeripheral#setNotifyValue not called")
            XCTAssertEqual(self.mockPerpheral.setNotifyValueCount, 1, "CBPeripheral#setNotifyValueCount not called 1 time")
            if let state = self.mockPerpheral.notifyingState {
                XCTAssertFalse(state, "setNotifyValue state not true")
            } else {
                XCTFail("setNotifyValue state not set")
            }
        }
    }

    func testStopNotifying_WhenNotifyingAndErrorOnAck_CompletesWithAckError() {
        let (characteristic, mockCharacteristic) = self.createCharacteristic([.Notify], isNotifying: true)
        let future = characteristic.stopNotifying()
        self.peripheral.didUpdateNotificationStateForCharacteristic(mockCharacteristic, error: TestFailure.error)
        XCTAssertFutureFails(future, context: self.immediateContext) { error in
            XCTAssert(self.mockPerpheral.setNotifyValueCalled, "CBPeripheral#setNotifyValue not called")
            XCTAssertEqual(self.mockPerpheral.setNotifyValueCount, 1, "CBPeripheral#setNotifyValueCount not called 1 time")
            XCTAssertEqual(error.code, TestFailure.error.code, "Error code invalid")
            if let state = self.mockPerpheral.notifyingState {
                XCTAssertFalse(state, "setNotifyValue state not true")
            } else {
                XCTFail("setNotifyValue state not set")
            }
        }
    }

    func testStopNotifying_WhenNotNotifiable_CompletesWithNotifyNotSupported() {
        let (characteristic, _) = self.createCharacteristic([], isNotifying: true)
        let future = characteristic.stopNotifying()
        XCTAssertFutureFails(future, context: self.immediateContext) { error in
            XCTAssertFalse(self.mockPerpheral.setNotifyValueCalled, "CBPeripheral#setNotifyValue not called")
            XCTAssertEqual(error.code, BCError.characteristicNotifyNotSupported.code, "Error code invalid")
        }
    }
    
}
