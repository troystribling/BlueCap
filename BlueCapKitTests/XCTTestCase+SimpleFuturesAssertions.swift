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

protocol SimpleFutureAssertions {
    func expectationWithDescription(description: String) -> XCTestExpectation
    func waitForExpectationsWithTimeout(timeout: NSTimeInterval, handler: XCWaitCompletionHandler?)
}

extension XCTestCase : SimpleFutureAssertions {}

extension SimpleFutureAssertions {

    func XCTAssertFutureSucceeds<T>(future: Future<T>, context: ExecutionContext = QueueContext.main,
                                 line: UInt = #line, file: StaticString = #file, validate: ((T)->Void)? = nil) {

    }
}
