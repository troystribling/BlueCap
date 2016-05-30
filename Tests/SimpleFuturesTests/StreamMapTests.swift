//
//  StreamMapTests.swift
//  SimpleFutures
//
//  Created by Troy Stribling on 12/20/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import UIKit
import XCTest
@testable import BlueCapKit

class StreamMapTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testSuccessfulMapping() {
        let promise = StreamPromise<Bool>()
        let stream = promise.future
        let onSuccessExpectation = XCTExpectFullfilledCountTimes(2, message:"onSuccess future")
        let mapExpectation = XCTExpectFullfilledCountTimes(2, message:"map")
        let onSuccessMappedExpectation = XCTExpectFullfilledCountTimes(2, message:"onSuccess mapped future")
        stream.onSuccess {value in
            XCTAssertTrue(value, "Invalid value")
            onSuccessExpectation()
        }
        stream.onFailure {error in
            XCTAssert(false, "future onFailure called")
        }
        let mapped = stream.map {value -> Try<Int> in
            mapExpectation()
            return Try(Int(1))
        }
        mapped.onSuccess {value in
            XCTAssertEqual(value, 1, "mapped onSuccess value invalid")
            onSuccessMappedExpectation()
        }
        mapped.onFailure {error in
            XCTAssert(false, "mapped onFailure called")
        }
        writeSuccesfulFutures(promise, value:true, times:2)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testFailedMapping() {
        let promise = StreamPromise<Bool>()
        let stream = promise.future
        let onSuccessExpectation = XCTExpectFullfilledCountTimes(2, message:"onSuccess future")
        let mapExpectation = XCTExpectFullfilledCountTimes(2, message:"map")
        let onFailureMappedExpectation = XCTExpectFullfilledCountTimes(2, message:"onFailure mapped future")
        stream.onSuccess {value in
            XCTAssertTrue(value, "Invalid value")
            onSuccessExpectation()
        }
        stream.onFailure {error in
            XCTAssert(false, "future onFailure called")
        }
        let mapped = stream.map {value -> Try<Int> in
            mapExpectation()
            return Try<Int>(TestFailure.error)
        }
        mapped.onSuccess {value in
            XCTAssert(false, "mapped onSuccess called")
        }
        mapped.onFailure {error in
            onFailureMappedExpectation()
        }
        writeSuccesfulFutures(promise, value:true, times:2)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testMappingToFailedFuture() {
        let promise = StreamPromise<Bool>()
        let stream = promise.future
        let onFailureExpectation = XCTExpectFullfilledCountTimes(2, message:"onFailure future")
        let onFailureMappedExpectation = XCTExpectFullfilledCountTimes(2, message:"onFailure mapped future")
        stream.onSuccess {value in
            XCTAssert(false, "future onSuccess called")
        }
        stream.onFailure {error in
            onFailureExpectation()
        }
        let mapped = stream.map {value -> Try<Int> in
            XCTAssert(false, "map called")
            return Try<Int>(TestFailure.error)
        }
        mapped.onSuccess {value in
            XCTAssert(false, "mapped onSuccess called")
        }
        mapped.onFailure {error in
            onFailureMappedExpectation()
        }
        writeFailedFutures(promise, times:2)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

}
