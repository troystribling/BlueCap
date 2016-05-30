//
//  FutureForcompYieldTests.swift
//  SimpleFutures
//
//  Created by Troy Stribling on 12/29/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import UIKit
import XCTest
@testable import BlueCapKit

class FutureForcompYieldTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testTwoFuturesSuccess() {
        let promise1 = Promise<Bool>()
        let future1 = promise1.future
        let promise2 = Promise<Int>()
        let future2 = promise2.future
        let onSuccessFuture1Expectation = expectationWithDescription("future1 onSuccess fulfilled")
        let onSuccessFuture2Expectation = expectationWithDescription("future2 onSuccess fulfilled")
        let forcompExpectation = expectationWithDescription("forcomp fulfilled")
        let onSuccessForcompExpectation = expectationWithDescription("forcomp onSuccess fullfilled")
        future1.onSuccess {value in
            XCTAssert(value, "future1 onSuccess value invalid")
            onSuccessFuture1Expectation.fulfill()
        }
        future1.onFailure {error in
            XCTAssert(false, "future1 onFailure called")
        }
        future2.onSuccess {value in
            XCTAssert(value == 1, "future2 onSuccess value invalid")
            onSuccessFuture2Expectation.fulfill()
        }
        future2.onFailure {error in
            XCTAssert(false, "future2 onFailure called")
        }
        let forcompFuture = forcomp(future1, g:future2) {(value1, value2) -> Try<Bool> in
            XCTAssert(value1, "forcomp yield value1 invalid")
            XCTAssert(value2 == 1, "forcomp yield value2 invalid")
            forcompExpectation.fulfill()
            return Try(true)
        }
        forcompFuture.onSuccess {value in
            XCTAssert(value, "forcompFuture onSuccess value invalid")
            onSuccessForcompExpectation.fulfill()
        }
        forcompFuture.onFailure {error in
            XCTAssert(false, "forcompFuture onFailure called")
        }
        promise1.success(true)
        promise2.success(1)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testTwoFuturesFailure() {
        let promise1 = Promise<Bool>()
        let future1 = promise1.future
        let promise2 = Promise<Int>()
        let future2 = promise2.future
        let onFailureFuture1Expectation = expectationWithDescription("future1 onFailure fulfilled")
        let onSuccessFuture2Expectation = expectationWithDescription("future2 onSuccess fulfilled")
        let onFailureForcompExpectation = expectationWithDescription("forcomp onFailure fullfilled")
        future1.onSuccess {value in
            XCTAssert(false, "future1 onSuccess called")
        }
        future1.onFailure {error in
            onFailureFuture1Expectation.fulfill()
        }
        future2.onSuccess {value in
            XCTAssert(value == 1, "future2 onSuccess value invalid")
            onSuccessFuture2Expectation.fulfill()
        }
        future2.onFailure {error in
            XCTAssert(false, "future2 onFailure called")
        }
        let forcompFuture = forcomp(future1, g:future2) {(value1, value2) -> Try<Bool> in
            XCTAssert(false, "forcomp called")
            return Try(true)
        }
        forcompFuture.onSuccess {value in
            XCTAssert(false, "forcomp onSuccess called")
        }
        forcompFuture.onFailure {error in
            onFailureForcompExpectation.fulfill()
        }
        promise1.failure(TestFailure.error)
        promise2.success(1)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testTwoFuturesYieldFailure() {
        let promise1 = Promise<Bool>()
        let future1 = promise1.future
        let promise2 = Promise<Int>()
        let future2 = promise2.future
        let onSuccessFuture1Expectation = expectationWithDescription("future1 onSuccess fulfilled")
        let onSuccessFuture2Expectation = expectationWithDescription("future2 onSuccess fulfilled")
        let forcompExpectation = expectationWithDescription("forcomp fulfilled")
        let onFailureForcompExpectation = expectationWithDescription("forcomp onFailure fullfilled")
        future1.onSuccess {value in
            XCTAssert(value, "future1 onSuccess value invalid")
            onSuccessFuture1Expectation.fulfill()
        }
        future1.onFailure {error in
            XCTAssert(false, "future1 onFailure called")
        }
        future2.onSuccess {value in
            XCTAssert(value == 1, "future2 onSuccess value invalid")
            onSuccessFuture2Expectation.fulfill()
        }
        future2.onFailure {error in
            XCTAssert(false, "future2 onFailure called")
        }
        let forcompFuture = forcomp(future1, g:future2) {(value1, value2) -> Try<Bool> in
            forcompExpectation.fulfill()
            return Try<Bool>(TestFailure.error)
        }
        forcompFuture.onSuccess {value in
            XCTAssert(false, "forcompFuture onSuccess called")
        }
        forcompFuture.onFailure {error in
            onFailureForcompExpectation.fulfill()
        }
        promise1.success(true)
        promise2.success(1)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testThreeFuturesSuccess() {
        let promise1 = Promise<Bool>()
        let future1 = promise1.future
        let promise2 = Promise<Int>()
        let future2 = promise2.future
        let promise3 = Promise<Float>()
        let future3 = promise3.future
        let onSuccessFuture1Expectation = expectationWithDescription("future1 onSuccess fulfilled")
        let onSuccessFuture2Expectation = expectationWithDescription("future2 onSuccess fulfilled")
        let onSuccessFuture3Expectation = expectationWithDescription("future3 onSuccess fulfilled")
        let forcompExpectation = expectationWithDescription("forcomp fulfilled")
        let onSuccessForcompExpectation = expectationWithDescription("forcomp onSuccess fullfilled")
        future1.onSuccess {value in
            XCTAssert(value, "future1 onSuccess value invalid")
            onSuccessFuture1Expectation.fulfill()
        }
        future1.onFailure {error in
            XCTAssert(false, "future1 onFailure called")
        }
        future2.onSuccess {value in
            XCTAssert(value == 1, "future2 onSuccess value invalid")
            onSuccessFuture2Expectation.fulfill()
        }
        future2.onFailure {error in
            XCTAssert(false, "future2 onFailure called")
        }
        future3.onSuccess {value in
            XCTAssert(value == 1.0, "future3 onSuccess value invalid")
            onSuccessFuture3Expectation.fulfill()
        }
        future3.onFailure {error in
            XCTAssert(false, "future3 onFailure called")
        }
        let forcompFuture = forcomp(future1, g:future2, h:future3) {(value1, value2, value3) -> Try<Bool> in
            XCTAssert(value1, "forcomp yield value1 invalid")
            XCTAssert(value2 == 1, "forcomp yield value2 invalid")
            XCTAssert(value3 == 1.0, "forcomp yield value3 invalid")
            forcompExpectation.fulfill()
            return Try(true)
        }
        forcompFuture.onSuccess {value in
            XCTAssert(value, "forcompFuture onSuccess value invalid")
            onSuccessForcompExpectation.fulfill()
        }
        forcompFuture.onFailure {error in
            XCTAssert(false, "forcompFuture onFailure called")
        }
        promise1.success(true)
        promise2.success(1)
        promise3.success(1.0)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testThreeFuturesFailure() {
        let promise1 = Promise<Bool>()
        let future1 = promise1.future
        let promise2 = Promise<Int>()
        let future2 = promise2.future
        let promise3 = Promise<Float>()
        let future3 = promise3.future
        let onFailureFuture1Expectation = expectationWithDescription("future1 onFailure fulfilled")
        let onSuccessFuture2Expectation = expectationWithDescription("future2 onSuccess fulfilled")
        let onSuccessFuture3Expectation = expectationWithDescription("future3 onSuccess fulfilled")
        let onFailureForcompExpectation = expectationWithDescription("forcomp onFailure fullfilled")
        future1.onSuccess {value in
            XCTAssert(false, "future1 onSuccess called")
        }
        future1.onFailure {error in
            onFailureFuture1Expectation.fulfill()
        }
        future2.onSuccess {value in
            XCTAssert(value == 1, "future2 onSuccess value invalid")
            onSuccessFuture2Expectation.fulfill()
        }
        future2.onFailure {error in
            XCTAssert(false, "future2 onFailure called")
        }
        future3.onSuccess {value in
            XCTAssert(value == 1.0, "future3 onSuccess value invalid")
            onSuccessFuture3Expectation.fulfill()
        }
        future3.onFailure {error in
            XCTAssert(false, "future3 onFailure called")
        }
        let forcompFuture = forcomp(future1, g:future2, h:future3) {(value1, value2, value3) -> Try<Bool> in
            XCTAssert(false, "forcomp yield called")
            return Try(true)
        }
        forcompFuture.onSuccess {value in
            XCTAssert(false, "forcomp onSuccess called")
        }
        forcompFuture.onFailure {error in
            onFailureForcompExpectation.fulfill()
        }
        promise1.failure(TestFailure.error)
        promise2.success(1)
        promise3.success(1.0)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testThreeFuturesYieldFailure() {
        let promise1 = Promise<Bool>()
        let future1 = promise1.future
        let promise2 = Promise<Int>()
        let future2 = promise2.future
        let promise3 = Promise<         Float>()
        let future3 = promise3.future
        let onSuccessFuture1Expectation = expectationWithDescription("future1 onSuccess fulfilled")
        let onSuccessFuture2Expectation = expectationWithDescription("future2 onSuccess fulfilled")
        let onSuccessFuture3Expectation = expectationWithDescription("future3 onSuccess fulfilled")
        let forcompExpectation = expectationWithDescription("forcomp fulfilled")
        let onFailureForcompExpectation = expectationWithDescription("forcomp onFailure fullfilled")
        future1.onSuccess {value in
            XCTAssert(value, "future1 onSuccess value invalid")
            onSuccessFuture1Expectation.fulfill()
        }
        future1.onFailure {error in
            XCTAssert(false, "future1 onFailure called")
        }
        future2.onSuccess {value in
            XCTAssert(value == 1, "future2 onSuccess value invalid")
            onSuccessFuture2Expectation.fulfill()
        }
        future2.onFailure {error in
            XCTAssert(false, "future2 onFailure called")
        }
        future3.onSuccess {value in
            XCTAssert(value == 1.0, "future3 onSuccess value invalid")
            onSuccessFuture3Expectation.fulfill()
        }
        future3.onFailure {error in
            XCTAssert(false, "future3 onFailure called")
        }
        let forcompFuture = forcomp(future1, g:future2, h:future3) {(value1, value2, value3) -> Try<Bool> in
            forcompExpectation.fulfill()
            return Try<Bool>(TestFailure.error)
        }
        forcompFuture.onSuccess {value in
            XCTAssert(false, "forcompFuture onSuccess called")
        }
        forcompFuture.onFailure {error in
            onFailureForcompExpectation.fulfill()
        }
        promise1.success(true)
        promise2.success(1)
        promise3.success(1.0)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testTwoFuturesSuccessFiltered() {
        let promise1 = Promise<Bool>()
        let future1 = promise1.future
        let promise2 = Promise<Int>()
        let future2 = promise2.future
        let onSuccessFuture1Expectation = expectationWithDescription("future1 onSuccess fulfilled")
        let onSuccessFuture2Expectation = expectationWithDescription("future2 onSuccess fulfilled")
        let forcompExpectation = expectationWithDescription("forcomp fulfilled")
        let filterExpectaion = expectationWithDescription("filter fulfilled")
        let onSuccessForcompExpectation = expectationWithDescription("forcomp onSuccess fullfilled")
        future1.onSuccess {value in
            XCTAssert(value, "future1 onSuccess value invalid")
            onSuccessFuture1Expectation.fulfill()
        }
        future1.onFailure {error in
            XCTAssert(false, "future1 onFailure called")
        }
        future2.onSuccess {value in
            XCTAssert(value == 1, "future2 onSuccess value invalid")
            onSuccessFuture2Expectation.fulfill()
        }
        future2.onFailure {error in
            XCTAssert(false, "future2 onFailure called")
        }
        let forcompFuture = forcomp(future1, g:future2, filter:{(value1, value2) -> Bool in
                XCTAssert(value1, "forcomp filter value1 invalid")
                XCTAssert(value2 == 1, "forcomp filter value2 invalid")
                filterExpectaion.fulfill()
                return true
            }) {(value1, value2) -> Try<Bool> in
                XCTAssert(value1, "forcomp yield value1 invalid")
                XCTAssert(value2 == 1, "forcomp yield value2 invalid")
                forcompExpectation.fulfill()
                return Try(true)
        }
        forcompFuture.onSuccess {value in
            XCTAssert(value, "forcompFuture onSuccess value invalid")
            onSuccessForcompExpectation.fulfill()
        }
        forcompFuture.onFailure {error in
            XCTAssert(false, "forcompFuture onFailure called")
        }
        promise1.success(true)
        promise2.success(1)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testTwoFuturesFailureFiltered() {
        let promise1 = Promise<Bool>()
        let future1 = promise1.future
        let promise2 = Promise<Int>()
        let future2 = promise2.future
        let onFailureFuture1Expectation = expectationWithDescription("future1 onFailure fulfilled")
        let onSuccessFuture2Expectation = expectationWithDescription("future2 onSuccess fulfilled")
        let onFailureForcompExpectation = expectationWithDescription("forcomp onF fullfailureilled")
        future1.onSuccess {value in
            XCTAssert(false, "future1 onSuccess called")
        }
        future1.onFailure {error in
            onFailureFuture1Expectation.fulfill()
        }
        future2.onSuccess {value in
            XCTAssert(value == 1, "future2 onSuccess value invalid")
            onSuccessFuture2Expectation.fulfill()
        }
        future2.onFailure {error in
            XCTAssert(false, "future2 onFailure called")
        }
        let forcompFuture = forcomp(future1, g:future2, filter:{(value1, value2) -> Bool in
                XCTAssert(false, "forcomp filter called")
                return true
            }) {(value1, value2) -> Try<Bool> in
                XCTAssert(false, "forcomp yield called")
                return Try(true)
        }
        forcompFuture.onSuccess {value in
            XCTAssert(false, "forcompFuture onSuccess called")
        }
        forcompFuture.onFailure {error in
            onFailureForcompExpectation.fulfill()
        }
        promise1.failure(TestFailure.error)
        promise2.success(1)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }

    }
    
    func testTwoFuturesFilterFailure() {
        let promise1 = Promise<Bool>()
        let future1 = promise1.future
        let promise2 = Promise<Int>()
        let future2 = promise2.future
        let onSuccessFuture1Expectation = expectationWithDescription("future1 onSuccess fulfilled")
        let onSuccessFuture2Expectation = expectationWithDescription("future2 onSuccess fulfilled")
        let filterExpectaion = expectationWithDescription("filter fulfilled")
        let onFailureForcompExpectation = expectationWithDescription("forcomp onSuccess fullfilled")
        future1.onSuccess {value in
            XCTAssert(value, "future1 onSuccess value invalid")
            onSuccessFuture1Expectation.fulfill()
        }
        future1.onFailure {error in
            XCTAssert(false, "future1 onFailure called")
        }
        future2.onSuccess {value in
            XCTAssert(value == 1, "future2 onSuccess value invalid")
            onSuccessFuture2Expectation.fulfill()
        }
        future2.onFailure {error in
            XCTAssert(false, "future2 onFailure called")
        }
        let forcompFuture = forcomp(future1, g:future2, filter:{(value1, value2) -> Bool in
                filterExpectaion.fulfill()
                return false
            }) {(value1, value2) -> Try<Bool> in
                XCTAssert(false, "forcomp yield called")
                return Try(true)
        }
        forcompFuture.onSuccess {value in
            XCTAssert(false, "forcompFuture onSuccess called")
        }
        forcompFuture.onFailure {error in
            onFailureForcompExpectation.fulfill()
        }
        promise1.success(true)
        promise2.success(1)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testThreeFuturesSuccessFiltered() {
        let promise1 = Promise<Bool>()
        let future1 = promise1.future
        let promise2 = Promise<Int>()
        let future2 = promise2.future
        let promise3 = Promise<Float>()
        let future3 = promise3.future
        let onSuccessFuture1Expectation = expectationWithDescription("future1 onSuccess fulfilled")
        let onSuccessFuture2Expectation = expectationWithDescription("future2 onSuccess fulfilled")
        let onSuccessFuture3Expectation = expectationWithDescription("future3 onSuccess fulfilled")
        let forcompExpectation = expectationWithDescription("forcomp fulfilled")
        let filterExpectaion = expectationWithDescription("filter fulfilled")
        let onSuccessForcompExpectation = expectationWithDescription("forcomp onSuccess fullfilled")
        future1.onSuccess {value in
            XCTAssert(value, "future1 onSuccess value invalid")
            onSuccessFuture1Expectation.fulfill()
        }
        future1.onFailure {error in
            XCTAssert(false, "future1 onFailure called")
        }
        future2.onSuccess {value in
            XCTAssert(value == 1, "future2 onSuccess value invalid")
            onSuccessFuture2Expectation.fulfill()
        }
        future2.onFailure {error in
            XCTAssert(false, "future2 onFailure called")
        }
        future3.onSuccess {value in
            XCTAssert(value == 1.0, "future3 onSuccess value invalid")
            onSuccessFuture3Expectation.fulfill()
        }
        future3.onFailure {error in
            XCTAssert(false, "future3 onFailure called")
        }
        let forcompFuture = forcomp(future1, g:future2, h:future3, filter:{(value1, value2, value3) -> Bool in
                XCTAssert(value1, "forcomp filter value1 invalid")
                XCTAssert(value2 == 1, "forcomp filter value2 invalid")
                XCTAssert(value3 == 1.0, "forcomp filter value3 invalid")
                filterExpectaion.fulfill()
                return true
            }) {(value1, value2, value3) -> Try<Bool> in
                XCTAssert(value1, "forcomp yield value1 invalid")
                XCTAssert(value2 == 1, "forcomp yiled value2 invalid")
                XCTAssert(value3 == 1.0, "forcomp yield value3 invalid")
                forcompExpectation.fulfill()
                return Try(true)
        }
        forcompFuture.onSuccess {value in
            XCTAssert(value, "forcompFuture onSuccess value invalid")
            onSuccessForcompExpectation.fulfill()
        }
        forcompFuture.onFailure {error in
            XCTAssert(false, "forcompFuture onFailure called")
        }
        promise1.success(true)
        promise2.success(1)
        promise3.success(1.0)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testThreeFuturesFailureFiltered() {
        let promise1 = Promise<Bool>()
        let future1 = promise1.future
        let promise2 = Promise<Int>()
        let future2 = promise2.future
        let promise3 = Promise<Float>()
        let future3 = promise3.future
        let onFailureFuture1Expectation = expectationWithDescription("future1 onFailure fulfilled")
        let onSuccessFuture2Expectation = expectationWithDescription("future2 onSuccess fulfilled")
        let onSuccessFuture3Expectation = expectationWithDescription("future3 onSuccess fulfilled")
        let onFailureForcompExpectation = expectationWithDescription("forcomp onFailure fullfilled")
        future1.onSuccess {value in
            XCTAssert(false, "future1 onSuccess called")
        }
        future1.onFailure {error in
            onFailureFuture1Expectation.fulfill()
        }
        future2.onSuccess {value in
            XCTAssert(value == 1, "future2 onSuccess value invalid")
            onSuccessFuture2Expectation.fulfill()
        }
        future2.onFailure {error in
            XCTAssert(false, "future2 onFailure called")
        }
        future3.onSuccess {value in
            XCTAssert(value == 1.0, "future3 onSuccess value invalid")
            onSuccessFuture3Expectation.fulfill()
        }
        future3.onFailure {error in
            XCTAssert(false, "future3 onFailure called")
        }
        let forcompFuture = forcomp(future1, g:future2, h:future3, filter:{(value1, value2, value3) -> Bool in
                XCTAssert(false, "forcomp filter called")
                return true
            }) {(value1, value2, value3) -> Try<Bool> in
                XCTAssert(false, "forcomp yield called")
                return Try(true)
        }
        forcompFuture.onSuccess {value in
            XCTAssert(false, "forcompFuture onSuccess called")
        }
        forcompFuture.onFailure {error in
            onFailureForcompExpectation.fulfill()
        }
        promise1.failure(TestFailure.error)
        promise2.success(1)
        promise3.success(1.0)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }
    
    func testThreeFuturesFilterFailure() {
        let promise1 = Promise<Bool>()
        let future1 = promise1.future
        let promise2 = Promise<Int>()
        let future2 = promise2.future
        let promise3 = Promise<Float>()
        let future3 = promise3.future
        let onSuccessFuture1Expectation = expectationWithDescription("future1 onSuccess fulfilled")
        let onSuccessFuture2Expectation = expectationWithDescription("future2 onSuccess fulfilled")
        let onSuccessFuture3Expectation = expectationWithDescription("future3 onSuccess fulfilled")
        let filterExpectaion = expectationWithDescription("filter fulfilled")
        let onFailureForcompExpectation = expectationWithDescription("forcomp onSuccess fullfilled")
        future1.onSuccess {value in
            XCTAssert(value, "future1 onSuccess value invalid")
            onSuccessFuture1Expectation.fulfill()
        }
        future1.onFailure {error in
            XCTAssert(false, "future1 onFailure called")
        }
        future2.onSuccess {value in
            XCTAssert(value == 1, "future2 onSuccess value invalid")
            onSuccessFuture2Expectation.fulfill()
        }
        future2.onFailure {error in
            XCTAssert(false, "future2 onFailure called")
        }
        future3.onSuccess {value in
            XCTAssert(value == 1.0, "future3 onSuccess value invalid")
            onSuccessFuture3Expectation.fulfill()
        }
        future3.onFailure {error in
            XCTAssert(false, "future3 onFailure called")
        }
        let forcompFuture = forcomp(future1, g:future2, h:future3, filter:{(value1, value2, value3) -> Bool in
            filterExpectaion.fulfill()
            return false
            }) {(value1, value2, value3) -> Try<Bool> in
                XCTAssert(false, "forcomp yield called")
                return Try(true)
        }
        forcompFuture.onSuccess {value in
            XCTAssert(false, "forcompFuture onSuccess called")
        }
        forcompFuture.onFailure {error in
            onFailureForcompExpectation.fulfill()
        }
        promise1.success(true)
        promise2.success(1)
        promise3.success(1.0)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

}
