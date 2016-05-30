//
//  FutureCompleteWithTests.swift
//  SimpleFutures
//
//  Created by Troy Stribling on 12/25/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import UIKit
import XCTest
@testable import BlueCapKit

class FutureCompleteWithTests: XCTestCase {

    let immediateContext = ImmediateContext()

    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testCompletesWith_WhenEnclosingFututureCompletedBeforeCallbacksDefined_CompletesSuccessfully() {
        let promise = Promise<Bool>()
        let future = promise.future
        let promiseCompleted = Promise<Bool>()
        let futureCompleted = promiseCompleted.future

        var onSuccessCalled = false
        var completedOnSuccessCalled = false

        promiseCompleted.success(true)
        future.onSuccess(self.immediateContext) { value in
            onSuccessCalled = true
            XCTAssert(value, "future onSuccess value invalid")
        }
        future.onFailure(self.immediateContext) { error in
            XCTFail("onFailure called")
        }
        futureCompleted.onSuccess(self.immediateContext) { value in
            completedOnSuccessCalled = true
            XCTAssert(value, "futureCompleted onSuccess value invalid")
        }
        futureCompleted.onFailure(self.immediateContext) { error in
            XCTFail("onFailure called")
        }
        promise.completeWith(self.immediateContext, future: futureCompleted)

        XCTAssert(onSuccessCalled, "onSuccess not called")
        XCTAssert(completedOnSuccessCalled, "onSuccess not called")
    }
    
    func testCompletesWith_WhenEnclosingFutureCompletedAfterCallbacksDefined_CompletesSuccessfully() {
        let promise = Promise<Bool>()
        let future = promise.future
        let promiseCompleted = Promise<Bool>()
        let futureCompleted = promiseCompleted.future

        var onSuccessCalled = false
        var completedOnSuccessCalled = false

        future.onSuccess(self.immediateContext) { value in
            onSuccessCalled = true
            XCTAssert(value, "future onSuccess value invalid")
        }
        future.onFailure(self.immediateContext) { error in
            XCTFail("onFailure called")
        }
        futureCompleted.onSuccess(self.immediateContext) { value in
            completedOnSuccessCalled = true
            XCTAssert(value, "futureCompleted onSuccess value invalid")
        }
        futureCompleted.onFailure(self.immediateContext) { error in
            XCTFail("onFailure called")
        }
        promise.completeWith(self.immediateContext, future: futureCompleted)
        promiseCompleted.success(true)

        XCTAssert(onSuccessCalled, "onSuccess not called")
        XCTAssert(completedOnSuccessCalled, "onSuccess not called")
    }

    func testCompletesWith_WhenCompletedBeforeEnclosingFuture_CompletesSuccessfully() {
        let promise = Promise<Bool>()
        let future = promise.future
        let promiseCompleted = Promise<Bool>()
        let futureCompleted = promiseCompleted.future

        var onSuccessCalled = false
        var completedOnSuccessCalled = false

        future.onSuccess(self.immediateContext) { value in
            onSuccessCalled = true
            XCTAssert(value, "future onSuccess invalid value")
        }
        future.onFailure(self.immediateContext) { error in
            XCTFail("onFailure called")
        }
        futureCompleted.onSuccess(self.immediateContext) { value in
            completedOnSuccessCalled = true
            XCTAssert(!value, "futureCompleted onSuccess value invalid")
        }
        futureCompleted.onFailure(self.immediateContext) { error in
            XCTFail("onFailure called")
        }
        promise.success(true)
        promise.completeWith(self.immediateContext, future: futureCompleted)
        promiseCompleted.success(false)

        XCTAssert(onSuccessCalled, "onSuccess not called")
        XCTAssert(completedOnSuccessCalled, "onSuccess not called")
    }

    func testCompletesWith_WhenEnclosingFutureFails_CompletesWithEnclosingFutureError() {
        let promise = Promise<Bool>()
        let future = promise.future
        let promiseCompleted = Promise<Bool>()
        let futureCompleted = promiseCompleted.future

        var onFailureCalled = false
        var completedOnFailureCalled = false


        future.onSuccess(self.immediateContext) { value in
            XCTAssert(false, "future onSuccess called")
        }
        future.onFailure(self.immediateContext) { error in
            onFailureCalled = true
            XCTAssertEqual(error.code, TestFailure.error.code, "Invalid error code")
        }
        futureCompleted.onSuccess(self.immediateContext) {  value in
            XCTAssert(false, "futureCompleted onSuccess called")
        }
        futureCompleted.onFailure(self.immediateContext) { error in
            completedOnFailureCalled = true
            XCTAssertEqual(error.code, TestFailure.error.code, "Invalid error code")
        }
        promise.completeWith(self.immediateContext, future: futureCompleted)
        promiseCompleted.failure(TestFailure.error)

        XCTAssert(onFailureCalled, "onFailure not called")
        XCTAssert(completedOnFailureCalled, "onFailure not called")

    }
    
}

