//
//  CharacteristicTests.swift
//  BlueCapKit
//
//  Created by Troy Stribling on 1/7/15.
//  Copyright (c) 2015 gnos.us. All rights reserved.
//

import UIKit
import XCTest
import CoreBluetooth
import BlueCapKit

struct TestFailure {
    static let error = NSError(domain:"BlueCapKit Tests", code:100, userInfo:[NSLocalizedDescriptionKey:"Testing"])
}

class CharacteristicTests: XCTestCase {

    // CharacteristicMock
    struct MockValues {
        static var isNotifying             = false
        static var stringValues            = [String]()
        static var propertyEnabled         = true
        static var stringValue             = ["Mock":"1"]
        static var dataFromStringValue     = "01".dataFromHexString()
        static var connectorator           = Connectorator()
        static var afterDiscoveredPromise  = StreamPromise<CharacteristicMock>()
    }
    
    struct CharacteristicMock : CharacteristicWrappable {
        
        var uuid : CBUUID! {
            return CBUUID(string:"2f0a0017-69aa-f316-3e78-4194989a6c1a")
        }
        
        var name : String {
            return "Mock"
        }
        
        var connectorator : Connectorator? {
            return MockValues.connectorator
        }
        
        var isNotifying : Bool {
            return MockValues.isNotifying
        }
        
        var stringValues : [String] {
            return MockValues.stringValues
        }
        
        var afterDiscoveredPromise  : StreamPromise<CharacteristicMock>? {
            return MockValues.afterDiscoveredPromise
        }
        
        func stringValue(data:NSData?) -> [String:String]? {
            return MockValues.stringValue
        }
        
        func dataFromStringValue(stringValue:[String:String]) -> NSData? {
            return MockValues.dataFromStringValue
        }
        
        func setNotifyValue(state:Bool) {
            MockValues.isNotifying = state
        }
        
        func propertyEnabled(property:CBCharacteristicProperties) -> Bool {
            return MockValues.propertyEnabled
        }
        
        func readValueForCharacteristic() {
        }
        
        func writeValue(value:NSData) {
        }
    }
    
    let impl = CharacteristicImpl<CharacteristicMock>()
    let mock = CharacteristicMock()
    
