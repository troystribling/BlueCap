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
import CoreLocation
import BlueCapKit

class CharacteristicTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testDiscovered() {
        let mock = CharacteristicMock()
        let onSuccessExpectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = mock.afterDiscoveredPromise?.future
        future!.onSuccess {_ in
            onSuccessExpectation.fulfill()
        }
        future!.onFailure {error in
            XCTAssert(false, "onFailure called")
        }
        CentralQueue.async {
            mock.impl.didDiscover(mock)
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testWriteDataSuccess() {
        let mock = CharacteristicMock()
        let onSuccessExpectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = mock.impl.writeData(mock, value:"aa".dataFromHexString())
        future.onSuccess {_ in
            onSuccessExpectation.fulfill()
        }
        future.onFailure {error in
            XCTAssert(false, "onFailure called")
        }
        CentralQueue.async {
            mock.impl.didWrite(mock, error:nil)
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testWriteDataFailed() {
        let mock = CharacteristicMock()
        let onFailureExpectation = expectationWithDescription("onFailure fulfilled for future")
        let future = mock.impl.writeData(mock, value:"aa".dataFromHexString())
        future.onSuccess {_ in
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure {error in
            onFailureExpectation.fulfill()
        }
        CentralQueue.async {
            mock.impl.didWrite(mock, error:TestFailure.error)
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testWriteDataTimeOut() {
        let mock = CharacteristicMock()
        let onFailureExpectation = expectationWithDescription("onFailure fulfilled for future")
        let future = mock.impl.writeData(mock, value:"aa".dataFromHexString())
        future.onSuccess {_ in
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
        let mock = CharacteristicMock(propertyEnabled:false)
        let onFailureExpectation = expectationWithDescription("onFailure fulfilled for future")
        let future = mock.impl.writeData(mock, value:"aa".dataFromHexString())
        future.onSuccess {_ in
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure {error in
            onFailureExpectation.fulfill()
            XCTAssert(error.code == CharacteristicError.WriteNotSupported.rawValue, "Error code invalid")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testWriteStringSuccess() {
        let mock = CharacteristicMock()
        let onSuccessExpectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = mock.impl.writeString(mock, stringValue:["Mock":"1"])
        future.onSuccess {_ in
            onSuccessExpectation.fulfill()
        }
        future.onFailure {error in
            XCTAssert(false, "onFailure called")
        }
        CentralQueue.async {
            mock.impl.didWrite(mock, error:nil)
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testWriteStringFailed() {
        let mock = CharacteristicMock()
        let onFailureExpectation = expectationWithDescription("onFailure fulfilled for future")
        let future = mock.impl.writeString(mock, stringValue:["Mock":"1"])
        future.onSuccess {_ in
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure {error in
            onFailureExpectation.fulfill()
        }
        CentralQueue.async {
            mock.impl.didWrite(mock, error:TestFailure.error)
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testWriteStringTimeOut() {
        let mock = CharacteristicMock()
        let onFailureExpectation = expectationWithDescription("onFailure fulfilled for future")
        let future = mock.impl.writeString(mock, stringValue:["Mock":"1"])
        future.onSuccess {_ in
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
        let mock = CharacteristicMock(propertyEnabled:false)
        let onFailureExpectation = expectationWithDescription("onFailure fulfilled for future")
        let future = mock.impl.writeString(mock, stringValue:["Mock":"1"])
        future.onSuccess {_ in
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure {error in
            onFailureExpectation.fulfill()
            XCTAssert(error.code == CharacteristicError.WriteNotSupported.rawValue, "Error code invalid")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testReadSuccess() {
        let mock = CharacteristicMock()
        let onSuccessExpectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = mock.impl.read(mock)
        future.onSuccess {_ in
            onSuccessExpectation.fulfill()
        }
        future.onFailure {error in
            XCTAssert(false, "onFailure called")
        }
        CentralQueue.async {
            mock.impl.didUpdate(mock, error:nil)
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testReadFailure() {
        let mock = CharacteristicMock()
        let onFailureExpectation = expectationWithDescription("onFailure fulfilled for future")
        let future = mock.impl.read(mock)
        future.onSuccess {_ in
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure {error in
            onFailureExpectation.fulfill()
        }
        CentralQueue.async {
            mock.impl.didUpdate(mock, error:TestFailure.error)
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testReadTimeout() {
        let mock = CharacteristicMock()
        let onFailureExpectation = expectationWithDescription("onFailure fulfilled for future")
        let future = mock.impl.read(mock)
        future.onSuccess {_ in
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
        let mock = CharacteristicMock(propertyEnabled:false)
        let onFailureExpectation = expectationWithDescription("onFailure fulfilled for future")
        let future = mock.impl.read(mock)
        future.onSuccess {_ in
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure {error in
            onFailureExpectation.fulfill()
            XCTAssert(error.code == CharacteristicError.ReadNotSupported.rawValue, "Error code invalid")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testStartNotifyingSucceess() {
        let mock = CharacteristicMock()
        let onSuccessExpectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = mock.impl.startNotifying(mock)
        future.onSuccess {_ in
            onSuccessExpectation.fulfill()
        }
        future.onFailure {error in
            XCTAssert(false, "onFailure called")
        }
        CentralQueue.async {
            mock.impl.didUpdateNotificationState(mock, error:nil)
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testStartNotifyingFailure() {
        let mock = CharacteristicMock()
        let onFailureExpectation = expectationWithDescription("onFailure fulfilled for future")
        let future = mock.impl.startNotifying(mock)
        future.onSuccess {_ in
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure {error in
            onFailureExpectation.fulfill()
        }
        CentralQueue.async {
            mock.impl.didUpdateNotificationState(mock, error:TestFailure.error)
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testReceiveNotificationUpdateSuccess() {
        let mock = CharacteristicMock()
        let startNotifyingOnSuccessExpectation = expectationWithDescription("onSuccess fulfilled for future start notifying")
        let updateOnSuccessExpectation = expectationWithDescription("onSuccess fulfilled for future on update")

        let startNotifyingFuture = mock.impl.startNotifying(mock)
        mock.impl.didUpdateNotificationState(mock, error:nil)
        
        startNotifyingFuture.onSuccess{_ in
            startNotifyingOnSuccessExpectation.fulfill()
        }
        startNotifyingFuture.onFailure{_ in
            XCTAssert(false, "start notifying onFailure called")
        }
        let updateFuture = startNotifyingFuture.flatmap{_ -> FutureStream<CharacteristicMock> in
            let future = mock.impl.recieveNotificationUpdates()
            CentralQueue.async {
                mock.impl.didUpdate(mock, error:nil)
            }
            return future
        }
        updateFuture.onSuccess {characteristic in
            updateOnSuccessExpectation.fulfill()
        }
        updateFuture.onFailure {error in
            XCTAssert(false, "update onFailure called")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testReceiveNotificationUpdateFailure() {
        let mock = CharacteristicMock()
        let startNotifyingOnSuccessExpectation = expectationWithDescription("onSuccess fulfilled for future start notifying")
        let updateOnFailureExpectation = expectationWithDescription("onSuccess fulfilled for future on update")
        
        let startNotifyingFuture = mock.impl.startNotifying(mock)
        mock.impl.didUpdateNotificationState(mock, error:nil)
        
        startNotifyingFuture.onSuccess{_ in
            startNotifyingOnSuccessExpectation.fulfill()
        }
        startNotifyingFuture.onFailure{_ in
            XCTAssert(false, "start notifying onFailure called")
        }
        let updateFuture = startNotifyingFuture.flatmap{_ -> FutureStream<CharacteristicMock> in
            let future = mock.impl.recieveNotificationUpdates()
            CentralQueue.async {
                mock.impl.didUpdate(mock, error:TestFailure.error)
            }
            return future
        }
        updateFuture.onSuccess {characteristic in
            XCTAssert(false, "update onSuccess called")
        }
        updateFuture.onFailure {error in
            updateOnFailureExpectation.fulfill()
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testStopNotifyingSuccess() {
        let mock = CharacteristicMock()
        let onSuccessExpectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = mock.impl.stopNotifying(mock)
        future.onSuccess {_ in
            onSuccessExpectation.fulfill()
        }
        future.onFailure {error in
            XCTAssert(false, "onFailure called")
        }
        CentralQueue.async {
            mock.impl.didUpdateNotificationState(mock, error:nil)
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testStopNotifyingFailure() {
        let mock = CharacteristicMock()
        let onFailureExpectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = mock.impl.stopNotifying(mock)
        future.onSuccess {_ in
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure {error in
            onFailureExpectation.fulfill()
        }
        CentralQueue.async {
            mock.impl.didUpdateNotificationState(mock, error:TestFailure.error)
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testStopNotificationUpdates() {
        let mock = CharacteristicMock()
        let startNotifyingOnSuccessExpectation = expectationWithDescription("onSuccess fulfilled for future start notifying")
        let updateOnSuccessExpectation = expectationWithDescription("onSuccess fulfilled for future on update")

        var updates = 0
        let startNotifyingFuture = mock.impl.startNotifying(mock)
        mock.impl.didUpdateNotificationState(mock, error:nil)
        
        startNotifyingFuture.onSuccess{_ in
            startNotifyingOnSuccessExpectation.fulfill()
        }
        startNotifyingFuture.onFailure{_ in
            XCTAssert(false, "start notifying onFailure called")
        }
        let updateFuture = startNotifyingFuture.flatmap{_ -> FutureStream<CharacteristicMock> in
            let future = mock.impl.recieveNotificationUpdates()
            CentralQueue.sync {
                mock.impl.didUpdate(mock, error:nil)
            }
            mock.impl.stopNotificationUpdates()
            CentralQueue.sync {
                mock.impl.didUpdate(mock, error:nil)
            }
            return future
        }
        updateFuture.onSuccess {characteristic in
            if updates == 0 {
                updateOnSuccessExpectation.fulfill()
                ++updates
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
