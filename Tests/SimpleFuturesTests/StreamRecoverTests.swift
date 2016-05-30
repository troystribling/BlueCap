//
//  StreamRecoverTests.swift
//  SimpleFutures
//
//  Created by Troy Stribling on 12/27/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import UIKit
import XCTest
@testable import BlueCapKit

class StreamRecoverTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testSuccessful() {
        let promise = StreamPromise<Int>()
        let future = promise.future
        let onSuccessExpectation = XCTExpectFullfilledCountTimes(2, message:"onSuccess future")
        let onSucessRecoveredExpectation = XCTExpectFullfilledCountTimes(2, message:"onSuccess recover future")
        future.onSuccess {value in
            XCTAssert(value == 1 || value == 2, "onSuccess value invalid")
            onSuccessExpectation()
        }
        future.onFailure {error in
            XCTAssert(false, "future onFailure called")
        }
        let recovered = future.recover {error -> Try<Int> in
            XCTAssert(false, "recover called")
            return Try(1)
        }
        recovered.onSuccess {value in
            XCTAssert(value == 1 || value == 2, "onSuccess recover value invalid")
            onSucessRecoveredExpectation()
        }
        recovered.onFailure {error in
            XCTAssert(false, "recovered onFailure called")
        }
        writeSuccesfulFutures(promise, values:[1,2])
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testSuccessfulRecovery() {
        let promise = StreamPromise<Int>()
        let future = promise.future
        let onFailureExpectation = XCTExpectFullfilledCountTimes(2, message:"onFailure future")
        let recoverExpectation = XCTExpectFullfilledCountTimes(2, message:"revover")
        let onSucessRecoveredExpectation = XCTExpectFullfilledCountTimes(2, message:"onSuccess recover future")
        future.onSuccess {value in
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure {error in
            onFailureExpectation()
        }
        let recovered = future.recover {error -> Try<Int> in
            recoverExpectation()
            return Try(1)
        }
        recovered.onSuccess {value in
            XCTAssert(value == 1, "onSuccess recover value invalid")
            onSucessRecoveredExpectation()
        }
        recovered.onFailure {error in
            XCTAssert(false, "recovered onFailure called")
        }
        writeFailedFutures(promise, times:2)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testFailedRecovery() {
        let promise = StreamPromise<Int>()
        let future = promise.future
        let onFailureExpectation = XCTExpectFullfilledCountTimes(2, message:"onFailure future")
        let recoverExpectation = XCTExpectFullfilledCountTimes(2, message:"revover")
        let onFailureRecoveredExpectation = XCTExpectFullfilledCountTimes(2, message:"onFailure recover future")
        future.onSuccess {value in
            XCTAssert(false, "onSuccess called")
        }
        future.onFailure {error in
            onFailureExpectation()
        }
        let recovered = future.recover {error -> Try<Int> in
            recoverExpectation()
            return Try(TestFailure.error)
        }
        recovered.onSuccess {value in
            XCTAssert(false, "recovered onSuccess called")
        }
        recovered.onFailure {error in
            onFailureRecoveredExpectation()
        }
        writeFailedFutures(promise, times:2)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

}
