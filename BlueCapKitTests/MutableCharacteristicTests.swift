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
import BlueCapKit

class MutableCharacteristicTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

//    func testNotSubscribeToUpdates() {
//        let mock = MutableCharacteristicMock(propertyEnabled:true)
//        XCTAssert(mock.impl.hasSubscriber == false, "hasSubscriber value invalid")
//        XCTAssert(mock.impl.isUpdating == false, "isUpdating value invalid")
//        XCTAssert(mock.impl.updateValueWithData(mock, value:"0".dataFromHexString()) == false, "updateValueWithData invalid return status")
//        XCTAssert(mock.updateCalled == false, "updateValueWithData not called")
//    }
//
//    func testSubscribeToUpdates() {
//        let mock = MutableCharacteristicMock(propertyEnabled:true, updateStatus:true)
//        mock.impl.didSubscribeToCharacteristic()
//        XCTAssert(mock.impl.hasSubscriber, "hasSubscriber value invalid")
//        XCTAssert(mock.impl.isUpdating, "isUpdating value invalid")
//        XCTAssert(mock.impl.updateValueWithData(mock, value:"0".dataFromHexString()), "updateValueWithData invalid return status")
//        XCTAssert(mock.updateCalled, "updateValueWithData not called")
//    }
//    
//    func testUnsubscribeToUpdates() {
//        let mock = MutableCharacteristicMock(propertyEnabled:true, updateStatus:true)
//        mock.impl.didSubscribeToCharacteristic()
//        mock.impl.didUnsubscribeFromCharacteristic()
//        XCTAssert(mock.impl.hasSubscriber == false, "hasSubscriber value invalid")
//        XCTAssert(mock.impl.isUpdating == false, "isUpdating value invalid")
//        XCTAssert(mock.impl.updateValueWithData(mock, value:"0".dataFromHexString()) == false, "updateValueWithData invalid return status")
//        XCTAssert(mock.updateCalled == false, "updateValueWithData called")
//    }
//    
//    func testSubscriberUpdateFailed() {
//        let mock = MutableCharacteristicMock(propertyEnabled:true, updateStatus:false)
//        mock.impl.didSubscribeToCharacteristic()
//        XCTAssert(mock.impl.hasSubscriber, "hasSubscriber not set")
//        XCTAssert(mock.impl.isUpdating, "isUpdating not set")
//        XCTAssert(mock.impl.updateValueWithData(mock, value:"0".dataFromHexString()) == false, "updateValueWithData invalid return status")
//        XCTAssert(mock.impl.isUpdating == false, "isUpdating not set")
//        XCTAssert(mock.updateCalled, "updateValueWithData not called")
//    }
//    
//    func testResumeSubscriberUpdates() {
//        let mock = MutableCharacteristicMock(propertyEnabled:true, updateStatus:false)
//        mock.impl.didSubscribeToCharacteristic()
//        XCTAssert(mock.impl.hasSubscriber, "hasSubscriber not set")
//        XCTAssert(mock.impl.updateValueWithData(mock, value:"0".dataFromHexString()) == false, "updateValueWithData invalid return status")
//        XCTAssert(mock.impl.isUpdating == false, "isUpdating not set")
//        XCTAssert(mock.updateCalled, "updateValueWithData not called")
//        mock.impl.peripheralManagerIsReadyToUpdateSubscribers()
//        XCTAssert(mock.impl.isUpdating, "isUpdating not set")
//    }
//    
//    func testStartRespondingToWriteRequests() {
//        let mock = MutableCharacteristicMock()
//        let expectation = expectationWithDescription("onFailure fulfilled for future")
//        let future = mock.impl.startRespondingToWriteRequests()
//        future.onSuccess {_ in
//            expectation.fulfill()
//        }
//        future.onFailure{error in
//            XCTAssert(false, "onFailure called")
//        }
//        PeripheralQueue.sync {
//            mock.impl.didRespondToWriteRequest(RequestMock())
//        }
//        waitForExpectationsWithTimeout(2) {error in
//            XCTAssertNil(error, "\(error)")
//        }
//    }
//
//    func testStopRespondingToWriteRequests() {
//        let mock = MutableCharacteristicMock()
//        let future = mock.impl.startRespondingToWriteRequests()
//        mock.impl.stopRespondingToWriteRequests()
//        future.onSuccess {_ in
//            XCTAssert(false, "onSuccess called")
//        }
//        future.onFailure{error in
//            XCTAssert(false, "onFailure called")
//        }
//        mock.impl.didRespondToWriteRequest(RequestMock())
//    }

}
