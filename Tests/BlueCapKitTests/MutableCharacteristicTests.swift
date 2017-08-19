//
//  MutableCharacteristicTests.swift
//  BlueCapKit
//
//  Created by Troy Stribling on 3/24/15.
//  Copyright (c) 2015 Troy Stribling. The MIT License (MIT).
//

import UIKit
import XCTest
import CoreBluetooth
import CoreLocation
@testable import BlueCapKit

// MARK: - MutableCharacteristicTests -
class MutableCharacteristicTests: XCTestCase {

    override func setUp() {
        GnosusProfiles.create(profileManager: profileManager)
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func addCharacteristics() -> (CBPeripheralManagerMock, PeripheralManagerUT, MutableService) {
        let (mock, peripheralManager) = createPeripheralManager(false, state: .poweredOn)
        let service = createPeripheralManagerService()
        service.characteristics = service.profile.characteristics.map { profile in
            let characteristic = CBMutableCharacteristicMock(uuid: profile.uuid, properties: profile.properties, permissions: profile.permissions, isNotifying: false)
            return MutableCharacteristic(cbMutableCharacteristic: characteristic, profile: profile)
        }
        let future = peripheralManager.add(service)
        future.onSuccess(context: TestContext.immediate) { _ in
            mock.isAdvertising = true
        }
        future.onFailure(context: TestContext.immediate) { _ in
            XCTFail()
        }
        peripheralManager.didAddService(service.cbMutableService, error: nil)
        return (mock, peripheralManager, service)
    }

    func addDuplicateCharacteristics() -> (CBPeripheralManagerMock, PeripheralManagerUT, MutableService) {
        let (mock, peripheralManager) = createPeripheralManager(false, state: .poweredOn)
        let service = createPeripheralManagerService()
        let characteristicProfile = service.profile.characteristics[0]
        let cbCharacteristic1 = CBMutableCharacteristicMock(uuid: characteristicProfile.uuid, properties: characteristicProfile.properties, permissions: characteristicProfile.permissions, isNotifying: false)
        let cbCharacteristic2 = CBMutableCharacteristicMock(uuid: characteristicProfile.uuid, properties: characteristicProfile.properties, permissions: characteristicProfile.permissions, isNotifying: false)
        service.characteristics = [MutableCharacteristic(cbMutableCharacteristic: cbCharacteristic1, profile: characteristicProfile),
                                   MutableCharacteristic(cbMutableCharacteristic: cbCharacteristic2, profile: characteristicProfile)]
        let future = peripheralManager.add(service)
        future.onSuccess(context: TestContext.immediate) { _ in
            mock.isAdvertising = true
        }
        future.onFailure(context: TestContext.immediate) { _ in
            XCTFail()
        }
        peripheralManager.didAddService(service.cbMutableService, error: nil)
        return (mock, peripheralManager, service)
    }

    // MARK: Add characteristics
    
    func testAddCharacteristics_WhenServiceAddWasSuccessfull_CompletesSuccessfully() {
        let (_, peripheralManager, _) = addCharacteristics()
        let chracteristics = peripheralManager.characteristics.map { $0.uuid }
        XCTAssertEqual(chracteristics.count, 2)
        XCTAssert(chracteristics.contains(CBUUID(string: Gnosus.HelloWorldService.Greeting.uuid)))
        XCTAssert(chracteristics.contains(CBUUID(string: Gnosus.HelloWorldService.UpdatePeriod.uuid)))
    }

    func testAddCharacteristics_WithDuplicateUUIDs_CompletesSuccessfully() {
        let (_, peripheralManager, _) = addDuplicateCharacteristics()
        let chracteristics = peripheralManager.characteristics.map { $0.uuid }
        XCTAssertEqual(chracteristics.count, 2)
        XCTAssert(chracteristics.contains(CBUUID(string: Gnosus.HelloWorldService.Greeting.uuid)))
        XCTAssertEqual(peripheralManager.characteristics(withUUID: CBUUID(string: Gnosus.HelloWorldService.Greeting.uuid))?.count, 2)
    }

    // MARK: Subscribe to charcteristic updates
    
    func testUpdateValueWithData_WithNoSubscribers_AddsUpdateToPengingQueue() {
        let (mock, peripheralManager, _) = addCharacteristics()
        let characteristic = peripheralManager.characteristics[0]
        XCTAssertFalse(characteristic.isUpdating)
        XCTAssertEqual(characteristic.subscribers.count, 0)
        XCTAssertNoThrow(try characteristic.update(withData: "aa".dataFromHexString()))
        XCTAssertFalse(mock.updateValueCalled)
        XCTAssertEqual(characteristic.pendingUpdates.count, 1)
    }

    func testUpdateValueWithData_WithSubscriber_IsSendingUpdates() {
        let centralMock = CBCentralMock(maximumUpdateValueLength: 20)
        let (mock, peripheralManager, _) = addCharacteristics()
        let characteristic = peripheralManager.characteristics[0]
        let value = "aa".dataFromHexString()
        peripheralManager.didSubscribeToCharacteristic(characteristic.cbMutableChracteristic, central: centralMock)
        XCTAssert(characteristic.isUpdating)
        XCTAssertNoThrow(try characteristic.update(withData: value))
        XCTAssert(mock.updateValueCalled)
        XCTAssertEqual(characteristic.value, value)
        XCTAssertEqual(characteristic.subscribers.count, 1)
        XCTAssertEqual(characteristic.pendingUpdates.count, 0)
    }


    func testUpdateValueWithData_WithSubscribers_IsSendingUpdates() {
        let centralMock1 = CBCentralMock(maximumUpdateValueLength: 20)
        let centralMock2 = CBCentralMock(maximumUpdateValueLength: 20)
        let (mock, peripheralManager, _) = addCharacteristics()
        let characteristic = peripheralManager.characteristics[0]
        let value = "aa".dataFromHexString()
        peripheralManager.didSubscribeToCharacteristic(characteristic.cbMutableChracteristic, central: centralMock1)
        peripheralManager.didSubscribeToCharacteristic(characteristic.cbMutableChracteristic, central: centralMock2)
        let centrals = characteristic.subscribers
        let centralIDs = centrals.map { $0.identifier }
        XCTAssert(characteristic.isUpdating)
        XCTAssertNoThrow(try characteristic.update(withData: value))
        XCTAssertEqual(characteristic.value, value)
        XCTAssert(mock.updateValueCalled)
        XCTAssertEqual(centrals.count, 2)
        XCTAssert(centralIDs.contains(centralMock1.identifier))
        XCTAssert(centralIDs.contains(centralMock2.identifier))
        XCTAssertEqual(characteristic.pendingUpdates.count, 0)
    }

    func testUpdateValueWithData_WithSubscriberOnUnsubscribe_IsNotSendingUpdates() {
        let centralMock = CBCentralMock(maximumUpdateValueLength: 20)
        let (mock, peripheralManager, _) = addCharacteristics()
        let characteristic = peripheralManager.characteristics[0]
        let value = "aa".dataFromHexString()
        peripheralManager.didSubscribeToCharacteristic(characteristic.cbMutableChracteristic, central: centralMock)
        XCTAssertEqual(characteristic.subscribers.count, 1)
        peripheralManager.didUnsubscribeFromCharacteristic(characteristic.cbMutableChracteristic, central: centralMock)
        XCTAssertFalse(characteristic.isUpdating)
        XCTAssertNoThrow(try characteristic.update(withData: value))
        XCTAssertEqual(characteristic.value, value)
        XCTAssertFalse(mock.updateValueCalled)
        XCTAssertEqual(characteristic.subscribers.count, 0)
        XCTAssertEqual(characteristic.pendingUpdates.count, 1)
    }

    func testUpdateValueWithData_WithSubscribersWhenOneUnsubscribes_IsSendingUpdates() {
        let centralMock1 = CBCentralMock(maximumUpdateValueLength: 20)
        let centralMock2 = CBCentralMock(maximumUpdateValueLength: 20)
        let (mock, peripheralManager, _) = addCharacteristics()
        let characteristic = peripheralManager.characteristics[0]
        let value = "aa".dataFromHexString()
        peripheralManager.didSubscribeToCharacteristic(characteristic.cbMutableChracteristic, central: centralMock1)
        peripheralManager.didSubscribeToCharacteristic(characteristic.cbMutableChracteristic, central: centralMock2)
        XCTAssertEqual(characteristic.subscribers.count, 2)
        peripheralManager.didUnsubscribeFromCharacteristic(characteristic.cbMutableChracteristic, central: centralMock1)
        let centrals = characteristic.subscribers
        XCTAssert(characteristic.isUpdating)
        XCTAssertNoThrow(try characteristic.update(withData: value))
        XCTAssertEqual(characteristic.value, value)
        XCTAssert(mock.updateValueCalled)
        XCTAssertEqual(centrals.count, 1)
        XCTAssertEqual(centrals[0].identifier, centralMock2.identifier as UUID)
        XCTAssertEqual(characteristic.pendingUpdates.count, 0)
    }

    func testUpdateValueWithData_WithSubscriberWhenUpdateFailes_UpdatesAreSavedToPendingQueue() {
        let centralMock = CBCentralMock(maximumUpdateValueLength: 20)
        let (mock, peripheralManager, _) = addCharacteristics()
        let characteristic = peripheralManager.characteristics[0]
        let value1 = "aa".dataFromHexString()
        let value2 = "bb".dataFromHexString()
        peripheralManager.didSubscribeToCharacteristic(characteristic.cbMutableChracteristic, central: centralMock)
        XCTAssert(characteristic.isUpdating)
        XCTAssertEqual(characteristic.subscribers.count, 1)
        mock.updateValueReturn = false
        XCTAssertNoThrow(try characteristic.update(withData: value1))
        XCTAssertNoThrow(try characteristic.update(withData: value2))
        XCTAssertFalse(characteristic.isUpdating)
        XCTAssert(mock.updateValueCalled)
        XCTAssertEqual(characteristic.pendingUpdates.count, 2)
        XCTAssertEqual(characteristic.value, value2)
        XCTAssertEqual(characteristic.pendingUpdates.count, 2)
    }

    func testUpdateValueWithData_WithSubscriberAndPendingUpdatesThatResume_PendingUpdatesAreSent() {
        let centralMock = CBCentralMock(maximumUpdateValueLength: 20)
        let (mock, peripheralManager, _) = addCharacteristics()
        let characteristic = peripheralManager.characteristics[0]
        let value1 = "aa".dataFromHexString()
        let value2 = "bb".dataFromHexString()
        peripheralManager.didSubscribeToCharacteristic(characteristic.cbMutableChracteristic, central: centralMock)
        XCTAssert(characteristic.isUpdating)
        XCTAssertEqual(characteristic.subscribers.count, 1)
        XCTAssertNoThrow(try characteristic.update(withData: "11".dataFromHexString()))
        XCTAssertEqual(characteristic.pendingUpdates.count, 0)
        mock.updateValueReturn = false
        XCTAssertNoThrow(try characteristic.update(withData: value1))
        XCTAssertNoThrow(try characteristic.update(withData: value2))
        XCTAssertEqual(characteristic.pendingUpdates.count, 2)
        XCTAssertFalse(characteristic.isUpdating)
        XCTAssert(mock.updateValueCalled)
        XCTAssertEqual(characteristic.value, value2)
        mock.updateValueReturn = true
        peripheralManager.isReadyToUpdateSubscribers()
        XCTAssertEqual(characteristic.pendingUpdates.count, 0)
        XCTAssert(characteristic.isUpdating)
        XCTAssertEqual(characteristic.value, value2)
    }

    func testupdateValueWithData_WhenCharacteristicNotAddedToPeripheralManager_ThrowsUnconfigured() {
        let characteristic = MutableCharacteristic(profile: StringCharacteristicProfile<Gnosus.HelloWorldService.Greeting>())
        XCTAssertThrowError(try characteristic.update(withData: "11".dataFromHexString()), MutableCharacteristicError.unconfigured)
    }

    func testupdateValueWithData_WhenCharacteristicDoesNotNotify_ThrowsNotifyNotSupported() {
        let (_, peripheralManager, _) = addCharacteristics()
        let characteristic = peripheralManager.characteristics[1]
        XCTAssertThrowError(try characteristic.update(withData: "11".dataFromHexString()), MutableCharacteristicError.notifyNotSupported)
    }

    func testupdateValueWithString_WhenCharacteristicSerializationFails_ThrowsNotSerializable() {
        let (_, peripheralManager, _) = addCharacteristics()
        let characteristic = peripheralManager.characteristics[0]
        XCTAssertThrowError(try characteristic.update(withString: ["bad name" : "Invalid"]), MutableCharacteristicError.notSerializable)
    }
    
    func testUpdateValueWithData_WithDuplicateUUIDsAndNoSubscribers_AddsUpdateToPengingQueue() {
        let (mock, peripheralManager, _) = addDuplicateCharacteristics()
        let characteristic1 = peripheralManager.characteristics[0]
        let characteristic2 = peripheralManager.characteristics[1]
        XCTAssertFalse(characteristic1.isUpdating)
        XCTAssertEqual(characteristic1.subscribers.count, 0)
        XCTAssertNoThrow(try characteristic1.update(withData: "aa".dataFromHexString()))
        XCTAssertFalse(mock.updateValueCalled)
        XCTAssertEqual(characteristic1.pendingUpdates.count, 1)
        XCTAssertEqual(characteristic2.pendingUpdates.count, 0)
        XCTAssertNoThrow(try characteristic2.update(withData: "aa".dataFromHexString()))
        XCTAssertEqual(characteristic1.pendingUpdates.count, 1)
        XCTAssertEqual(characteristic2.pendingUpdates.count, 1)
    }

    func testUpdateValueWithData_WithDuplicateUUIDsWithSubscriber_IsSendingUpdates() {
        let centralMock = CBCentralMock(maximumUpdateValueLength: 20)
        let (mock, peripheralManager, _) = addDuplicateCharacteristics()
        let characteristic1 = peripheralManager.characteristics[0]
        let characteristic2 = peripheralManager.characteristics[1]
        let value = "aa".dataFromHexString()
        peripheralManager.didSubscribeToCharacteristic(characteristic1.cbMutableChracteristic, central: centralMock)
        XCTAssert(characteristic1.isUpdating)
        XCTAssertNoThrow(try characteristic1.update(withData: value))
        XCTAssert(mock.updateValueCalled)
        XCTAssertEqual(characteristic1.value, value)
        XCTAssertEqual(characteristic1.subscribers.count, 1)
        XCTAssertEqual(characteristic1.pendingUpdates.count, 0)
        peripheralManager.didSubscribeToCharacteristic(characteristic2.cbMutableChracteristic, central: centralMock)
        XCTAssert(characteristic2.isUpdating)
        XCTAssertNoThrow(try characteristic2.update(withData: value))
    }

    // MARK: Respond to write requests
    
    func testStartRespondingToWriteRequests_WhenRequestIsRecieved_CompletesSuccessfullyAndResponds() {
        let centralMock = CBCentralMock(maximumUpdateValueLength: 20)
        let (_, peripheralManager, _) = addCharacteristics()
        let characteristic = peripheralManager.characteristics[0]
        let value = "aa".dataFromHexString()
        let requestMock = CBATTRequestMock(characteristic: characteristic.cbMutableChracteristic, offset: 0, value: value)
        let future = characteristic.startRespondingToWriteRequests()
        peripheralManager.didReceiveWriteRequest(requestMock, central: centralMock)
        XCTAssertFutureStreamSucceeds(future, context: TestContext.immediate, validations: [{ (arg) in
                
                let (request, central) = arg
                characteristic.respondToRequest(request, withResult: CBATTError.Code.success)
                XCTAssertEqual(centralMock.identifier, central.identifier)
                XCTAssertEqual(request.getCharacteristic().uuid, characteristic.uuid)
                XCTAssertEqual(peripheralManager.result, CBATTError.Code.success)
                XCTAssertEqual(request.value, value)
                XCTAssert(peripheralManager.respondToRequestCalled)
            }
        ])
    }

    func testStartRespondingToWriteRequests_WhenMultipleRequestsAreReceived_CompletesSuccessfullyAndRespondstoAll() {
        let centralMock = CBCentralMock(maximumUpdateValueLength: 20)
        let (_, peripheralManager, _) = addCharacteristics()
        let characteristic = peripheralManager.characteristics[0]
        let values = ["aa".dataFromHexString(), "a1".dataFromHexString(), "a2".dataFromHexString(), "a3".dataFromHexString(), "a4".dataFromHexString(), "a5".dataFromHexString()]
        let requestMocks = values.map { CBATTRequestMock(characteristic: characteristic.cbMutableChracteristic, offset: 0, value: $0) }
        let future = characteristic.startRespondingToWriteRequests()
        for requestMock in requestMocks {
            peripheralManager.didReceiveWriteRequest(requestMock, central: centralMock)
        }
        XCTAssertFutureStreamSucceeds(future, context: TestContext.immediate, validations: [
             { (arg) in
                let (request, central) = arg
                characteristic.respondToRequest(request, withResult: CBATTError.Code.success)
                XCTAssertEqual(centralMock.identifier, central.identifier)
                XCTAssertEqual(request.getCharacteristic().uuid, characteristic.uuid)
                XCTAssertEqual(peripheralManager.result, CBATTError.Code.success)
                XCTAssertEqual(request.value, values[0])
                XCTAssert(peripheralManager.respondToRequestCalled)
            },
            { (arg) in
                let (request, central) = arg
                characteristic.respondToRequest(request, withResult: CBATTError.Code.success)
                XCTAssertEqual(centralMock.identifier, central.identifier)
                XCTAssertEqual(request.getCharacteristic().uuid, characteristic.uuid)
                XCTAssertEqual(peripheralManager.result, CBATTError.Code.success)
                XCTAssertEqual(request.value, values[1])
                XCTAssert(peripheralManager.respondToRequestCalled)
            },
            { (arg) in
                let (request, central) = arg
                characteristic.respondToRequest(request, withResult: CBATTError.Code.success)
                XCTAssertEqual(centralMock.identifier, central.identifier)
                XCTAssertEqual(request.getCharacteristic().uuid, characteristic.uuid)
                XCTAssertEqual(peripheralManager.result, CBATTError.Code.success)
                XCTAssertEqual(request.value, values[2])
                XCTAssert(peripheralManager.respondToRequestCalled)
            },
            { (arg) in
                let (request, central) = arg
                characteristic.respondToRequest(request, withResult: CBATTError.Code.success)
                XCTAssertEqual(centralMock.identifier, central.identifier)
                XCTAssertEqual(request.getCharacteristic().uuid, characteristic.uuid)
                XCTAssertEqual(peripheralManager.result, CBATTError.Code.success)
                XCTAssertEqual(request.value, values[3])
                XCTAssert(peripheralManager.respondToRequestCalled)
            },
            { (arg) in
                let (request, central) = arg
                characteristic.respondToRequest(request, withResult: CBATTError.Code.success)
                XCTAssertEqual(centralMock.identifier, central.identifier)
                XCTAssertEqual(request.getCharacteristic().uuid, characteristic.uuid)
                XCTAssertEqual(peripheralManager.result, CBATTError.Code.success)
                XCTAssertEqual(request.value, values[4])
                XCTAssert(peripheralManager.respondToRequestCalled)
            },
            { (arg) in
                let (request, central) = arg
                characteristic.respondToRequest(request, withResult: CBATTError.Code.success)
                XCTAssertEqual(centralMock.identifier, central.identifier)
                XCTAssertEqual(request.getCharacteristic().uuid, characteristic.uuid)
                XCTAssertEqual(peripheralManager.result, CBATTError.Code.success)
                XCTAssertEqual(request.value, values[5])
                XCTAssert(peripheralManager.respondToRequestCalled)
            }
        ])
    }

    func testStartRespondingToWriteRequests_WhenNotCalled_RespondsToRequestWithRequestNotSupported() {
        let centralMock = CBCentralMock(maximumUpdateValueLength: 20)
        let (_, peripheralManager, _) = addCharacteristics()
        let characteristic = peripheralManager.characteristics[0]
        let value = "aa".dataFromHexString()
        let request = CBATTRequestMock(characteristic: characteristic.cbMutableChracteristic, offset: 0, value: value)
        peripheralManager.didReceiveWriteRequest(request, central: centralMock)
        XCTAssertEqual(peripheralManager.result, CBATTError.Code.requestNotSupported)
        XCTAssert(peripheralManager.respondToRequestCalled)
    }

    func testStartRespondingToWriteRequests_WhenNotCalledAndCharacteristicNotAddedToService_RespondsToRequestWithUnlikelyError() {
        let centralMock = CBCentralMock(maximumUpdateValueLength: 20)
        let (_, peripheralManager) = createPeripheralManager(false, state: .poweredOn)
        let characteristic = MutableCharacteristic(profile: StringCharacteristicProfile<Gnosus.HelloWorldService.Greeting>())
        let request = CBATTRequestMock(characteristic: characteristic.cbMutableChracteristic, offset: 0, value: nil)
        let value = "aa".dataFromHexString()
        characteristic.value = value
        peripheralManager.didReceiveWriteRequest(request, central: centralMock)
        XCTAssertEqual(request.value, nil)
        XCTAssert(peripheralManager.respondToRequestCalled)
        XCTAssertEqual(peripheralManager.result, CBATTError.Code.unlikelyError)
    }

    func testStopRespondingToWriteRequests_WhenRespondingToWriteRequests_StopsRespondingToWriteRequests() {
        let centralMock = CBCentralMock(maximumUpdateValueLength: 20)
        let (_, peripheralManager, _) = addCharacteristics()
        let characteristic = peripheralManager.characteristics[0]
        let value = "aa".dataFromHexString()
        let request = CBATTRequestMock(characteristic: characteristic.cbMutableChracteristic, offset: 0, value: value)
        let future = characteristic.startRespondingToWriteRequests()
        characteristic.stopRespondingToWriteRequests()
        future.onSuccess(context: TestContext.immediate) {_ in
            XCTFail()
        }
        future.onFailure (context: TestContext.immediate) {error in
            XCTFail()
        }
        peripheralManager.didReceiveWriteRequest(request, central: centralMock)
        XCTAssert(peripheralManager.respondToRequestCalled)
        XCTAssertEqual(peripheralManager.result, CBATTError.Code.requestNotSupported)
    }

    func testStartRespondingToWriteRequests_WithDuplicateUUIDs_CompletesSuccessfullyAndResponds() {
        let centralMock = CBCentralMock(maximumUpdateValueLength: 20)
        let (_, peripheralManager, _) = addDuplicateCharacteristics()
        let characteristic1 = peripheralManager.characteristics[0]
        let characteristic2 = peripheralManager.characteristics[1]
        let value = "aa".dataFromHexString()
        let requestMock1 = CBATTRequestMock(characteristic: characteristic1.cbMutableChracteristic, offset: 0, value: value)
        let future1 = characteristic1.startRespondingToWriteRequests()
        peripheralManager.didReceiveWriteRequest(requestMock1, central: centralMock)
        XCTAssertFutureStreamSucceeds(future1, context: TestContext.immediate, validations: [{ (arg) in
            
            let (request, central) = arg
            characteristic1.respondToRequest(request, withResult: CBATTError.Code.success)
            XCTAssertEqual(centralMock.identifier, central.identifier)
            XCTAssertEqual(request.getCharacteristic().uuid, characteristic1.uuid)
            XCTAssertEqual(peripheralManager.result, CBATTError.Code.success)
            XCTAssertEqual(request.value, value)
            XCTAssert(peripheralManager.respondToRequestCalled)
            }
        ])
        let requestMock2 = CBATTRequestMock(characteristic: characteristic2.cbMutableChracteristic, offset: 0, value: value)
        let future2 = characteristic2.startRespondingToWriteRequests()
        peripheralManager.didReceiveWriteRequest(requestMock2, central: centralMock)
        XCTAssertFutureStreamSucceeds(future2, context: TestContext.immediate, validations: [{ (arg) in
            
            let (request, central) = arg
            characteristic1.respondToRequest(request, withResult: CBATTError.Code.success)
            XCTAssertEqual(centralMock.identifier, central.identifier)
            XCTAssertEqual(request.getCharacteristic().uuid, characteristic2.uuid)
            XCTAssertEqual(peripheralManager.result, CBATTError.Code.success)
            XCTAssertEqual(request.value, value)
            XCTAssert(peripheralManager.respondToRequestCalled)
            }
        ])
    }

    // MARK: Respond to read requests
    
    func testDidReceiveReadRequest_WhenCharacteristicIsInService_RespondsToRequest() {
        let centralMock = CBCentralMock(maximumUpdateValueLength: 20)
        let (_, peripheralManager, _) = addCharacteristics()
        let characteristic = peripheralManager.characteristics[0]
        let request = CBATTRequestMock(characteristic: characteristic.cbMutableChracteristic, offset: 0, value: nil)
        let value = "aa".dataFromHexString()
        characteristic.value = value
        peripheralManager.didReceiveReadRequest(request, central: centralMock)
        XCTAssertEqual(request.value, value)
        XCTAssert(peripheralManager.respondToRequestCalled)
        XCTAssertEqual(peripheralManager.result, CBATTError.Code.success)
    }
    
    func testDidReceiveReadRequest_WhenCharacteristicIsNotInService_RespondsWithUnlikelyError() {
        let centralMock = CBCentralMock(maximumUpdateValueLength: 20)
        let (_, peripheralManager) = createPeripheralManager(false, state: .poweredOn)
        let characteristic = MutableCharacteristic(profile: StringCharacteristicProfile<Gnosus.HelloWorldService.Greeting>())
        let request = CBATTRequestMock(characteristic: characteristic.cbMutableChracteristic, offset: 0, value: nil)
        let value = "aa".dataFromHexString()
        characteristic.value = value
        peripheralManager.didReceiveReadRequest(request, central: centralMock)
        XCTAssertEqual(request.value, nil)
        XCTAssert(peripheralManager.respondToRequestCalled)
        XCTAssertEqual(peripheralManager.result, CBATTError.Code.unlikelyError)
    }

    func testDidReceiveReadRequest_WithDuplicateUUIDs_RespondsToRequest() {
        let centralMock = CBCentralMock(maximumUpdateValueLength: 20)
        let (_, peripheralManager, _) = addDuplicateCharacteristics()
        let characteristic = peripheralManager.characteristics[0]
        let request = CBATTRequestMock(characteristic: characteristic.cbMutableChracteristic, offset: 0, value: nil)
        let value = "aa".dataFromHexString()
        characteristic.value = value
        peripheralManager.didReceiveReadRequest(request, central: centralMock)
        XCTAssertEqual(request.value, value)
        XCTAssert(peripheralManager.respondToRequestCalled)
        XCTAssertEqual(peripheralManager.result, CBATTError.Code.success)
    }

}
