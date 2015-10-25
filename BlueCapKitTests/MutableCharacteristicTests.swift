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

    // MutableCharacteristicMock
    class MutableCharacteristicMock : MutableCharacteristicWrappable {

        var impl = MutableCharacteristicImpl<MutableCharacteristicMock>()

        var updateCalled        = false

        var _propertyEnabled    : Bool
        var _permissionEnabled  : Bool
        var _updateStatus       : Bool

        var value : NSData? =  "01".dataFromHexString()
        
        var uuid : CBUUID {
            return CBUUID(string:"2f0a0017-69aa-f316-3e78-4194989a6c1a")
        }
        
        var name : String {
            return "Mock"
        }
        
        var stringValues : [String] {
            return []
        }
        
        var stringValue : [String:String]? {
            return ["Mock":"1"]
        }
        
        init(propertyEnabled:Bool=false, permissionEnabled:Bool=false, updateStatus:Bool=true) {
            self._propertyEnabled = propertyEnabled
            self._permissionEnabled = permissionEnabled
            self._updateStatus = updateStatus
        }
        
        func propertyEnabled(property:CBCharacteristicProperties) -> Bool {
            return self._propertyEnabled
        }
        
        func permissionEnabled(permission:CBAttributePermissions) -> Bool {
            return self._permissionEnabled
        }
        
        func dataFromStringValue(stringValue:[String:String]) -> NSData? {
            if let val = stringValue["Mock"] {
                return val.dataFromHexString()
            } else {
                return nil
            }
        }
        
        func updateValueWithData(value:NSData) -> Bool {
            self.value = value
            self.updateCalled = true
            return self._updateStatus
        }
        
        func respondToWrappedRequest(request:RequestMock, withResult result:ResultMock) {
        }

    }
    
    class RequestMock : CBATTRequestWrappable {
        
    }
    
    class ResultMock : CBATTErrorWrappable {
        
    }
    
    // MutableCharacteristicMock

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
