//
//  StreamFailureTests.swift
//  SimpleFutures
//
//  Created by Troy Stribling on 12/20/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import UIKit
import XCTest
@testable import BlueCapKit

class StreamFailureTests : XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testImmediate() {
        let promise = StreamPromise<Bool>()
        let stream = promise.future
        let onFailureExpectation = XCTExpectFullfilledCountTimes(2, message:"onFailure future")
        writeFailedFutures(promise, times:2)
        stream.onSuccess {value in
            XCTAssert(false, "onSuccess called")
        }
        stream.onFailure {error in
            onFailureExpectation()
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testDelayed() {
        let promise = StreamPromise<Bool>()
        let stream = promise.future
        let onFailureExpectation = XCTExpectFullfilledCountTimes(2, message:"onFailure future")
        stream.onSuccess {value in
            XCTAssert(false, "onSuccess called")
        }
        stream.onFailure {error in
            onFailureExpectation()
        }
        writeFailedFutures(promise, times:2)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testDelayedAndImmediate() {
        let promise = StreamPromise<Bool>()
        let stream = promise.future
        let onFailureExpectation = XCTExpectFullfilledCountTimes(2, message:"onFailure future")
        writeFailedFutures(promise, times:1)
        stream.onSuccess {value in
            XCTAssert(false, "onSuccess called")
        }
        writeFailedFutures(promise, times:1)
        stream.onFailure {error in
            onFailureExpectation()
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
}