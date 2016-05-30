//
//  StreamSuccessTests.swift
//  SimpleFutures
//
//  Created by Troy Stribling on 12/20/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import UIKit
import XCTest
@testable import BlueCapKit

class StreamSuccessTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testImmediate() {
        let promise = StreamPromise<Bool>()
        let stream = promise.future
        let onSuccessExpectation = XCTExpectFullfilledCountTimes(2, message:"onSuccess future")
        writeSuccesfulFutures(promise, value:true, times:2)
        stream.onSuccess {value in
            XCTAssertTrue(value, "Invalid value")
            onSuccessExpectation()
        }
        stream.onFailure {error in
            XCTAssert(false, "onFailure called")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testDelayed() {
        let promise = StreamPromise<Bool>()
        let stream = promise.future
        let onSuccessExpectation = XCTExpectFullfilledCountTimes(2, message:"onSuccess future")
        stream.onSuccess {value in
            XCTAssertTrue(value, "Invalid value")
            onSuccessExpectation()
        }
        stream.onFailure {error in
            XCTAssert(false, "onFailure called")
        }
        writeSuccesfulFutures(promise, value:true, times:2)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testDelayedAndImmediate() {
        let promise = StreamPromise<Bool>()
        let stream = promise.future
        let onSuccessExpectation = XCTExpectFullfilledCountTimes(2, message:"onSuccess future")
        writeSuccesfulFutures(promise, value:true, times:1)
        stream.onSuccess {value in
            XCTAssertTrue(value, "Invalid value")
            onSuccessExpectation()
        }
        writeSuccesfulFutures(promise, value:true, times:1)
        stream.onFailure {error in
            XCTAssert(false, "onFailure called")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testMultipleCallbacks() {
        let promise = StreamPromise<Bool>()
        let stream = promise.future
        writeSuccesfulFutures(promise, value:true, times:1)
        let onSuccessImmediateExpectation = XCTExpectFullfilledCountTimes(2, message:"onSuccess immediate future")
        let onSuccessDelayedExpectation = XCTExpectFullfilledCountTimes(2, message:"onSuccess delayed future")
        stream.onSuccess {value in
            XCTAssertTrue(value, "Invalid value")
            onSuccessImmediateExpectation()
        }
        writeSuccesfulFutures(promise, value:true, times:1)
        stream.onSuccess {value in
            XCTAssertTrue(value, "Invalid value")
            onSuccessDelayedExpectation()
        }
        stream.onFailure {error in
            XCTAssert(false, "onFailure called")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testSuccessAndFailure() {
        var countFailure = 0
        let promise = StreamPromise<Bool>()
        let stream = promise.future
        let onFailureExpectation = XCTExpectFullfilledCountTimes(1, message:"onFailure future")
        let onSuccessExpectation = XCTExpectFullfilledCountTimes(1, message:"onSuccess future")
        stream.onSuccess {value in
            XCTAssertTrue(value, "Invalid value")
            onSuccessExpectation()
        }
        stream.onFailure {error in
            countFailure += 1
            onFailureExpectation()
        }
        writeSuccesfulFutures(promise, value:true, times:1)
        writeFailedFutures(promise, times:1)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

}