    // CharacteristicMock
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testDiscovered() {
        let onSuccessExpectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = MockValues.afterDiscoveredPromise.future
        future.onSuccess {characteristic in
            onSuccessExpectation.fulfill()
        }
        future.onFailure {error in
            XCTAssert(false, "onFailure called")
        }
        self.impl.didDiscover(self.mock)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testWriteDataSuccess() {
        let onSuccessExpectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = self.impl.writeData(self.mock, value:"aa".dataFromHexString())
        future.onSuccess {characteristic in
            onSuccessExpectation.fulfill()
        }
        future.onFailure {error in
            XCTAssert(false, "onFailure called")
        }
        self.impl.didWrite(self.mock, error:nil)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testWriteDataFailed() {
        let onFailureExpectation = expectationWithDescription("onFailure fulfilled for future")
        let future = self.impl.writeData(self.mock, value:"aa".dataFromHexString())
        future.onSuccess {characteristic in
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure {error in
            onFailureExpectation.fulfill()
        }
        self.impl.didWrite(self.mock, error:TestFailure.error)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testWriteDataTimeOut() {
        let onFailureExpectation = expectationWithDescription("onFailure fulfilled for future")
        let future = self.impl.writeData(self.mock, value:"aa".dataFromHexString())
        future.onSuccess {characteristic in
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

    func testWriteDataNotWrteable() {
        MockValues.propertyEnabled = false
        let onFailureExpectation = expectationWithDescription("onFailure fulfilled for future")
        let future = self.impl.writeData(self.mock, value:"aa".dataFromHexString())
        future.onSuccess {characteristic in
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure {error in
            onFailureExpectation.fulfill()
            XCTAssert(error.code == CharacteristicError.WriteNotSupported.rawValue, "Error code invalid")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
        MockValues.propertyEnabled = true
    }

    func testWriteStringSuccess() {
        let onSuccessExpectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = self.impl.writeString(self.mock, stringValue:["Mock":"1"])
        future.onSuccess {characteristic in
            onSuccessExpectation.fulfill()
        }
        future.onFailure {error in
            XCTAssert(false, "onFailure called")
        }
        self.impl.didWrite(self.mock, error:nil)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testWriteStringFailed() {
        let onFailureExpectation = expectationWithDescription("onFailure fulfilled for future")
        let future = self.impl.writeString(self.mock, stringValue:["Mock":"1"])
        future.onSuccess {characteristic in
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure {error in
            onFailureExpectation.fulfill()
        }
        self.impl.didWrite(self.mock, error:TestFailure.error)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testWriteStringTimeOut() {
        let onFailureExpectation = expectationWithDescription("onFailure fulfilled for future")
        let future = self.impl.writeString(self.mock, stringValue:["Mock":"1"])
        future.onSuccess {characteristic in
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

    func testWriteStringNotWrteable() {
        MockValues.propertyEnabled = false
        let onFailureExpectation = expectationWithDescription("onFailure fulfilled for future")
        let future = self.impl.writeString(self.mock, stringValue:["Mock":"1"])
        future.onSuccess {characteristic in
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure {error in
            onFailureExpectation.fulfill()
            XCTAssert(error.code == CharacteristicError.WriteNotSupported.rawValue, "Error code invalid")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
        MockValues.propertyEnabled = true
    }
    
    func testReadSuccess() {
        let onSuccessExpectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = self.impl.read(self.mock)
        future.onSuccess {characteristic in
            onSuccessExpectation.fulfill()
        }
        future.onFailure {error in
            XCTAssert(false, "onFailure called")
        }
        self.impl.didUpdate(self.mock, error:nil)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testReadFailure() {
        let onFailureExpectation = expectationWithDescription("onFailure fulfilled for future")
        let future = self.impl.read(self.mock)
        future.onSuccess {characteristic in
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure {error in
            onFailureExpectation.fulfill()
        }
        self.impl.didUpdate(self.mock, error:TestFailure.error)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testReadTimeout() {
        let onFailureExpectation = expectationWithDescription("onFailure fulfilled for future")
        let future = self.impl.read(self.mock)
        future.onSuccess {characteristic in
            XCTAssert(false, "onFailure called")
        }
        future.onFailure {error in
            onFailureExpectation.fulfill()
            XCTAssert(error.code == CharacteristicError.ReadTimeout.rawValue, "Error code invalid")
        }
        waitForExpectationsWithTimeout(20) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testReadNotReadable() {
        MockValues.propertyEnabled = false
        let onFailureExpectation = expectationWithDescription("onFailure fulfilled for future")
        let future = self.impl.read(self.mock)
        future.onSuccess {characteristic in
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure {error in
            onFailureExpectation.fulfill()
            XCTAssert(error.code == CharacteristicError.ReadNotSupported.rawValue, "Error code invalid")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
        MockValues.propertyEnabled = true
    }
    
    func testStartNotifyingSucceess() {
        let onSuccessExpectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = self.impl.startNotifying(self.mock)
        future.onSuccess {characteristic in
            onSuccessExpectation.fulfill()
        }
        future.onFailure {error in
            XCTAssert(false, "onFailure called")
        }
        self.impl.didUpdateNotificationState(self.mock, error:nil)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testStartNotifyingFailure() {
        let onFailureExpectation = expectationWithDescription("onFailure fulfilled for future")
        let future = self.impl.startNotifying(self.mock)
        future.onSuccess {characteristic in
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure {error in
            onFailureExpectation.fulfill()
        }
        self.impl.didUpdateNotificationState(self.mock, error:TestFailure.error)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testReceiveNotificationUpdateSuccess() {
        let onSuccessExpectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = self.impl.startNotifying(self.mock).foreach{characteristic in
            return self.impl.recieveNotificationUpdates()
        }
        future.onSuccess {characteristic in
            onSuccessExpectation.fulfill()
        }
        future.onFailure {error in
            XCTAssert(false, "onFailure called")
        }
        self.impl.didUpdateNotificationState(self.mock, error:nil)
        self.impl.didUpdate(self.mock, error:nil)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

//    func testReceiveNotificationUpdateFailure() {
//        let onFailureExpectation = expectationWithDescription("onFailure fulfilled for future")
//        let future = self.impl.startNotifying(self.mock).flatmap{(characteristic:CharacteristicMock) -> Future<CharacteristicMock> in
//            return self.impl.recieveNotificationUpdates()
//        }
//        future.onSuccess {characteristic in
//            XCTAssert(false, "onSuccess called")
//        }
//        future.onFailure {error in
//            onFailureExpectation.fulfill()
//        }
//        self.impl.didUpdateNotificationState(self.mock, error:nil)
//        self.impl.didUpdate(self.mock, error:TestFailure.error)
//        waitForExpectationsWithTimeout(2) {error in
//            XCTAssertNil(error, "\(error)")
//        }
//    }
//
//    func testReceivingNotificationUpdates() {
//        
//    }
//    
//    func testStopNotifyingSuccess() {
//        let onSuccessExpectation = expectationWithDescription("onSuccess fulfilled for future")
//        let future = self.impl.stopNotifying(self.mock)
//        self.impl.stopNotifying(self.mock)
//        future.onSuccess {characteristic in
//            onSuccessExpectation.fulfill()
//        }
//        future.onFailure {error in
//            XCTAssert(false, "onFailure called")
//        }
//        self.impl.didUpdate(self.mock, error:nil)
//        waitForExpectationsWithTimeout(2) {error in
//            XCTAssertNil(error, "\(error)")
//        }
//    }

}
