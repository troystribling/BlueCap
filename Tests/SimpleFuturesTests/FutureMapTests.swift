//
//  FutureMapTests.swift
//  SimpleFutures
//
//  Created by Troy Stribling on 12/20/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import UIKit
import XCTest
@testable import BlueCapKit

class FutureMapTests : XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testSuccessfulMapping() {
        let promise = Promise<Bool>()
        let future = promise.future
        let onSuccessExpectation = expectationWithDescription("OnSuccess fulfilled")
        let onSuccessMappedExpectation = expectationWithDescription("OnSuccess fulfilled for mapped future")
        let mapExpectation = expectationWithDescription("map fulfilled")
        future.onSuccess {value in
            XCTAssert(value, "future onSuccess value invalid")
            onSuccessExpectation.fulfill()
        }
        future.onFailure {error in
            XCTAssert(false, "future onFailure called")
        }
        let mapped = future.map {value -> Try<Int> in
            mapExpectation.fulfill()
            return Try(Int(1))
        }
        mapped.onSuccess {value in
            XCTAssertEqual(value, 1, "mapped onSuccess value invalid")
            onSuccessMappedExpectation.fulfill()
        }
        mapped.onFailure {error in
            XCTAssert(false, "mapped onFailure called")
        }
        promise.success(true)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testFailedMapping() {
        let promise = Promise<Bool>()
        let future = promise.future
        let onFailureMappedExpectation = expectationWithDescription("OnFailure fulfilled for mapped future")
        let onSuccessExpectation = expectationWithDescription("OnSuccess fulfilled")
        let mapExpectation = expectationWithDescription("map fulfilled")
        future.onSuccess {value in
            XCTAssert(value, "future onSuccess value invalid")
            onSuccessExpectation.fulfill()
        }
        future.onFailure {error in
            XCTAssert(false, "future onFailure called")
        }
        let mapped = future.map {value -> Try<Int> in
            mapExpectation.fulfill()
            return Try<Int>(TestFailure.error)
        }
        mapped.onSuccess {value in
            XCTAssert(false, "mapped onSuccess called")
        }
        mapped.onFailure {error in
            onFailureMappedExpectation.fulfill()
        }
        promise.success(true)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testMappingToFailedFuture() {
        let promise = Promise<Bool>()
        let future = promise.future
        let onFailureExpectation = expectationWithDescription("OnFailure fulfilled")
        let onFailureMappedExpectation = expectationWithDescription("OnFailure fulfilled for mapped future")
        future.onSuccess {value in
            XCTAssert(false, "future onSucces called")
        }
        future.onFailure {error in
            onFailureExpectation.fulfill()
        }
        let mapped = future.map {value -> Try<Int> in
            XCTAssert(false, "map called")
            return Try(Int(1))
        }
        mapped.onSuccess {value in
            XCTAssert(false, "mapped onSuccess called")
        }
        mapped.onFailure {error in
            onFailureMappedExpectation.fulfill()
        }
        promise.failure(TestFailure.error)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
}
