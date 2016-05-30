//
//  FutureSuccessTests.swift
//  SimpleFuturesTests
//
//  Created by Troy Stribling on 12/14/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import UIKit
import XCTest
@testable import BlueCapKit

class FutureSuccessTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testImediate() {
        let promise = Promise<Bool>()
        let future = promise.future
        let onSuccessExpectation = expectationWithDescription("Imediate future onSuccess fulfilled")
        promise.success(true)
        future.onSuccess {value in
            XCTAssertTrue(value, "onSuccess Invalid value")
            onSuccessExpectation.fulfill()
        }
        future.onFailure {error in
            XCTAssert(false, "onFailure called")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testDelayed() {
        let promise = Promise<Bool>()
        let future = promise.future
        let onSuccessExpectation = expectationWithDescription("Delayed future onSuccess fulfilled")
        future.onSuccess {value in
            XCTAssertTrue(value, "Invalid value")
            onSuccessExpectation.fulfill()
        }
        future.onFailure {error in
            XCTAssert(false, "onFailure called")
        }
        promise.success(true)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testImmediateAndDelayed() {
        let promise = Promise<Bool>()
        let future = promise.future
        let onSuccesImmediateExpectation = expectationWithDescription("Immediate future onSuccess fulfilled")
        let onSuccessDelayedExpectation = expectationWithDescription("Delayed future onSuccess fulfilled")
        future.onSuccess {value in
            XCTAssertTrue(value, "Delayed Invalid value")
            onSuccessDelayedExpectation.fulfill()
        }
        future.onFailure {error in
            XCTAssert(false, "Delayed onFailure called")
        }
        promise.success(true)
        future.onSuccess {value in
            XCTAssertTrue(value, "Immediate Invalid value")
            onSuccesImmediateExpectation.fulfill()
        }
        future.onFailure {error in
            XCTAssert(false, "Immediate onFailure called")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

}

    