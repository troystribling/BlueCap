//
//  FutureAndThenTests.swift
//  SimpleFutures
//
//  Created by Troy Stribling on 12/20/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import UIKit
import XCTest
@testable import BlueCapKit

class FutureAndThenTests : XCTestCase {

    let immediateContext = ImmediateContext()

    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testAndThen_FollwingSuccessfulFuture_CompletesSuccessfully() {
        var successCalled = false
        let promise = Promise<Bool>()
        let future = promise.future
        let andThen = future.andThen(self.immediateContext) { result in
            switch result {
            case .Success(_):
                successCalled = true
            case .Failure(_):
                XCTAssert(false, "andThen Failure")
            }
        }
        promise.success(true)
        XCTAssert(successCalled, "andThen .Success not called")
        XCTAssertFutureSucceeds(andThen, context: self.immediateContext) { value in
            XCTAssert(value, "andThen onSuccess value invalid")
        }
    }
    
    func testAndThen_FollowingFailedFuture_CompletesWithError() {
        var failureCalled = false
        let promise = Promise<Bool>()
        let future = promise.future
        let andThen = future.andThen(self.immediateContext) {result in
            switch result {
            case .Success(_):
                XCTAssert(false, "andThen Failure")
            case .Failure(_):
                failureCalled = true
            }
        }
        promise.failure(TestFailure.error)
        XCTAssert(failureCalled, "andThen .Failure not called")
        XCTAssertFutureFails(andThen, context: self.immediateContext) { error in
            XCTAssertEqual(error.code, TestFailure.error.code, "Error code invalid")
        }
    }
    
}
