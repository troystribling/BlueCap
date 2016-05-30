//
//  FutureRecoverWithTests.swift
//  SimpleFutures
//
//  Created by Troy Stribling on 12/20/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import UIKit
import XCTest
@testable import BlueCapKit

class FutureRecoverWithTests : XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testSuccessfulToFuture() {
        let promise = Promise<Bool>()
        let future = promise.future
        let onSuccessExpectation = expectationWithDescription("OnSuccess fulfilled")
        let onSuccessRecoveryExpectation = expectationWithDescription("OnSuccess fulfilled for recovered future")
        future.onSuccess {value in
            XCTAssert(value, "future onSuccess value invalid")
            onSuccessExpectation.fulfill()
        }
        future.onFailure {error in
            XCTAssert(false, "future onFailure called")
        }
        let recovered = future.recoverWith {error -> Future<Bool> in
            XCTAssert(false, "recover called")
            return Future<Bool>()
        }
        recovered.onSuccess {value in
            XCTAssert(value, "recovered onSuccess value invalid")
            onSuccessRecoveryExpectation.fulfill()
        }
        recovered.onFailure {error in
            XCTAssert(false, "recovered onFailure called")
        }
        promise.success(true)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testSuccessfulRecoveryToFuture() {
        let promise = Promise<Bool>()
        let future = promise.future
        let onFailureExpectation = expectationWithDescription("OnFailure fulfilled")
        let onSuccessRecoveryExpectation = expectationWithDescription("OnSuccess fulfilled for recovered future")
        let recoverExpectation = expectationWithDescription("recover fulfilled")
        future.onSuccess {value in
            XCTAssert(false, "future onSuccess called")
        }
        future.onFailure {error in
            onFailureExpectation.fulfill()
        }
        let recovered = future.recoverWith {error -> Future<Bool> in
            recoverExpectation.fulfill()
            let promise = Promise<Bool>()
            promise.success(false)
            return promise.future
        }
        recovered.onSuccess {value in
            XCTAssertFalse(value, "recovered onSuccess invalid value")
            onSuccessRecoveryExpectation.fulfill()
        }
        recovered.onFailure {error in
            XCTAssert(false, "recovered onFailure called")
        }
        promise.failure(TestFailure.error)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testFailedRecoveryToFuture() {
        let promise = Promise<Bool>()
        let future = promise.future
        let onFailureExpectation = expectationWithDescription("OnFailure fulfilled")
        let onFailureRecoveryExpectation = expectationWithDescription("OnFailure fulfilled for recovered future")
        let recoverExpectation = expectationWithDescription("recover fulfilled")
        future.onSuccess {value in
            XCTAssert(false, "future onSuccess called")
        }
        future.onFailure {error in
            onFailureExpectation.fulfill()
        }
        let recovered = future.recoverWith {error -> Future<Bool> in
            recoverExpectation.fulfill()
            let promise = Promise<Bool>()
            promise.failure(TestFailure.error)
            return promise.future
        }
        recovered.onSuccess {value in
            XCTAssert(false, "recovered onSuccess callsd")
        }
        recovered.onFailure {error in
            onFailureRecoveryExpectation.fulfill()
        }
        promise.failure(TestFailure.error)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
 
    func testSuccessfulToFutureStream() {
        let promise = Promise<Bool>()
        let future = promise.future
        let onSuccessExpectation = expectationWithDescription("OnSuccess fulfilled")
        let onSuccessRecoveryExpectation = expectationWithDescription("OnSuccess fulfilled for recovered future")
        future.onSuccess {value in
            XCTAssert(value, "future onSuccess value invalid")
            onSuccessExpectation.fulfill()
        }
        future.onFailure {error in
            XCTAssert(false, "future onFailure called")
        }
        let recovered = future.recoverWith {error -> FutureStream<Bool> in
            XCTAssert(false, "recover called")
            return FutureStream<Bool>()
        }
        recovered.onSuccess {value in
            XCTAssert(value, "recovered onSuccess value invalid")
            onSuccessRecoveryExpectation.fulfill()
        }
        recovered.onFailure {error in
            XCTAssert(false, "recovered onFailure called")
        }
        promise.success(true)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testSuccessfulRecoveryToFutureStream() {
        let promise = Promise<Bool>()
        let future = promise.future
        let onFailureExpectation = expectationWithDescription("OnFailure fulfilled")
        let onSuccessRecoveryExpectation = expectationWithDescription("OnSuccess fulfilled for recovered future")
        let recoverExpectation = expectationWithDescription("recover fulfilled")
        future.onSuccess {value in
            XCTAssert(false, "future onSuccess called")
        }
        future.onFailure {error in
            onFailureExpectation.fulfill()
        }
        let recovered = future.recoverWith {error -> FutureStream<Bool> in
            recoverExpectation.fulfill()
            let promise = StreamPromise<Bool>()
            promise.success(false)
            return promise.future
        }
        recovered.onSuccess {value in
            XCTAssertFalse(value, "recovered onSuccess invalid value")
            onSuccessRecoveryExpectation.fulfill()
        }
        recovered.onFailure {error in
            XCTAssert(false, "recovered onFailure called")
        }
        promise.failure(TestFailure.error)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testFailedRecoveryToFutureStream() {
        let promise = Promise<Bool>()
        let future = promise.future
        let onFailureExpectation = expectationWithDescription("OnFailure fulfilled")
        let onFailureRecoveryExpectation = expectationWithDescription("OnFailure fulfilled for recovered future")
        let recoverExpectation = expectationWithDescription("recover fulfilled")
        future.onSuccess {value in
            XCTAssert(false, "future onSuccess called")
        }
        future.onFailure {error in
            onFailureExpectation.fulfill()
        }
        let recovered = future.recoverWith {error -> FutureStream<Bool> in
            recoverExpectation.fulfill()
            let promise = StreamPromise<Bool>()
            promise.failure(TestFailure.error)
            return promise.future
        }
        recovered.onSuccess {value in
            XCTAssert(false, "recovered onSuccess callsd")
        }
        recovered.onFailure {error in
            onFailureRecoveryExpectation.fulfill()
        }
        promise.failure(TestFailure.error)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }


}
