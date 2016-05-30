//
//  FutureWithFilterTests.swift
//  SimpleFutures
//
//  Created by Troy Stribling on 12/23/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import UIKit
import XCTest
@testable import BlueCapKit

class FutureWithFilterTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testSuccessfulFilter() {
        let promise = Promise<Bool>()
        let future = promise.future
        let onSuccessExpectation = expectationWithDescription("onSuccess fullfilled")
        let onSuccesFilterExpectation = expectationWithDescription("onSuccess fullfilled for filtered future")
        let filterExpectation = expectationWithDescription("fullfilled for filter")
        future.onSuccess {value in
            XCTAssert(value, "future onSucces value invalid")
            onSuccessExpectation.fulfill()
        }
        future.onFailure {error in
            XCTAssert(false, "future onFailure called")
        }
        let filter = future.withFilter {value in
            filterExpectation.fulfill()
            return value
        }
        filter.onSuccess {value in
            XCTAssert(value, "filter future onSuccess value invalid")
            onSuccesFilterExpectation.fulfill()
        }
        filter.onFailure {error in
            XCTAssert(false, "filter future onFailure called")
        }
        promise.success(true)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testFailedFilter() {
        let promise = Promise<Bool>()
        let future = promise.future
        let onSuccessExpectation = expectationWithDescription("onSuccess fullfilled")
        let onFailureFilterExpectation = expectationWithDescription("onFailure fullfilled for filtered future")
        let filterExpectation = expectationWithDescription("fullfilled for filter")
        future.onSuccess {value in
            XCTAssertFalse(value, "future onSucces value invalid")
            onSuccessExpectation.fulfill()
        }
        future.onFailure {error in
            XCTAssert(false, "future onFailure called")
        }
        let filter = future.withFilter {value in
            filterExpectation.fulfill()
            return value
        }
        filter.onSuccess {value in
            XCTAssert(false, "filter future onSuccess called")
        }
        filter.onFailure {error in
            XCTAssertEqual(error.domain, "Wrappers", "filter future onFailure invalid error domain")
            XCTAssertEqual(error.code, 1, "filter future onFailure invalid error code")
            onFailureFilterExpectation.fulfill()
        }
        promise.success(false)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testFailedFuture() {
        let promise = Promise<Bool>()
        let future = promise.future
        let onFailureExpectation = expectationWithDescription("onFailure fullfilled")
        let onFailureFilterExpectation = expectationWithDescription("onFailure fullfilled for filtered future")
        future.onSuccess {value in
            XCTAssert(false, "future onSuccess called")
        }
        future.onFailure {error in
            onFailureExpectation.fulfill()
        }
        let filter = future.withFilter {value in
            XCTAssert(false, "filter called")
            return value
        }
        filter.onSuccess {value in
            XCTAssert(false, "filter future onSuccess called")
        }
        filter.onFailure {error in
            XCTAssertEqual(error.domain, "SimpleFutures Tests", "filter future onFailure invalid error domain")
            XCTAssertEqual(error.code, 100, "filter future onFailure invalid error code")
            onFailureFilterExpectation.fulfill()
        }
        promise.failure(TestFailure.error)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
}
