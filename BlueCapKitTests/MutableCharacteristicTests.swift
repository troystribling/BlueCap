//
//  MutableCharacteristicTests.swift
//  BlueCapKit
//
//  Created by Troy Stribling on 3/24/15.
//  Copyright (c) 2015 gnos.us. All rights reserved.
//

import UIKit
import XCTest
import CoreBluetooth
import BlueCapKit

class MutableCharacteristicTests: XCTestCase {

    // MutableCharacteristicMock
    class MutableCharacteristicMock : MutableCharacteristicWrappable {

        var impl = MutableCharacteristicImpl<MutableCharacteristicMock>()
        
        var _propertyEnabled : Bool
        var _permissionEnabled : Bool

        var _value =  "01".dataFromHexString()
        
        var uuid : CBUUID {
            return CBUUID(string:"2f0a0017-69aa-f316-3e78-4194989a6c1a")
        }
        
        var name : String {
            return "Mock"
        }
        
        var value : NSData! {
            return self._value
        }
        
        var stringValues : [String] {
            return []
        }
        
        var stringValue : [String:String]? {
            return ["Mock":"1"]
        }
        
        init(propertyEnabled:Bool=false, permissionEnabled:Bool=false) {
            self._propertyEnabled = propertyEnabled
            self._permissionEnabled = permissionEnabled
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
        
        func updateValueWithData(value:NSData) {
            self._value = value
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

    func testStartRespondingToWriteRequests() {
        let mock = MutableCharacteristicMock()
        let expectation = expectationWithDescription("onFailure fulfilled for future")
        let future = mock.impl.startRespondingToWriteRequests()
        future.onSuccess {_ in
            expectation.fulfill()
        }
        future.onFailure{error in
            XCTAssert(false, "onFailure called")
        }
        PeripheralQueue.sync {
            mock.impl.didRespondToWriteRequest(RequestMock())
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testStopRespondingToWriteRequests() {
        let mock = MutableCharacteristicMock()
        let future = mock.impl.startRespondingToWriteRequests()
        mock.impl.stopProcessingWriteRequests()
        future.onSuccess {_ in
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure{error in
            XCTAssert(false, "onFailure called")
        }
        mock.impl.didRespondToWriteRequest(RequestMock())
    }

}
