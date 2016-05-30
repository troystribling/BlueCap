//
//  StreamFlatmapTests.swift
//  SimpleFutures
//
//  Created by Troy Stribling on 12/20/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import UIKit
import XCTest
@testable import BlueCapKit

class StreamFlatmapTests: XCTestCase {

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
        let flatmapExpectation = XCTExpectFullfilledCountTimes(2, message:"flatmap")
        let onSuccessMappedExpectation = XCTExpectFullfilledCountTimes(2, message:"onSuccess mapped future")
        stream.onSuccess {value in
            XCTAssertTrue(value, "Invalid value")
            onSuccessExpectation()
        }
        stream.onFailure {error in
            XCTAssert(false, "future onFailure called")
        }
        let mapped = stream.flatmap {value -> Future<Int> in
            flatmapExpectation()
            let promise = Promise<Int>()
            promise.success(1)
            return promise.future
        }
        mapped.onSuccess {value in
            XCTAssertEqual(value, 1, "mapped onSuccess value invalid")
            onSuccessMappedExpectation()
        }
        mapped.onFailure {error in
            XCTAssert(false, "mapped future onFailure called")
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
        let flatmapExpectation = XCTExpectFullfilledCountTimes(2, message:"flatmap")
        let onFailureMappedExpectation = XCTExpectFullfilledCountTimes(2, message:"onFailure mapped future")
        stream.onSuccess {value in
            XCTAssertTrue(value, "Invalid value")
            onSuccessExpectation()
        }
        stream.onFailure {error in
            XCTAssert(false, "future onFailure called")
        }
        let mapped = stream.flatmap {value -> Future<Int> in
            flatmapExpectation()
            let promise = Promise<Int>()
            promise.failure(TestFailure.error)
            return promise.future
        }
        mapped.onSuccess {value in
            XCTAssert(false, "mapped future onSuccess called")
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
        let mapped = stream.flatmap {value -> Future<Int> in
            XCTAssert(false, "flatmap called")
            let promise = Promise<Int>()
            promise.failure(TestFailure.error)
            return promise.future
        }
        mapped.onSuccess {value in
            XCTAssert(false, "mapped future onSuccess called")
        }
        mapped.onFailure {error in
            onFailureMappedExpectation()
        }
        writeFailedFutures(promise, times:2)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testSuccessfulMappingToFutureStream() {
        let promise = StreamPromise<Bool>()
        let stream = promise.future
        let onSuccessExpectation = XCTExpectFullfilledCountTimes(2, message:"onSuccess future")
        let flatmapExpectation = XCTExpectFullfilledCountTimes(2, message:"flatmap")
        let onSuccessMappedExpectation = XCTExpectFullfilledCountTimes(4, message:"onSuccess mapped future")
        stream.onSuccess {value in
            onSuccessExpectation()
        }
        stream.onFailure {error in
            XCTAssert(false, "future onFailure called")
        }
        let mapped = stream.flatmap {value -> FutureStream<Int> in
            flatmapExpectation()
            let promise = StreamPromise<Int>()
            if value {
                writeSuccesfulFutures(promise, values:[1, 2])
            } else {
                writeSuccesfulFutures(promise, values:[3, 4])
            }
            return promise.future
        }
        mapped.onSuccess {value in
            XCTAssert(value == 1 || value == 2 || value == 3 || value == 4, "mapped onSuccess value invalid")
            onSuccessMappedExpectation()
        }
        mapped.onFailure {error in
            XCTAssert(false, "mapped future onFailure called")
        }
        writeSuccesfulFutures(promise, values:[true, false])
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testFailedMappingToFutureStream() {
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
        let mapped = stream.flatmap {value -> FutureStream<Int> in
            XCTAssert(false, "flatmap called")
            return  StreamPromise<Int>().future
        }
        mapped.onSuccess {value in
            XCTAssert(false, "mapped future onSuccess called")
        }
        mapped.onFailure {error in
            onFailureMappedExpectation()
        }
        writeFailedFutures(promise, times:2)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testSuccessfulMappingToFailedFutureStream() {
        let promise = StreamPromise<Bool>()
        let stream = promise.future
        let onSuccessExpectation = XCTExpectFullfilledCountTimes(2, message:"onSuccess future")
        let flatmapExpectation = XCTExpectFullfilledCountTimes(2, message:"flatmap")
        let onFailureMappedExpectation = XCTExpectFullfilledCountTimes(4, message:"onFailure mapped future")
        stream.onSuccess {value in
            onSuccessExpectation()
        }
        stream.onFailure {error in
            XCTAssert(false, "future onFailure called")
        }
        let mapped = stream.flatmap {value -> FutureStream<Int> in
            flatmapExpectation()
            let promise = StreamPromise<Int>()
            writeFailedFutures(promise, times:2)
            return promise.future
        }
        mapped.onSuccess {value in
            XCTAssert(false, "mapped future onSucces called")
        }
        mapped.onFailure {error in
            onFailureMappedExpectation()
        }
        writeSuccesfulFutures(promise, values:[true, false])
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

}
