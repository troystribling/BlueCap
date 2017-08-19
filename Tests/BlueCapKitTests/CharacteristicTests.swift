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
@testable import BlueCapKit

// MARK: - CharacteristicTests -
class CharacteristicTests: XCTestCase {

    var centralManager: CentralManager!
    var peripheral: Peripheral!
    var service: Service!
    let mockService = CBServiceMock(uuid: CBUUID(string: Gnosus.HelloWorldService.uuid))
    let mockPerpheral = CBPeripheralMock(state: .connected)
    let RSSI = -45

    override func setUp() {
        GnosusProfiles.create(profileManager: profileManager)
        centralManager = CentralManagerUT(centralManager: CBCentralManagerMock(state: .poweredOn), profileManager: profileManager)
        peripheral = Peripheral(cbPeripheral: self.mockPerpheral, centralManager: self.centralManager, advertisements: peripheralAdvertisements, RSSI: self.RSSI, profileManager: profileManager)
        let serviceProfile = profileManager.services[mockService.uuid]!
        service = Service(cbService: mockService, peripheral: peripheral, profile: serviceProfile)
        peripheral.discoveredServices = [service.uuid : [service]]
        mockPerpheral.services = [mockService]
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func createCharacteristic(_ properties: CBCharacteristicProperties, isNotifying:Bool, hasProfile: Bool = true) -> (Characteristic, CBCharacteristicMock) {
        let mockCharacteristic: CBCharacteristicMock
        if hasProfile {
            mockCharacteristic = CBCharacteristicMock(uuid: CBUUID(string: Gnosus.HelloWorldService.Greeting.uuid), properties: properties, isNotifying: isNotifying)
        } else {
            mockCharacteristic = CBCharacteristicMock(uuid: CBUUID(nsuuid: UUID()), properties: properties, isNotifying: isNotifying)
        }
        let characteristic = Characteristic(cbCharacteristic: mockCharacteristic, service: service)
        service.discoveredCharacteristics = [characteristic.uuid : [characteristic]]
        mockService.characteristics = [mockCharacteristic]
        return (characteristic, mockCharacteristic)
    }

    func createDuplicateCharacteristics(_ properties: CBCharacteristicProperties, isNotifying:Bool = true) -> ([Characteristic], [CBCharacteristicMock]) {
        let mockCharacteristics = [CBCharacteristicMock(uuid: CBUUID(string: Gnosus.HelloWorldService.Greeting.uuid), properties: properties, isNotifying: isNotifying), CBCharacteristicMock(uuid: CBUUID(string: Gnosus.HelloWorldService.Greeting.uuid), properties: properties, isNotifying: isNotifying)]
        let characteristics = mockCharacteristics.map { Characteristic(cbCharacteristic: $0, service: service) }
        service.discoveredCharacteristics = [characteristics[0].uuid : characteristics]
        mockService.characteristics = mockCharacteristics
        return (characteristics, mockCharacteristics)
    }

    // MARK: Write data

    func testWriteData_WithTypeWithResponseWritableAndNoErrorInAck_QueuesRequestAndCompletesSuccessfilly() {
        let (characteristic, mockCharacteristic) = createCharacteristic([.read, .write], isNotifying: false)
        let future = characteristic.write(data: "aa".dataFromHexString())

        XCTAssert(self.mockPerpheral.writeValueCalled)
        XCTAssertEqual(self.mockPerpheral.writeValueCount, 1)
        XCTAssertEqual(self.mockPerpheral.writtenData!, "aa".dataFromHexString())
        XCTAssertEqual(characteristic.pendingWriteCount, 1)
        XCTAssertEqual(self.mockPerpheral.writtenType, .withResponse)

        self.peripheral.didWriteValueForCharacteristic(mockCharacteristic, error :nil)
        XCTAssertFutureSucceeds(future, context: TestContext.immediate) { _ in
            XCTAssertEqual(characteristic.pendingWriteCount, 0)
        }
    }

    func testWriteData_WithTypeWithoutResponseAndWriteable_DoesNotQueueRequestsAndCompleteSuccessfully() {
        let (characteristic, mockCharacteristic) = createCharacteristic([.read, .write], isNotifying: false)
        let future = characteristic.write(data: "aa".dataFromHexString(), type: .withoutResponse)
        XCTAssert(mockPerpheral.writeValueCalled)
        XCTAssertEqual(mockCharacteristic.properties, [.read, .write])
        XCTAssertEqual(mockPerpheral.writeValueCount, 1)
        XCTAssertEqual(mockPerpheral.writtenType, .withoutResponse)
        XCTAssertEqual(mockPerpheral.writtenData!, "aa".dataFromHexString())
        XCTAssertEqual(characteristic.pendingWriteCount, 0)
        XCTAssertFutureSucceeds(future, context: TestContext.immediate)
    }

    func testWriteData_WithTypeWithResponseWritableAndErrorInAck_CompletesWithAckError() {
        let (characteristic, mockCharacteristic) = createCharacteristic([.read, .write], isNotifying: false)
        let future = characteristic.write(data: "aa".dataFromHexString())
        self.peripheral.didWriteValueForCharacteristic(mockCharacteristic, error:TestFailure.error)
        XCTAssertFutureFails(future, context: TestContext.immediate) { error in
            XCTAssertEqualErrors(error, TestFailure.error)
            XCTAssert(self.mockPerpheral.writeValueCalled)
            XCTAssertEqual(self.mockPerpheral.writeValueCount, 1)
            XCTAssertEqual(self.mockPerpheral.writtenType, .withResponse)
        }
    }

    func testWriteData_WithTypeWithResponseWritableAndOnTimeout_CompletesWithTimeoutError() {
        let (characteristic, mockCharacteristic) = createCharacteristic([.read, .write], isNotifying: false)
        let future = characteristic.write(data: "aa".dataFromHexString(), timeout:1.0)
        XCTAssertEqual(mockCharacteristic.properties, [.read, .write])
        XCTAssertFutureFails(future) { error in
            XCTAssertEqualErrors(error, CharacteristicError.writeTimeout)
            XCTAssert(self.mockPerpheral.writeValueCalled)
            XCTAssertEqual(self.mockPerpheral.writeValueCount, 1)
            XCTAssertEqual(self.mockPerpheral.writtenType, .withResponse)
        }
    }

    func testWriteData_WhenNotWriteable_CompletesWithErrorWriteNotSupported() {
        let (characteristic, mockCharacteristic) = createCharacteristic([.read], isNotifying: false)
        let future = characteristic.write(data: "aa".dataFromHexString())
        XCTAssertEqual(mockCharacteristic.properties, [.read])
        XCTAssertFutureFails(future, context: TestContext.immediate) { error in
            XCTAssertEqualErrors(error, CharacteristicError.writeNotSupported)
            XCTAssertFalse(self.mockPerpheral.writeValueCalled)
        }
    }

    func testWriteString_WithTypeWithResponseWritableAndProfileAndNoErrorOnAck_CompletesSuccessfully() {
        let (characteristic, mockCharacteristic) = createCharacteristic([.read, .write], isNotifying: false)
        let future = characteristic.write(string: ["Hello World Greeting" : "Good bye"])
        self.peripheral.didWriteValueForCharacteristic(mockCharacteristic, error: nil)
        XCTAssertFutureSucceeds(future, context: TestContext.immediate) { _ in
            XCTAssert(self.mockPerpheral.writeValueCalled)
            XCTAssertEqual(self.mockPerpheral.writeValueCount, 1)
            XCTAssertEqual(self.mockPerpheral.writtenType, .withResponse)
            if let data = self.mockPerpheral.writtenData, let result = Data.fromString("Good bye") {
                XCTAssertEqual(data, result)
            } else {
                XCTFail()
            }
        }
    }

    func testWriteString_WithTypeWithResponseWritableAndNoProfileAndNoErrorOnAck_CompletesSuccessfully() {
        let (characteristic, mockCharacteristic) = createCharacteristic([.read, .write], isNotifying: false, hasProfile: false)
        let future = characteristic.write(string: ["Unknown" : "abcd0101"])
        self.peripheral.didWriteValueForCharacteristic(mockCharacteristic, error: nil)
        XCTAssertFutureSucceeds(future, context: TestContext.immediate) { _ in
            XCTAssert(self.mockPerpheral.writeValueCalled)
            XCTAssertEqual(self.mockPerpheral.writeValueCount, 1)
            XCTAssertEqual(self.mockPerpheral.writtenType, .withResponse)
            if let data = self.mockPerpheral.writtenData {
                XCTAssertEqual(data, "abcd0101".dataFromHexString())
            } else {
                XCTFail()
            }
        }
    }

    func testWriteString_WhenStringIsNotSerializable_CompletesWithErrorNotSerailizable() {
        let (characteristic, _) = createCharacteristic([.read, .write], isNotifying:  false)
        let future = characteristic.write(string: ["bad name" : "Invalid"])
        XCTAssertFutureFails(future, context: TestContext.immediate) { error in
            XCTAssertFalse(self.mockPerpheral.writeValueCalled)
            XCTAssertEqualErrors(error, CharacteristicError.notSerializable)
        }
    }

    func testWriteData_WhenMultipleWithTypeWithResponseBeforeFirstAckReceived_QueuesRequestsAndCompleteSuccessfully() {
        let (characteristic, mockCharacteristic) = createCharacteristic([.read, .write], isNotifying: false)
        let future1 = characteristic.write(data: "aa".dataFromHexString(), type: .withResponse)
        let future2 = characteristic.write(data: "bb".dataFromHexString(), type: .withResponse)
        let future3 = characteristic.write(data: "cc".dataFromHexString(), type: .withResponse)

        XCTAssert(self.mockPerpheral.writeValueCalled)
        XCTAssertEqual(self.mockPerpheral.writeValueCount, 1)
        XCTAssertEqual(self.mockPerpheral.writtenData!, "aa".dataFromHexString())
        XCTAssertEqual(characteristic.pendingWriteCount, 3)

        self.peripheral.didWriteValueForCharacteristic(mockCharacteristic, error:nil)
        XCTAssertFutureSucceeds(future1, context: TestContext.immediate) { _ in
            XCTAssertEqual(self.mockPerpheral.writeValueCount, 2)
            XCTAssertEqual(self.mockPerpheral.writtenData!, "bb".dataFromHexString())
            XCTAssertEqual(characteristic.pendingWriteCount, 2)
        }
        self.peripheral.didWriteValueForCharacteristic(mockCharacteristic, error:nil)
        XCTAssertFutureSucceeds(future2, context: TestContext.immediate) { _ in
            XCTAssertEqual(self.mockPerpheral.writeValueCount, 3)
            XCTAssertEqual(self.mockPerpheral.writtenData!, "cc".dataFromHexString())
            XCTAssertEqual(characteristic.pendingWriteCount, 1)
        }
        self.peripheral.didWriteValueForCharacteristic(mockCharacteristic, error:nil)
        XCTAssertFutureSucceeds(future3, context: TestContext.immediate) { _ in
            XCTAssertEqual(characteristic.pendingWriteCount, 0)
        }
    }

    func testWriteData_WithDuplicateUUIDs_CompletesSuccessfully() {
        let (characteristics, mockCharacteristics) = createDuplicateCharacteristics([.read, .write], isNotifying: false)
        let future = characteristics[0].write(data: "aa".dataFromHexString())

        XCTAssert(self.mockPerpheral.writeValueCalled)
        XCTAssertEqual(self.mockPerpheral.writeValueCount, 1)
        XCTAssertEqual(self.mockPerpheral.writtenData!, "aa".dataFromHexString())
        XCTAssertEqual(characteristics[0].pendingWriteCount, 1)
        XCTAssertEqual(characteristics[1].pendingWriteCount, 0)
        XCTAssertEqual(self.mockPerpheral.writtenType, .withResponse)

        peripheral.didWriteValueForCharacteristic(mockCharacteristics[0], error :nil)
        XCTAssertFutureSucceeds(future, context: TestContext.immediate) { _ in
            XCTAssertEqual(characteristics[0].pendingWriteCount, 0)
            XCTAssertEqual(characteristics[1].pendingWriteCount, 0)
        }
    }

   // MARK: Read data

    func testRead_WhenReadableAndNoErrorInResponse_CompletesSuccessfully() {
        let (characteristic, mockCharacteristic) = createCharacteristic([.read, .write], isNotifying: false)
        let future = characteristic.read()
        XCTAssertEqual(characteristic.pendingReadCount, 1)
        self.peripheral.didUpdateValueForCharacteristic(mockCharacteristic, error:nil)
        XCTAssertFutureSucceeds(future, context: TestContext.immediate) { _ in
            XCTAssert(self.mockPerpheral.readValueForCharacteristicCalled)
            XCTAssertEqual(self.mockPerpheral.readValueForCharacteristicCount, 1)
        }
    }
    
    func testRead_WhenReadableAnResponseHasError_CompletesWithResponseError() {
        let (characteristic, mockCharacteristic) = createCharacteristic([.read, .write], isNotifying: false)
        let future = characteristic.read()
        XCTAssertEqual(characteristic.pendingReadCount, 1)
        self.peripheral.didUpdateValueForCharacteristic(mockCharacteristic, error:TestFailure.error)
        XCTAssertFutureFails(future, context: TestContext.immediate) { error in
            XCTAssert(self.mockPerpheral.readValueForCharacteristicCalled)
            XCTAssertEqual(self.mockPerpheral.readValueForCharacteristicCount, 1)
        }
    }
    
    func testRead_WhenReadableAndNoResponsdeReceivedBeforeTimeout_CompletesWithTimeoutError() {
        let (characteristic, mockCharacteristic) = createCharacteristic([.read, .write], isNotifying: false)
        XCTAssertEqual(mockCharacteristic.properties, [.read, .write])
        let future = characteristic.read(timeout: 0.25)
        XCTAssertEqual(characteristic.pendingReadCount, 1)
        XCTAssertFutureFails(future) { error in
            XCTAssert(self.mockPerpheral.readValueForCharacteristicCalled)
            XCTAssertEqualErrors(error, CharacteristicError.readTimeout)
            XCTAssertEqual(self.mockPerpheral.readValueForCharacteristicCount, 1)
        }
    }
    
    func testRead_WhenNotReadable_CompletesWithReadNotSupported() {
        let (characteristic, mockCharacteristic) = createCharacteristic([.write], isNotifying: false)
        XCTAssertEqual(mockCharacteristic.properties, [.write])
        let future = characteristic.read()
        XCTAssertFutureFails(future, context: TestContext.immediate) { error in
            XCTAssertFalse(self.mockPerpheral.readValueForCharacteristicCalled)
            XCTAssertEqualErrors(error, CharacteristicError.readNotSupported)
        }
    }
    
    func testRead_WhenMultipleReadsAreMadeBeforeFirstResponseIsReceived_AllCompleteSuccessfully() {
        let (characteristic, mockCharacteristic) = createCharacteristic([.read, .write], isNotifying: false)
        let future1 = characteristic.read()
        let future2 = characteristic.read()
        let future3 = characteristic.read()

        XCTAssertEqual(self.mockPerpheral.readValueForCharacteristicCount, 1)
        XCTAssertEqual(characteristic.pendingReadCount, 3)
        XCTAssert(self.mockPerpheral.readValueForCharacteristicCalled)

        self.peripheral.didUpdateValueForCharacteristic(mockCharacteristic, error:nil)
        XCTAssertFutureSucceeds(future1, context: TestContext.immediate) { chracteristic in
            XCTAssertEqual(self.mockPerpheral.readValueForCharacteristicCount, 2)
            XCTAssertEqual(characteristic.pendingReadCount, 2)
        }
        self.peripheral.didUpdateValueForCharacteristic(mockCharacteristic, error:nil)
        XCTAssertFutureSucceeds(future2, context: TestContext.immediate) { _ in
            XCTAssertEqual(self.mockPerpheral.readValueForCharacteristicCount, 3)
            XCTAssertEqual(characteristic.pendingReadCount, 1)
        }
        self.peripheral.didUpdateValueForCharacteristic(mockCharacteristic, error:nil)
        XCTAssertFutureSucceeds(future3, context: TestContext.immediate) { _ in
            XCTAssertEqual(self.mockPerpheral.readValueForCharacteristicCount, 3)
            XCTAssertEqual(characteristic.pendingReadCount, 0)
        }
    }

    func testRead_WithDuplicateUUIDs_CompletesSuccessfully() {
        let (characteristics, mockCharacteristics) = createDuplicateCharacteristics([.read, .write], isNotifying: false)
        let future = characteristics[0].read()
        XCTAssertEqual(characteristics[0].pendingReadCount, 1)
        XCTAssertEqual(characteristics[1].pendingReadCount, 0)
        self.peripheral.didUpdateValueForCharacteristic(mockCharacteristics[0], error:nil)
        XCTAssertFutureSucceeds(future, context: TestContext.immediate) { _ in
            XCTAssertEqual(characteristics[0].pendingReadCount, 0)
            XCTAssertEqual(characteristics[1].pendingReadCount, 0)
            XCTAssert(self.mockPerpheral.readValueForCharacteristicCalled)
            XCTAssertEqual(self.mockPerpheral.readValueForCharacteristicCount, 1)
        }
    }

    // MARK: StartNotifying

    func testStartNotifying_WhenNotifiableAndNoErrorOnAck_CompletesSuccessfully() {
        let (characteristic, mockCharacteristic) = createCharacteristic([.notify], isNotifying: false)
        let future = characteristic.startNotifying()
        self.peripheral.didUpdateNotificationStateForCharacteristic(mockCharacteristic, error:nil)
        XCTAssertFutureSucceeds(future, context: TestContext.immediate) { _ in
            XCTAssert(self.mockPerpheral.setNotifyValueCalled)
            XCTAssertEqual(self.mockPerpheral.setNotifyValueCount, 1)
            if let state = self.mockPerpheral.notifyingState {
                XCTAssert(state)
            } else {
                XCTFail()
            }
        }
    }

    func testStartNotifying_WhenNotifiableAndErrorInAck_CompletesWithAckError() {
        let (characteristic, mockCharacteristic) = createCharacteristic([.notify], isNotifying: false)
        let future = characteristic.startNotifying()
        self.peripheral.didUpdateNotificationStateForCharacteristic(mockCharacteristic, error: TestFailure.error)
        XCTAssertFutureFails(future, context:TestContext.immediate) { error in
            XCTAssert(self.mockPerpheral.setNotifyValueCalled)
            XCTAssertEqualErrors(error, TestFailure.error)
            XCTAssertEqual(self.mockPerpheral.setNotifyValueCount, 1)
            if let state = self.mockPerpheral.notifyingState {
                XCTAssert(state)
            } else {
                XCTFail()
            }
        }
    }

    func testStartNotifying_WhenIndicatableAndNoErrorOnAck_CompletesSuccessfully() {
        let (characteristic, mockCharacteristic) = createCharacteristic([.indicate], isNotifying: false)
        let future = characteristic.startNotifying()
        self.peripheral.didUpdateNotificationStateForCharacteristic(mockCharacteristic, error: nil)
        XCTAssertFutureSucceeds(future, context: TestContext.immediate) { _ in
            XCTAssert(self.mockPerpheral.setNotifyValueCalled)
            XCTAssertEqual(self.mockPerpheral.setNotifyValueCount, 1)
            if let state = self.mockPerpheral.notifyingState {
                XCTAssert(state)
            } else {
                XCTFail()
            }
        }
    }

    func testStartNotify_WhenNotifyEncryptionRequiredAndNoErrorOnAck_CompletesSuccessfully() {
        let (characteristic, mockCharacteristic) = createCharacteristic([.notifyEncryptionRequired], isNotifying: false)
        let future = characteristic.startNotifying()
        self.peripheral.didUpdateNotificationStateForCharacteristic(mockCharacteristic, error: nil)
        XCTAssertFutureSucceeds(future, context: TestContext.immediate) { _ in
            XCTAssert(self.mockPerpheral.setNotifyValueCalled)
            XCTAssertEqual(self.mockPerpheral.setNotifyValueCount, 1)
            if let state = self.mockPerpheral.notifyingState {
                XCTAssert(state)
            } else {
                XCTFail()
            }
        }
    }

    func testStartNotify_WhenIndicateEncryptionRequiredAndNoErrorOnAck_CompletesSuccessfully() {
        let (characteristic, mockCharacteristic) = createCharacteristic([.indicateEncryptionRequired], isNotifying: false)
        let future = characteristic.startNotifying()
        self.peripheral.didUpdateNotificationStateForCharacteristic(mockCharacteristic, error: nil)
        XCTAssertFutureSucceeds(future, context: TestContext.immediate) { _ in
            XCTAssert(self.mockPerpheral.setNotifyValueCalled)
            XCTAssertEqual(self.mockPerpheral.setNotifyValueCount, 1)
            if let state = self.mockPerpheral.notifyingState {
                XCTAssert(state)
            } else {
                XCTFail()
            }
        }
    }

    func testStartNotifying_WhenNotNotifiable_CompletesWithNotifyNotSupportedError() {
        let (characteristic, _) = createCharacteristic([], isNotifying: false)
        let future = characteristic.startNotifying()
        XCTAssertFutureFails(future, context: TestContext.immediate) { error in
            XCTAssertFalse(self.mockPerpheral.setNotifyValueCalled)
            XCTAssertEqualErrors(error, CharacteristicError.notifyNotSupported)
            if let state = self.mockPerpheral.notifyingState {
                XCTAssertFalse(state)
            }
        }
    }

    func testStartNotifying_WithDuplicateUUIDs_CompletesSuccessfully() {
        let (characteristics, mockCharacteristics) = createDuplicateCharacteristics([.notify], isNotifying: false)
        let future = characteristics[0].startNotifying()
        self.peripheral.didUpdateNotificationStateForCharacteristic(mockCharacteristics[0], error:nil)
        XCTAssertFutureSucceeds(future, context: TestContext.immediate) { _ in
            XCTAssert(self.mockPerpheral.setNotifyValueCalled)
            XCTAssertEqual(self.mockPerpheral.setNotifyValueCount, 1)
            if let state = self.mockPerpheral.notifyingState {
                XCTAssert(state)
            } else {
                XCTFail()
            }
        }
    }

    // MARK: ReceiveNotificationUpdates

    func testReceiveNotificationUpdates_WhenNotifiableAndUpdateIsReceivedWithoutError_CompletesSuccessfully() {
        let (characteristic, mockCharacteristic) = createCharacteristic([.notify], isNotifying: true)
        let startNotifyingFuture = characteristic.startNotifying()
        let updateFuture = startNotifyingFuture.flatMap(context: TestContext.immediate) { _ -> FutureStream<Data?> in
            characteristic.receiveNotificationUpdates()
        }
        self.peripheral.didUpdateNotificationStateForCharacteristic(mockCharacteristic, error: nil)
        mockCharacteristic.value = "11".dataFromHexString()
        self.peripheral.didUpdateValueForCharacteristic(mockCharacteristic, error: nil)
        XCTAssertFutureSucceeds(startNotifyingFuture, context: TestContext.immediate)
        XCTAssertFutureStreamSucceeds(updateFuture, context: TestContext.immediate, validations: [
            { data in
                if let data = data {
                    XCTAssertEqual(data, "11".dataFromHexString())
                } else {
                    XCTFail()
                }
            }
        ])
    }

    func testReceiveNotificationUpdates_WhenNotifiableUpdateIsReceivedWitfError_CompletesWithReceivedError() {
        let (characteristic, mockCharacteristic) = createCharacteristic([.notify], isNotifying: true)
        let startNotifyingFuture = characteristic.startNotifying()
        let updateFuture = startNotifyingFuture.flatMap(context: TestContext.immediate) { _ -> FutureStream<Data?> in
            characteristic.receiveNotificationUpdates()
        }
        self.peripheral.didUpdateNotificationStateForCharacteristic(mockCharacteristic, error: nil)
        mockCharacteristic.value = "11".dataFromHexString()
        self.peripheral.didUpdateValueForCharacteristic(mockCharacteristic, error: TestFailure.error)
        XCTAssertFutureSucceeds(startNotifyingFuture, context: TestContext.immediate)
        XCTAssertFutureStreamFails(updateFuture, context: TestContext.immediate, validations: [
            { error in
                XCTAssertEqualErrors(error, TestFailure.error)
            }
        ])
    }

    func testReceiveNotificationUpdates_WhenNotNotifiableUpdateIsReceivedWithError_CompletesWithNotifyNotSupported() {
        let (characteristic, _) = createCharacteristic([], isNotifying: true)
        let future = characteristic.receiveNotificationUpdates()
        XCTAssertFutureStreamFails(future, context: TestContext.immediate, validations: [
            { error in
                XCTAssertEqualErrors(error, CharacteristicError.notifyNotSupported)
            }
        ])
    }

    func testReceiveNotificationUpdates_WhenNotifiableAndMultipleUpdatesAreReceivedWithoutError_CompletesSuccessfully() {
        let (characteristic, mockCharacteristic) = createCharacteristic([.notify], isNotifying: true)

        let startNotifyingFuture = characteristic.startNotifying()

        let updateFuture = startNotifyingFuture.flatMap(context: TestContext.immediate) { _ -> FutureStream<Data?> in
            characteristic.receiveNotificationUpdates()
        }
        self.peripheral.didUpdateNotificationStateForCharacteristic(mockCharacteristic, error: nil)

        mockCharacteristic.value = "00".dataFromHexString()
        self.peripheral.didUpdateValueForCharacteristic(mockCharacteristic, error: nil)
        mockCharacteristic.value = "01".dataFromHexString()
        self.peripheral.didUpdateValueForCharacteristic(mockCharacteristic, error: nil)
        mockCharacteristic.value = "02".dataFromHexString()
        self.peripheral.didUpdateValueForCharacteristic(mockCharacteristic, error: nil)

        XCTAssertFutureSucceeds(startNotifyingFuture, context: TestContext.immediate)
        XCTAssertFutureStreamSucceeds(updateFuture, context: TestContext.immediate, validations: [
            { data in
                if let data = data {
                    XCTAssertEqual(data, "00".dataFromHexString())
                } else {
                    XCTFail()
                }
            },
            { data in
                if let data = data {
                    XCTAssertEqual(data, "01".dataFromHexString())
                } else {
                    XCTFail()
                }
            },
            { data in
                if let data = data {
                    XCTAssertEqual(data, "02".dataFromHexString())
                } else {
                    XCTFail()
                }
            }
        ])
    }

    func testReceiveNotificationUpdates_WithDublicateUUIDsr_CompletesSuccessfully() {
        let (characteristics, mockCharacteristics) = createDuplicateCharacteristics([.notify], isNotifying: true)
        let startNotifyingFuture = characteristics[0].startNotifying()
        let updateFuture = startNotifyingFuture.flatMap(context: TestContext.immediate) { _ -> FutureStream<Data?> in
            characteristics[0].receiveNotificationUpdates()
        }
        self.peripheral.didUpdateNotificationStateForCharacteristic(mockCharacteristics[0], error: nil)
        mockCharacteristics[0].value = "11".dataFromHexString()
        self.peripheral.didUpdateValueForCharacteristic(mockCharacteristics[0], error: nil)
        XCTAssertFutureSucceeds(startNotifyingFuture, context: TestContext.immediate)
        XCTAssertFutureStreamSucceeds(updateFuture, context: TestContext.immediate, validations: [
            { data in
                if let data = data {
                    XCTAssertEqual(data, "11".dataFromHexString())
                } else {
                    XCTFail()
                }
            }
        ])
    }

    // MARK: StopNotifying

    func testStopNotifying_WhenNotifyingAndNoErrorOnAck_CompletesSuccessfully() {
        let (characteristic, mockCharacteristic) = createCharacteristic([.notify], isNotifying: true)
        let future = characteristic.stopNotifying()
        self.peripheral.didUpdateNotificationStateForCharacteristic(mockCharacteristic, error: nil)
        XCTAssertFutureSucceeds(future, context: TestContext.immediate) { _ in
            XCTAssert(self.mockPerpheral.setNotifyValueCalled)
            XCTAssertEqual(self.mockPerpheral.setNotifyValueCount, 1)
            if let state = self.mockPerpheral.notifyingState {
                XCTAssertFalse(state)
            } else {
                XCTFail()
            }
        }
    }

    func testStopNotifying_WhenNotifyingAndErrorOnAck_CompletesWithAckError() {
        let (characteristic, mockCharacteristic) = createCharacteristic([.notify], isNotifying: true)
        let future = characteristic.stopNotifying()
        self.peripheral.didUpdateNotificationStateForCharacteristic(mockCharacteristic, error: TestFailure.error)
        XCTAssertFutureFails(future, context: TestContext.immediate) { error in
            XCTAssert(self.mockPerpheral.setNotifyValueCalled)
            XCTAssertEqual(self.mockPerpheral.setNotifyValueCount, 1)
            XCTAssertEqualErrors(error, TestFailure.error)
            if let state = self.mockPerpheral.notifyingState {
                XCTAssertFalse(state)
            } else {
                XCTFail()
            }
        }
    }

    func testStopNotifying_WhenNotNotifiable_CompletesWithNotifyNotSupported() {
        let (characteristic, _) = createCharacteristic([], isNotifying: true)
        let future = characteristic.stopNotifying()
        XCTAssertFutureFails(future, context: TestContext.immediate) { error in
            XCTAssertFalse(self.mockPerpheral.setNotifyValueCalled)
            XCTAssertEqualErrors(error, CharacteristicError.notifyNotSupported)
        }
    }

    func testStopNotifying_WithDuplicateUUIDs_CompletesSuccessfully() {
        let (characteristics, mockCharacteristics) = createDuplicateCharacteristics([.notify], isNotifying: true)
        let future = characteristics[0].stopNotifying()
        self.peripheral.didUpdateNotificationStateForCharacteristic(mockCharacteristics[0], error: nil)
        XCTAssertFutureSucceeds(future, context: TestContext.immediate) { _ in
            XCTAssert(self.mockPerpheral.setNotifyValueCalled)
            XCTAssertEqual(self.mockPerpheral.setNotifyValueCount, 1)
            if let state = self.mockPerpheral.notifyingState {
                XCTAssertFalse(state)
            } else {
                XCTFail()
            }
        }
    }

}
