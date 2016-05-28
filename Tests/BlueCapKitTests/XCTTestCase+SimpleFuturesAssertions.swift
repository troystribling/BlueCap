//
//  XCTTestCase+SimpleFutures.swift
//  BlueCapKit
//
//  Created by Troy Stribling on 5/5/16.
//  Copyright © 2016 Troy Stribling. All rights reserved.
//

import Foundation
import XCTest
import SimpleFutures

extension XCTestCase  {

    func XCTAssertFutureSucceeds<T>(future: Future<T>, context: ExecutionContext = QueueContext.main, timeout: NSTimeInterval = 10.0,
                                 line: UInt = #line, file: String = #file, validate: ((T) -> Void)? = nil) {
        var expectation: XCTestExpectation?
        var onSuccessCalled = false
        if context is QueueContext {
            expectation = self.expectationWithDescription("onSuccess expectation failed")
        }
        future.onSuccess(context) { result in
            onSuccessCalled = true
            expectation?.fulfill()
            validate?(result)
        }
        future.onFailure(context) { _ in
            XCTFail("onFailure called")
        }
        if context is QueueContext {
            self.waitForExpectationsWithTimeout(timeout) { error in
                if error != nil {
                    let message = "Failed to meet expectation after \(timeout)s"
                    self.recordFailureWithDescription(message, inFile: file, atLine: line, expected: true)
                } else {
                    if !onSuccessCalled {
                        self.recordFailureWithDescription("onSuccess not called", inFile: file, atLine: line, expected: true)
                    }
                }
            }
        } else {
            if !onSuccessCalled {
                self.recordFailureWithDescription("onSuccess not called", inFile: file, atLine: line, expected: true)
            }
        }
    }

    func XCTAssertFutureStreamSucceeds<T>(future: FutureStream<T>, context: ExecutionContext = QueueContext.main, timeout: NSTimeInterval = 10.0, line: UInt = #line, file: String = #file, validations: [((T) -> Void)] = []) {
        var expectation: XCTestExpectation?
        let maxCount = validations.count
        var count = 0
        if context is QueueContext {
            expectation = self.expectationWithDescription("onSuccess expectation failed")
        }
        future.onSuccess(context) { result in
            count += 1
            if maxCount == 0 {
                expectation?.fulfill()
            } else if count > maxCount {
                XCTFail("onSuccess called more than \(maxCount) times")
            } else {
                validations[count - 1](result)
                if count == maxCount {
                    expectation?.fulfill()
                }
            }
        }
        future.onFailure(context) { _ in
            XCTFail("onFailure called")
        }
        if context is QueueContext {
            self.waitForExpectationsWithTimeout(timeout) { error in
                if error == nil {
                    if maxCount == 0 {
                        // no validations given onSuccess only called one time
                        if count != 1 {
                            self.recordFailureWithDescription("onSuccess not called", inFile: file, atLine: line, expected: true)
                        }
                    } else {
                        // validations given onSuccess called for each validation
                        if maxCount != count {
                            let message = "onSuccess not called \(maxCount) times"
                            self.recordFailureWithDescription(message, inFile: file, atLine: line, expected: true)
                        }
                    }
                } else {
                    // expectation not filfilled
                    let message = "Failed to meet expectation after \(timeout)s"
                    self.recordFailureWithDescription(message, inFile: file, atLine: line, expected: true)
                }
            }
        } else {
            if maxCount == 0 {
                // no validations given onSuccess only called one time
                if count != 1 {
                    self.recordFailureWithDescription("onSuccess not called", inFile: file, atLine: line, expected: true)
                }
            } else {
                // validations given onSuccess called once for each validation
                if maxCount != count {
                    self.recordFailureWithDescription("onSuccess not called \(maxCount) times", inFile: file, atLine: line, expected: true)
                }
            }
        }
    }


    func XCTAssertFutureFails<T>(future: Future<T>, context: ExecutionContext = QueueContext.main, timeout: NSTimeInterval = 10.0,
                              line: UInt = #line, file: String = #file, validate: ((NSError) -> Void)? = nil) {
        var expectation: XCTestExpectation?
        var onFailureCalled = false
        if context is QueueContext {
            expectation = self.expectationWithDescription("onSuccess expectation failed")
        }
        future.onSuccess(context) { _ in
            XCTFail("onSuccess called")
        }
        future.onFailure(context) { error in
            onFailureCalled = true
            expectation?.fulfill()
            validate?(error)
        }
        if context is QueueContext {
            self.waitForExpectationsWithTimeout(timeout) { error in
                if error != nil {
                    let message = "Failed to meet expectation after \(timeout)s"
                    self.recordFailureWithDescription(message, inFile: file, atLine: line, expected: true)
                } else {
                    if !onFailureCalled {
                        self.recordFailureWithDescription("onFailure not called", inFile: file, atLine: line, expected: true)
                    }
                }
            }
        } else {
            if !onFailureCalled {
                self.recordFailureWithDescription("onFailure not called", inFile: file, atLine: line, expected: true)
            }
        }
    }

    func XCTAssertFutureStreamFails<T>(future: FutureStream<T>, context: ExecutionContext = QueueContext.main, timeout: NSTimeInterval = 10.0,
                                    line: UInt = #line, file: String = #file, validations: [((NSError) -> Void)] = []) {
        var expectation: XCTestExpectation?
        let maxCount = validations.count
        var count = 0
        if context is QueueContext {
            expectation = self.expectationWithDescription("onSuccess expectation failed")
        }
        future.onSuccess(context) { _ in
            XCTFail("onFailure called")
        }
        future.onFailure(context) { error in
            count += 1
            if maxCount == 0 {
                expectation?.fulfill()
            } else if count > maxCount {
                XCTFail("onFailure called more than maxCount \(maxCount) times")
            } else {
                validations[count - 1](error)
                if count == maxCount {
                    expectation?.fulfill()
                }
            }
        }
        if context is QueueContext {
            self.waitForExpectationsWithTimeout(timeout) { error in
                if error == nil {
                    if maxCount == 0 {
                        // no validations given onFailure only called one time
                        if count != 1 {
                            self.recordFailureWithDescription("onFailure not called", inFile: file, atLine: line, expected: true)
                        }
                    } else {
                        // validations given onFailure called once for each validation
                        if maxCount != count {
                            let message = "onFailure not called \(maxCount) times"
                            self.recordFailureWithDescription(message, inFile: file, atLine: line, expected: true)
                        }
                    }
                } else {
                    // expectation not fulfilled
                    let message = "Failed to meet expectation after \(timeout)s"
                    self.recordFailureWithDescription(message, inFile: file, atLine: line, expected: true)
                }
            }
        } else {
            if maxCount == 0 {
                // no validations given onFailure only called one time
                if count != 1 {
                    self.recordFailureWithDescription("onFailure not called", inFile: file, atLine: line, expected: true)
                }
            } else {
                // validations given onFailure called once for each validation
                if maxCount != count {
                    self.recordFailureWithDescription("onFailure not called \(maxCount) times", inFile: file, atLine: line, expected: true)
                }
            }
        }
    }

}
