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

    func addCharacteristics(onSuccess: @escaping (_ mock: CBPeripheralManagerMock, _ peripheralManager: PeripheralManagerUT, _ service: MutableService) -> Void) {
        let (mock, peripheralManager) = createPeripheralManager(false, state: .poweredOn)
        let service = createPeripheralManagerService(peripheralManager)
        service.characteristics = service.profile.characteristics.map { profile in
            let characteristic = CBMutableCharacteristicMock(uuid: profile.uuid, properties: profile.properties, permissions: profile.permissions, isNotifying: false)
            return MutableCharacteristic(cbMutableCharacteristic: characteristic, profile: profile)
        }
        let future = peripheralManager.add(service)
        future.onSuccess(context: TestContext.immediate) {
            mock.isAdvertising = true
            onSuccess(mock, peripheralManager, service)
        }
        future.onFailure(context: TestContext.immediate) {error in
            XCTFail()
        }
        peripheralManager.didAddService(service.cbMutableService, error: nil)
    }

    // MARK: Add characteristics
    func testAddCharacteristics_WhenServiceAddWasSuccessfull_CompletesSuccessfully() {
        self.addCharacteristics {(mock: CBPeripheralManagerMock, peripheralManager: PeripheralManagerUT, service: MutableService) -> Void in
            let chracteristics = peripheralManager.characteristics.map { $0.uuid }
            XCTAssertEqual(chracteristics.count, 2)
            XCTAssert(chracteristics.contains(CBUUID(string: Gnosus.HelloWorldService.Greeting.uuid)))
            XCTAssert(chracteristics.contains(CBUUID(string: Gnosus.HelloWorldService.UpdatePeriod.uuid)))
        }
    }

    // MARK: Subscribe to charcteristic updates
    func testUpdateValueWithData_WithNoSubscribers_AddsUpdateToPengingQueue() {
        self.addCharacteristics {(mock: CBPeripheralManagerMock, peripheralManager: PeripheralManagerUT, service: MutableService) -> Void in
            let characteristic = peripheralManager.characteristics[0]
            XCTAssertFalse(characteristic.isUpdating)
            XCTAssertEqual(characteristic.subscribers.count, 0)
            XCTAssertFalse(characteristic.update(withData: "aa".dataFromHexString()))
            XCTAssertFalse(mock.updateValueCalled)
            XCTAssertEqual(characteristic.pendingUpdates.count, 1)
        }
    }

    func testUpdateValueWithData_WithSubscriber_IsSendingUpdates() {
        let centralMock = CBCentralMock(maximumUpdateValueLength: 20)
        self.addCharacteristics {(mock: CBPeripheralManagerMock, peripheralManager: PeripheralManagerUT, service: MutableService) -> Void in
            let characteristic = peripheralManager.characteristics[0]
            let value = "aa".dataFromHexString()
            peripheralManager.didSubscribeToCharacteristic(characteristic.cbMutableChracteristic, central: centralMock)
            XCTAssert(characteristic.isUpdating)
            XCTAssert(characteristic.update(withData: value))
            XCTAssert(mock.updateValueCalled)
            XCTAssertEqual(characteristic.value, value)
            XCTAssertEqual(characteristic.subscribers.count, 1)
            XCTAssertEqual(characteristic.pendingUpdates.count, 0)
        }
    }


    func testUpdateValueWithData_WithSubscribers_IsSendingUpdates() {
        let centralMock1 = CBCentralMock(maximumUpdateValueLength: 20)
        let centralMock2 = CBCentralMock(maximumUpdateValueLength: 20)
        self.addCharacteristics {(mock: CBPeripheralManagerMock, peripheralManager: PeripheralManagerUT, service: MutableService) -> Void in
            let characteristic = peripheralManager.characteristics[0]
            let value = "aa".dataFromHexString()
            peripheralManager.didSubscribeToCharacteristic(characteristic.cbMutableChracteristic, central: centralMock1)
            peripheralManager.didSubscribeToCharacteristic(characteristic.cbMutableChracteristic, central: centralMock2)
            let centrals = characteristic.subscribers
            let centralIDs = centrals.map { $0.identifier }
            XCTAssert(characteristic.isUpdating)
            XCTAssert(characteristic.update(withData: value))
            XCTAssertEqual(characteristic.value, value)
            XCTAssert(mock.updateValueCalled)
            XCTAssertEqual(centrals.count, 2)
            XCTAssert(centralIDs.contains(centralMock1.identifier))
            XCTAssert(centralIDs.contains(centralMock2.identifier))
            XCTAssertEqual(characteristic.pendingUpdates.count, 0)
        }
    }

    func testupdateValueWithData_WithSubscriberOnUnsubscribe_IsNotSendingUpdates() {
        let centralMock = CBCentralMock(maximumUpdateValueLength: 20)
        self.addCharacteristics {(mock: CBPeripheralManagerMock, peripheralManager: PeripheralManagerUT, service: MutableService) -> Void in
            let characteristic = peripheralManager.characteristics[0]
            let value = "aa".dataFromHexString()
            peripheralManager.didSubscribeToCharacteristic(characteristic.cbMutableChracteristic, central: centralMock)
            XCTAssertEqual(characteristic.subscribers.count, 1)
            peripheralManager.didUnsubscribeFromCharacteristic(characteristic.cbMutableChracteristic, central: centralMock)
            XCTAssertFalse(characteristic.isUpdating)
            XCTAssertFalse(characteristic.update(withData: value))
            XCTAssertEqual(characteristic.value, value)
            XCTAssertFalse(mock.updateValueCalled)
            XCTAssertEqual(characteristic.subscribers.count, 0)
            XCTAssertEqual(characteristic.pendingUpdates.count, 1)
        }
    }

    func testupdateValueWithData_WithSubscribersWhenOneUnsubscribes_IsSendingUpdates() {
        let centralMock1 = CBCentralMock(maximumUpdateValueLength: 20)
        let centralMock2 = CBCentralMock(maximumUpdateValueLength: 20)
        self.addCharacteristics {(mock: CBPeripheralManagerMock, peripheralManager: PeripheralManagerUT, service: MutableService) -> Void in
            let characteristic = peripheralManager.characteristics[0]
            let value = "aa".dataFromHexString()
            peripheralManager.didSubscribeToCharacteristic(characteristic.cbMutableChracteristic, central: centralMock1)
            peripheralManager.didSubscribeToCharacteristic(characteristic.cbMutableChracteristic, central: centralMock2)
            XCTAssertEqual(characteristic.subscribers.count, 2)
            peripheralManager.didUnsubscribeFromCharacteristic(characteristic.cbMutableChracteristic, central: centralMock1)
            let centrals = characteristic.subscribers
            XCTAssert(characteristic.isUpdating)
            XCTAssert(characteristic.update(withData: value))
            XCTAssertEqual(characteristic.value, value)
            XCTAssert(mock.updateValueCalled)
            XCTAssertEqual(centrals.count, 1)
            XCTAssertEqual(centrals[0].identifier, centralMock2.identifier as UUID)
            XCTAssertEqual(characteristic.pendingUpdates.count, 0)
        }
    }

    func testupdateValueWithData_WithSubscriberWhenUpdateFailes_UpdatesAreSavedToPendingQueue() {
        let centralMock = CBCentralMock(maximumUpdateValueLength: 20)
        self.addCharacteristics {(mock: CBPeripheralManagerMock, peripheralManager: PeripheralManagerUT, service: MutableService) -> Void in
            let characteristic = peripheralManager.characteristics[0]
            let value1 = "aa".dataFromHexString()
            let value2 = "bb".dataFromHexString()
            peripheralManager.didSubscribeToCharacteristic(characteristic.cbMutableChracteristic, central: centralMock)
            XCTAssert(characteristic.isUpdating)
            XCTAssertEqual(characteristic.subscribers.count, 1)
            mock.updateValueReturn = false
            XCTAssertFalse(characteristic.update(withData: value1))
            XCTAssertFalse(characteristic.update(withData: value2))
            XCTAssertFalse(characteristic.isUpdating)
            XCTAssert(mock.updateValueCalled)
            XCTAssertEqual(characteristic.pendingUpdates.count, 2)
            XCTAssertEqual(characteristic.value, value2)
            XCTAssertEqual(characteristic.pendingUpdates.count, 2)
        }
    }

    func testupdateValueWithData_WithSubscriberWithPendingUpdatesThatResume_PendingUpdatesAreSent() {
        let centralMock = CBCentralMock(maximumUpdateValueLength: 20)
        self.addCharacteristics {(mock: CBPeripheralManagerMock, peripheralManager: PeripheralManagerUT, service: MutableService) -> Void in
            let characteristic = peripheralManager.characteristics[0]
            let value1 = "aa".dataFromHexString()
            let value2 = "bb".dataFromHexString()
            peripheralManager.didSubscribeToCharacteristic(characteristic.cbMutableChracteristic, central: centralMock)
            XCTAssert(characteristic.isUpdating)
            XCTAssertEqual(characteristic.subscribers.count, 1)
            XCTAssert(characteristic.update(withData: "11".dataFromHexString()))
            XCTAssertEqual(characteristic.pendingUpdates.count, 0)
            mock.updateValueReturn = false
            XCTAssertFalse(characteristic.update(withData: value1))
            XCTAssertFalse(characteristic.update(withData: value2))
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
    }

    func testupdateValueWithData_WithPendingUpdatesPriorToSubscriber_SEndPensingUpdates() {
        let centralMock = CBCentralMock(maximumUpdateValueLength: 20)
        self.addCharacteristics {(mock: CBPeripheralManagerMock, peripheralManager: PeripheralManagerUT, service: MutableService) -> Void in
            let characteristic = peripheralManager.characteristics[0]
            let value1 = "aa".dataFromHexString()
            let value2 = "bb".dataFromHexString()
            XCTAssertFalse(characteristic.isUpdating)
            XCTAssertFalse(characteristic.update(withData: value1))
            XCTAssertFalse(characteristic.update(withData: value2))
            XCTAssertFalse(mock.updateValueCalled)
            XCTAssertEqual(characteristic.value, value2)
            XCTAssertEqual(characteristic.subscribers.count, 0)
            XCTAssertEqual(characteristic.pendingUpdates.count, 2)
            peripheralManager.didSubscribeToCharacteristic(characteristic.cbMutableChracteristic, central: centralMock)
            XCTAssertEqual(characteristic.subscribers.count, 1)
            XCTAssertEqual(characteristic.pendingUpdates.count, 0)
            XCTAssert(mock.updateValueCalled)
        }
    }


    // MARK: Respond to write requests
    func testStartRespondingToWriteRequests_WhenRequestIsRecieved_CompletesSuccessfullyAndResponds() {
        let centralMock = CBCentralMock(maximumUpdateValueLength: 20)
        var peripheralManagerUT: PeripheralManagerUT?
        self.addCharacteristics {(mock: CBPeripheralManagerMock, peripheralManager: PeripheralManagerUT, service: MutableService) -> Void in
            peripheralManagerUT = peripheralManager
        }
        if let peripheralManagerUT = peripheralManagerUT {
            let characteristic = peripheralManagerUT.characteristics[0]
            let value = "aa".dataFromHexString()
            let requestMock = CBATTRequestMock(characteristic: characteristic.cbMutableChracteristic, offset: 0, value: value)
            let future = characteristic.startRespondingToWriteRequests()
            peripheralManagerUT.didReceiveWriteRequest(requestMock, central: centralMock)
            XCTAssertFutureStreamSucceeds(future, context: TestContext.immediate, validations: [{ (request, central) in
                    characteristic.respondToRequest(request, withResult: CBATTError.Code.success)
                    XCTAssertEqual(centralMock.identifier, central.identifier)
                    XCTAssertEqual(request.getCharacteristic().uuid, characteristic.uuid)
                    XCTAssertEqual(peripheralManagerUT.result, CBATTError.Code.success)
                    XCTAssertEqual(request.value, value)
                    XCTAssert(peripheralManagerUT.respondToRequestCalled)
                }
            ])
        } else {
            XCTFail("peripheralManagerUT is nil")
        }

    }

    func testStartRespondingToWriteRequests_WhenMultipleRequestsAreReceived_CompletesSuccessfullyAndRespondstoAll() {
        let centralMock = CBCentralMock(maximumUpdateValueLength: 20)
        var peripheralManagerUT: PeripheralManagerUT?
        self.addCharacteristics {(mock: CBPeripheralManagerMock, peripheralManager: PeripheralManagerUT, service: MutableService) -> Void in
            peripheralManagerUT = peripheralManager
        }
        if let peripheralManagerUT = peripheralManagerUT {
            let characteristic = peripheralManagerUT.characteristics[0]
            let values = ["aa".dataFromHexString(), "a1".dataFromHexString(), "a2".dataFromHexString(), "a3".dataFromHexString(), "a4".dataFromHexString(), "a5".dataFromHexString()]
            let requestMocks = values.map { CBATTRequestMock(characteristic: characteristic.cbMutableChracteristic, offset: 0, value: $0) }
            let future = characteristic.startRespondingToWriteRequests()
            for requestMock in requestMocks {
                peripheralManagerUT.didReceiveWriteRequest(requestMock, central: centralMock)
            }
            XCTAssertFutureStreamSucceeds(future, context: TestContext.immediate, validations: [
                 { (request, central) in
                    characteristic.respondToRequest(request, withResult: CBATTError.Code.success)
                    XCTAssertEqual(centralMock.identifier, central.identifier)
                    XCTAssertEqual(request.getCharacteristic().uuid, characteristic.uuid)
                    XCTAssertEqual(peripheralManagerUT.result, CBATTError.Code.success)
                    XCTAssertEqual(request.value, values[0])
                    XCTAssert(peripheralManagerUT.respondToRequestCalled)
                },
                { (request, central) in
                    characteristic.respondToRequest(request, withResult: CBATTError.Code.success)
                    XCTAssertEqual(centralMock.identifier, central.identifier)
                    XCTAssertEqual(request.getCharacteristic().uuid, characteristic.uuid)
                    XCTAssertEqual(peripheralManagerUT.result, CBATTError.Code.success)
                    XCTAssertEqual(request.value, values[1])
                    XCTAssert(peripheralManagerUT.respondToRequestCalled)
                },
                { (request, central) in
                    characteristic.respondToRequest(request, withResult: CBATTError.Code.success)
                    XCTAssertEqual(centralMock.identifier, central.identifier)
                    XCTAssertEqual(request.getCharacteristic().uuid, characteristic.uuid)
                    XCTAssertEqual(peripheralManagerUT.result, CBATTError.Code.success)
                    XCTAssertEqual(request.value, values[2])
                    XCTAssert(peripheralManagerUT.respondToRequestCalled)
                },
                { (request, central) in
                    characteristic.respondToRequest(request, withResult: CBATTError.Code.success)
                    XCTAssertEqual(centralMock.identifier, central.identifier)
                    XCTAssertEqual(request.getCharacteristic().uuid, characteristic.uuid)
                    XCTAssertEqual(peripheralManagerUT.result, CBATTError.Code.success)
                    XCTAssertEqual(request.value, values[3])
                    XCTAssert(peripheralManagerUT.respondToRequestCalled)
                },
                { (request, central) in
                    characteristic.respondToRequest(request, withResult: CBATTError.Code.success)
                    XCTAssertEqual(centralMock.identifier, central.identifier)
                    XCTAssertEqual(request.getCharacteristic().uuid, characteristic.uuid)
                    XCTAssertEqual(peripheralManagerUT.result, CBATTError.Code.success)
                    XCTAssertEqual(request.value, values[4])
                    XCTAssert(peripheralManagerUT.respondToRequestCalled)
                },
                { (request, central) in
                    characteristic.respondToRequest(request, withResult: CBATTError.Code.success)
                    XCTAssertEqual(centralMock.identifier, central.identifier)
                    XCTAssertEqual(request.getCharacteristic().uuid, characteristic.uuid)
                    XCTAssertEqual(peripheralManagerUT.result, CBATTError.Code.success)
                    XCTAssertEqual(request.value, values[5])
                    XCTAssert(peripheralManagerUT.respondToRequestCalled)
                }
            ])
        } else {
            XCTFail()
        }
    }

    func testStartRespondingToWriteRequests_WhenNotCalled_RespondsToRequestWithRequestNotSupported() {
        let centralMock = CBCentralMock(maximumUpdateValueLength: 20)
        self.addCharacteristics {(mock: CBPeripheralManagerMock, peripheralManager: PeripheralManagerUT, service: MutableService) -> Void in
            let characteristic = peripheralManager.characteristics[0]
            let value = "aa".dataFromHexString()
            let request = CBATTRequestMock(characteristic: characteristic.cbMutableChracteristic, offset: 0, value: value)
            peripheralManager.didReceiveWriteRequest(request, central: centralMock)
            XCTAssertEqual(peripheralManager.result, CBATTError.Code.requestNotSupported)
            XCTAssert(peripheralManager.respondToRequestCalled)
        }
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
        var peripheralManagerUT: PeripheralManagerUT?
        self.addCharacteristics {(mock: CBPeripheralManagerMock, peripheralManager: PeripheralManagerUT, service: MutableService) -> Void in
            peripheralManagerUT = peripheralManager
        }
        if let peripheralManagerUT = peripheralManagerUT {
            let characteristic = peripheralManagerUT.characteristics[0]
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
            peripheralManagerUT.didReceiveWriteRequest(request, central: centralMock)
            XCTAssert(peripheralManagerUT.respondToRequestCalled)
            XCTAssertEqual(peripheralManagerUT.result, CBATTError.Code.requestNotSupported)
        } else {
            XCTFail()
        }
    }

    // MARK: Respond to read requests
    func testDidReceiveReadRequest_WhenCharacteristicIsInService_RespondsToRequest() {
        let centralMock = CBCentralMock(maximumUpdateValueLength: 20)
        self.addCharacteristics {(mock: CBPeripheralManagerMock, peripheralManager: PeripheralManagerUT, service: MutableService) -> Void in
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

}
