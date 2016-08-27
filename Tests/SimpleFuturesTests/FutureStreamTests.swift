//
//  FutureStreamTests.swift
//  SimpleFuturesTests
//
//  Created by Troy Stribling on 8/8/16.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import XCTest
@testable import BlueCapKit

class FutureStreamTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    // MARK: - onSuccess -
    
    func testOnSuccess_WhenCompletedBeforeCallbacksDefined_CompletesSuccessfully() {
        let future = FutureStream<Bool>()
        var onSuccessCalled = 0
        future.success(true)
        future.success(true)
        future.success(true)
        future.onSuccess(context: TestContext.immediate) {value in
            if value {
                onSuccessCalled += 1
            }
        }
        future.onFailure(context: TestContext.immediate) { _ in
            XCTFail()
        }
        XCTAssertEqual(onSuccessCalled, 3)
    }

    func testOnSuccess_WhenCompletedAfterCallbacksDefined_CompletesSuccessfully() {
        let future = FutureStream<Bool>()
        var onSuccessCalled = 0
        future.onSuccess(context: TestContext.immediate) {value in
            if value {
                onSuccessCalled += 1
            }
        }
        future.onFailure(context: TestContext.immediate) { _ in
            XCTFail()
        }
        future.success(true)
        future.success(true)
        future.success(true)
        XCTAssertEqual(onSuccessCalled, 3)
    }

    func testOnSuccess_WhenCompletedBeforeAndAfterCallbacksDefined_CompletesSuccessfully() {
        let future = FutureStream<Bool>()
        var onSuccessCalled = 0
        future.success(true)
        future.onSuccess(context: TestContext.immediate) {value in
            if value {
                onSuccessCalled += 1
            }
        }
        future.onFailure(context: TestContext.immediate) { _ in
            XCTFail()
        }
        future.success(true)
        future.success(true)
        XCTAssertEqual(onSuccessCalled, 3)
    }

    func testOnSuccess_WhenCompletedWithMultipleCallbacksDefined_CompletesSuccessfully() {
        let future = FutureStream<Bool>()
        var onSuccessCalled1 = 0
        var onSuccessCalled2 = 0
        future.onSuccess(context: TestContext.immediate) {value in
            if value {
                onSuccessCalled1 += 1
            }
        }
        future.onSuccess(context: TestContext.immediate) {value in
            if value {
                onSuccessCalled2 += 1
            }
        }
        future.onFailure(context: TestContext.immediate) { _ in
            XCTFail()
        }
        future.success(true)
        future.success(true)
        future.success(true)
        XCTAssertEqual(onSuccessCalled1, 3)
        XCTAssertEqual(onSuccessCalled2, 3)
    }

    func testOnSuccess_WhenCompletedWithSuccessAndFailure_CompletesSuccessfullyAndWithError() {
        let future = FutureStream<Bool>()
        var onSuccessCalled = 0
        var onFailureCalled = 0
        future.onSuccess(context: TestContext.immediate) {value in
            if value {
                onSuccessCalled += 1
            }
        }
        future.onFailure(context: TestContext.immediate) { error in
            XCTAssertEqualErrors(error, TestFailure.error)
            onFailureCalled += 1
        }
        future.success(true)
        future.success(true)
        future.success(true)
        future.failure(TestFailure.error)
        future.failure(TestFailure.error)
        future.failure(TestFailure.error)
        XCTAssertEqual(onSuccessCalled, 3)
        XCTAssertEqual(onFailureCalled, 3)
    }

    // MARK: - onFailure -

    func testOnFailure_WhenCompletedBeforeCallbacksDefined_CompletesWithError() {
        let stream = FutureStream<Bool>()
        var onFailureCalled = 0
        stream.failure(TestFailure.error)
        stream.failure(TestFailure.error)
        stream.failure(TestFailure.error)
        stream.onSuccess(context: TestContext.immediate) { _ in
            XCTFail()
        }
        stream.onFailure(context: TestContext.immediate) { error in
            XCTAssertEqualErrors(error, TestFailure.error)
            onFailureCalled += 1
        }
        XCTAssertEqual(onFailureCalled, 3)
    }

    func testOnSuccess_WhenCompletedBeforeCallbacksDefined_CompletesWithError() {
        let stream = FutureStream<Bool>()
        var onFailureCalled = 0
        stream.onSuccess(context: TestContext.immediate) { _ in
            XCTFail()
        }
        stream.onFailure(context: TestContext.immediate) { error in
            XCTAssertEqualErrors(error, TestFailure.error)
            onFailureCalled += 1
        }
        stream.failure(TestFailure.error)
        stream.failure(TestFailure.error)
        stream.failure(TestFailure.error)
        XCTAssertEqual(onFailureCalled, 3)
    }

    func testOnSuccess_WhenCompletedBeforeAndAfterCallbacksDefined_CompletesWithError() {
        let stream = FutureStream<Bool>()
        var onFailureCalled = 0
        stream.failure(TestFailure.error)
        stream.failure(TestFailure.error)
        stream.onSuccess(context: TestContext.immediate) { _ in
            XCTFail()
        }
        stream.onFailure(context: TestContext.immediate) { error in
            XCTAssertEqualErrors(error, TestFailure.error)
            onFailureCalled += 1
        }
        stream.failure(TestFailure.error)
        XCTAssertEqual(onFailureCalled, 3)
    }

    // MARK: - capacity -

    func testOnSuccess_WithInfiniteCapacityCompletedBeforeCallbacksDefined_CompletesSuccessfully() {
        let stream = FutureStream<Bool>()
        var onSuccessCalled = 0
        stream.success(true)
        stream.success(true)
        stream.success(true)
        stream.success(true)
        stream.success(true)
        stream.success(true)
        stream.success(true)
        stream.success(true)
        stream.success(true)
        stream.success(true)
        stream.onSuccess(context: TestContext.immediate) {value in
            if value {
                onSuccessCalled += 1
            }
        }
        stream.onFailure(context: TestContext.immediate) { _ in
            XCTFail()
        }
        XCTAssertEqual(stream.count, 10)
        XCTAssertEqual(onSuccessCalled, 10)
    }

    func testOnSuccess_WithInfiniteCapacityCompletedAfterCallbacksDefined_CompletesSuccessfully() {
        let stream = FutureStream<Bool>()
        var onSuccessCalled = 0
        stream.onSuccess(context: TestContext.immediate) {value in
            if value {
                onSuccessCalled += 1
            }
        }
        stream.onFailure(context: TestContext.immediate) { _ in
            XCTFail()
        }
        stream.success(true)
        stream.success(true)
        stream.success(true)
        stream.success(true)
        stream.success(true)
        stream.success(true)
        stream.success(true)
        stream.success(true)
        stream.success(true)
        stream.success(true)
        XCTAssertEqual(stream.count, 10)
        XCTAssertEqual(onSuccessCalled, 10)
    }

    func testOnSuccess_WithFiniteCapacityCompletedBeforeCallbacksDefined_CompletesSuccessfully() {
        let stream = FutureStream<Bool>(capacity: 2)
        var onSuccessCalled = 0
        stream.success(true)
        stream.success(true)
        stream.success(true)
        stream.success(true)
        stream.success(true)
        stream.success(true)
        stream.success(true)
        stream.success(true)
        stream.success(true)
        stream.success(true)
        stream.onSuccess(context: TestContext.immediate) {value in
            if value {
                onSuccessCalled += 1
            }
        }
        stream.onFailure(context: TestContext.immediate) { _ in
            XCTFail()
        }
        XCTAssertEqual(stream.count, 2)
        XCTAssertEqual(onSuccessCalled, 2)
    }

    func testOnSuccess_WithFiniteCapacityCompletedAfterCallbacksDefined_CompletesSuccessfully() {
        let stream = FutureStream<Bool>(capacity: 2)
        var onSuccessCalled = 0
        stream.onSuccess(context: TestContext.immediate) {value in
            if value {
                onSuccessCalled += 1
            }
        }
        stream.onFailure(context: TestContext.immediate) { _ in
            XCTFail()
        }
        stream.success(true)
        stream.success(true)
        stream.success(true)
        stream.success(true)
        stream.success(true)
        stream.success(true)
        stream.success(true)
        stream.success(true)
        stream.success(true)
        stream.success(true)
        XCTAssertEqual(stream.count, 2)
        XCTAssertEqual(onSuccessCalled, 10)
    }

    // MARK: - completeWith -

    func testCompletesWith_WhenDependentFutureStreamCompletedFirst_CompletesSuccessfullyWithDependentValue() {
        let stream = FutureStream<Int>()
        let dependentStream = FutureStream<Int>()

        dependentStream.success(1)
        dependentStream.success(2)
        stream.completeWith(context: TestContext.immediate, stream: dependentStream)

        XCTAssertFutureStreamSucceeds(stream, context: TestContext.immediate, validations: [
            { value in
                XCTAssertEqual(value, 1)
            },
            { value in
                XCTAssertEqual(value, 2)
            }
        ])
    }

    func testCompletesWith_WhenDependentFutureStreamCompletedLast_CompletesSuccessfullyWithDependentValue() {
        let stream = FutureStream<Int>()
        let dependentStream = FutureStream<Int>()

        stream.completeWith(context: TestContext.immediate, stream: dependentStream)
        dependentStream.success(1)
        dependentStream.success(2)

        XCTAssertFutureStreamSucceeds(stream, context: TestContext.immediate, validations: [
            { value in
                XCTAssertEqual(value, 1)
            },
            { value in
                XCTAssertEqual(value, 2)
            }
        ])
    }

    func testCompletesWith_WhenDependentFutureStreamFails_CompletesWithDependantError() {
        let stream = FutureStream<Int>()
        let dependentStream = FutureStream<Int>()

        stream.completeWith(context: TestContext.immediate, stream: dependentStream)
        dependentStream.failure(TestFailure.error)
        dependentStream.failure(TestFailure.error)

        XCTAssertFutureStreamFails(stream, context: TestContext.immediate, validations: [
            { error in
                XCTAssertEqualErrors(error, TestFailure.error)
            },
            { error in
                XCTAssertEqualErrors(error, TestFailure.error)
            }
        ])
    }

    func testCompletesWith_WhenDependentFutureSucceeds_CompletesWithDependantValue() {
        let stream = FutureStream<Int>()
        let dependentFuture = Future<Int>()

        stream.completeWith(context: TestContext.immediate, future: dependentFuture)
        dependentFuture.success(1)

        XCTAssertFutureStreamSucceeds(stream, context: TestContext.immediate, validations: [
            { value in
                XCTAssertEqual(value, 1)
            }
        ])
    }

    func testCompletesWith_WhenDependentFutureFails_CompletesWithDependantError() {
        let stream = FutureStream<Int>()
        let dependentFuture = Future<Int>()

        stream.completeWith(context: TestContext.immediate, future: dependentFuture)
        dependentFuture.failure(TestFailure.error)

        XCTAssertFutureStreamFails(stream, context: TestContext.immediate, validations: [
            { error in
                XCTAssertEqualErrors(error, TestFailure.error)
            }
        ])
    }


    // MARK: - map -

    func testMap_WhenFutureStreamAndMapSucceed_MapCalledCompletesSuccessfully() {
        let stream = FutureStream<Int>()
        let mapped = stream.map(context: TestContext.immediate) { value -> Int in
            return value + 1
        }
        stream.success(1)
        stream.success(2)
        XCTAssertFutureStreamSucceeds(mapped, context: TestContext.immediate, validations: [
            { value in
                XCTAssertEqual(value, 2)
            },
            { value in
                XCTAssertEqual(value, 3)
            }
        ])
    }

    func testMap_WhenFutureStreamFails_MapNotCalledCompletesWithError() {
        let stream = FutureStream<Int>()
        let mapped = stream.map(context: TestContext.immediate) {value -> Int in
            XCTFail()
            return 1
        }
        stream.failure(TestFailure.error)
        stream.failure(TestFailure.error)
        XCTAssertFutureStreamFails(mapped, context: TestContext.immediate, validations: [
            { error in
                XCTAssertEqualErrors(error, TestFailure.error)
            },
            { error in
                XCTAssertEqualErrors(error, TestFailure.error)
            }
        ])
    }

    func testMap_WhenFutureStreamSuccedsAndMapFails_MapCalledCompletesWithError() {
        let stream = FutureStream<Int>()
        let mapped = stream.map(context: TestContext.immediate) {value -> Int in
            throw TestFailure.error
        }
        stream.success(1)
        stream.success(2)
        XCTAssertFutureStreamFails(mapped, context: TestContext.immediate, validations: [
            { error in
                XCTAssertEqualErrors(error, TestFailure.error)
            },
            { error in
                XCTAssertEqualErrors(error, TestFailure.error)
            }
        ])
    }

    // MARK: - flatMap -

    func testFlatMap_WhenFutureStreamAndFlatMapSucceed_FlatMapCalledCompletesSuccessfully() {
        let stream = FutureStream<Int>()
        let mapped = stream.flatMap(context: TestContext.immediate) { value -> FutureStream<Bool> in
            let result = FutureStream<Bool>()
            result.success(value > 1)
            return result
        }
        stream.success(1)
        stream.success(2)
        XCTAssertFutureStreamSucceeds(mapped, context: TestContext.immediate, validations: [
            { value in
                XCTAssertFalse(value)
            },
            { value in
                XCTAssertTrue(value)
            }
        ])
    }

    func testFlatMap_WhenFutureStreamFails_FlatMapNotCalledCompletesWithError() {
        let stream = FutureStream<Int>()
        let mapped = stream.flatMap(context: TestContext.immediate) { value -> FutureStream<Bool> in
            let result = FutureStream<Bool>()
            result.success(value > 1)
            return result
        }
        stream.failure(TestFailure.error)
        stream.failure(TestFailure.error)
        XCTAssertFutureStreamFails(mapped, context: TestContext.immediate, validations: [
            { error in
                XCTAssertEqualErrors(error, TestFailure.error)
            },
            { error in
                XCTAssertEqualErrors(error, TestFailure.error)
            }
        ])
    }

    func testFlatMap_WhenFutureStreamSucceedsAndFlatMapFails_FlatMapCalledCompletesWithError() {
        let stream = FutureStream<Int>()
        let mapped = stream.flatMap(context: TestContext.immediate) { value -> FutureStream<Bool> in
            throw TestFailure.error
        }
        stream.success(1)
        stream.success(2)
        XCTAssertFutureStreamFails(mapped, context: TestContext.immediate, validations: [
            { error in
                XCTAssertEqualErrors(error, TestFailure.error)
            },
            { error in
                XCTAssertEqualErrors(error, TestFailure.error)
            }
        ])
    }

    func testFlatMap_WhenFutureStreamSucceedsAndFlatMapToFailedFutureStream_FlatMapCalledCompletesWithError() {
        let stream = FutureStream<Int>()
        let mapped = stream.flatMap(context: TestContext.immediate) { value -> FutureStream<Bool> in
            let result = FutureStream<Bool>()
            result.failure(TestFailure.error)
            return result
        }
        stream.success(1)
        stream.success(2)
        XCTAssertFutureStreamFails(mapped, context: TestContext.immediate, validations: [
            { error in
                XCTAssertEqualErrors(error, TestFailure.error)
            },
            { error in
                XCTAssertEqualErrors(error, TestFailure.error)
            }
        ])
    }

    func testFlatMap_WhenFutureStreamSuccedsAndFlatMapFutureStreamCompletesMultipleTimes_FlatMapCalledCompletesSuccessfully() {
        let stream = FutureStream<Int>()
        let result = FutureStream<Bool>()
        let mapped = stream.flatMap(context: TestContext.immediate) { value -> FutureStream<Bool> in
            return result
        }
        stream.success(1)
        stream.success(2)
        result.success(true)
        result.success(false)
        XCTAssertFutureStreamSucceeds(mapped, context: TestContext.immediate, validations: [
            { value in
                XCTAssertTrue(value)
            },
            { value in
                XCTAssertTrue(value)
            },
            { value in
                XCTAssertFalse(value)
            },
            { value in
                XCTAssertFalse(value)
            }
       ])
    }

    func testFlatMap_WhenFutureStreamSuccedsAndFlatMapReturnsSuccessfulFuture_FlatMapCalledCompletesSuccessfully() {
        let stream = FutureStream<Int>()
        let mapped = stream.flatMap(context: TestContext.immediate) { value -> Future<Bool> in
            return Future(value: value > 1)
        }
        stream.success(1)
        stream.success(2)
        XCTAssertFutureStreamSucceeds(mapped, context: TestContext.immediate, validations: [
            { value in
                XCTAssertFalse(value)
            },
            { value in
                XCTAssertTrue(value)
            }
        ])
    }

    func testFlatMap_WhenFutureStreamSuccedsAndFlatMapReturnsFailedFuture_FlatMapCalledCompletesWithError() {
        let stream = FutureStream<Int>()
        let mapped = stream.flatMap(context: TestContext.immediate) { value -> Future<Bool> in
            return Future(error: TestFailure.error)
        }
        stream.success(1)
        stream.success(2)
        XCTAssertFutureStreamFails(mapped, context: TestContext.immediate, validations: [
            { error in
                XCTAssertEqualErrors(error, TestFailure.error)
            },
            { error in
                XCTAssertEqualErrors(error, TestFailure.error)
            }
        ])
    }

    func testFlatMap_WhenFutureStreamFailsAndFlatMapReturnsFuture_FlatMapNotCalledCompletesWithError() {
        let stream = FutureStream<Int>()
        let mapped = stream.flatMap(context: TestContext.immediate) { value -> Future<Bool> in
            XCTFail()
            return Future(value: value > 1)
        }
        stream.failure(TestFailure.error)
        stream.failure(TestFailure.error)
        XCTAssertFutureStreamFails(mapped, context: TestContext.immediate, validations: [
            { error in
                XCTAssertEqualErrors(error, TestFailure.error)
            },
            { error in
                XCTAssertEqualErrors(error, TestFailure.error)
            }
        ])
    }

    func testFlatMap_WhenFlatMapFailsReturningFuture_FlatMapCalledCompletesWithError() {
        let stream = FutureStream<Int>()
        let mapped = stream.flatMap(context: TestContext.immediate) { value -> Future<Bool> in
            throw TestFailure.error
        }
        stream.success(1)
        stream.success(2)
        XCTAssertFutureStreamFails(mapped, context: TestContext.immediate, validations: [
            { error in
                XCTAssertEqualErrors(error, TestFailure.error)
            },
            { error in
                XCTAssertEqualErrors(error, TestFailure.error)
            }
        ])
    }

    // MARK: - recover -

    func testRecover_WhenFutureStreamSucceeds_RecoverNotCalledCompletesSuccessfully() {
        let stream = FutureStream<Int>()
        let recovered = stream.recover(context: TestContext.immediate) { error -> Int in
            XCTFail()
            return 1
        }
        stream.success(1)
        stream.success(2)
        XCTAssertFutureStreamSucceeds(recovered, context: TestContext.immediate, validations: [
            { value in
                XCTAssertEqual(value, 1)
            },
            { value in
                XCTAssertEqual(value, 2)
            }
        ])
    }

    func testRecover_WhenFutureStreamFailsAndRecoverySucceeds_RecoverCalledCompletesSuccessfully() {
        let stream = FutureStream<Int>()
        let recovered = stream.recover(context: TestContext.immediate) { error -> Int in
            return 1
        }
        stream.failure(TestFailure.error)
        stream.failure(TestFailure.error)
        XCTAssertFutureStreamSucceeds(recovered, context: TestContext.immediate, validations: [
            { value in
                XCTAssertEqual(value, 1)
            },
            { value in
                XCTAssertEqual(value, 1)
            }
        ])
    }

    func testRecovery_WhenFutureStreamFailsAndRecoveryFails_RecoverCallledCompletesWithError() {
        let stream = FutureStream<Int>()
        let recovered = stream.recover(context: TestContext.immediate) { error -> Int in
            throw TestFailure.error
        }
        stream.failure(TestFailure.error)
        stream.failure(TestFailure.error)
        XCTAssertFutureStreamFails(recovered, context: TestContext.immediate, validations: [
            { error in
                XCTAssertEqualErrors(error, TestFailure.error)
            },
            { error in
                XCTAssertEqualErrors(error, TestFailure.error)
            }
        ])
    }

    // MARK: - recoverWith -

    func testRecoverWith_WhenFutureStreamSucceedsAndRecoveryReturnsFutureStream_RecoverWithNotCalledCompletesSuccessfully() {
        let stream = FutureStream<Bool>()
        let recoveredResult = FutureStream<Bool>()
        let recovered = stream.recoverWith(context: TestContext.immediate) { error -> FutureStream<Bool> in
            XCTFail()
            return recoveredResult
        }
        stream.success(true)
        stream.success(false)
        XCTAssertFutureStreamSucceeds(recovered, context: TestContext.immediate, validations: [
            { value in
                XCTAssert(value)
            },
            { value in
                XCTAssertFalse(value)
            }
        ])
    }

    func testRecoverWith_WhenFutureStreamFailsAndRecoveryReturnsSuccesfullFutureStream_RecoverWithCalledCompletesSuccessfully() {
        let stream = FutureStream<Bool>()
        let recoveredResult = FutureStream<Bool>()
        let recovered = stream.recoverWith(context: TestContext.immediate) { error -> FutureStream<Bool> in
            return recoveredResult
        }
        stream.failure(TestFailure.error)
        stream.failure(TestFailure.error)
        recoveredResult.success(true)
        XCTAssertFutureStreamSucceeds(recovered, context: TestContext.immediate, validations: [
            { value in
                XCTAssert(value)
            },
            { value in
                XCTAssert(value)
            }
        ])
    }

    func testRecoverWith_WhenFutureStreamFailsAndRecoveryReturnsFailedFutureStream_RecoverWithCalledCompletesWithError() {
        let stream = FutureStream<Bool>()
        let recoveredResult = FutureStream<Bool>()
        let recovered = stream.recoverWith(context: TestContext.immediate) { error -> FutureStream<Bool> in
            return recoveredResult
        }
        stream.failure(TestFailure.error)
        stream.failure(TestFailure.error)
        recoveredResult.failure(TestFailure.error)
        XCTAssertFutureStreamFails(recovered, context: TestContext.immediate, validations: [
            { error in
                XCTAssertEqualErrors(error, TestFailure.error)
            },
            { error in
                XCTAssertEqualErrors(error, TestFailure.error)
            }
        ])
    }

    func testRecoverWith_WhenFutureStreamFailsAndRecoveryFails_RecoverWithCalledCompletesWithError() {
        let stream = FutureStream<Bool>()
        let recovered = stream.recoverWith(context: TestContext.immediate) { error -> FutureStream<Bool> in
            throw TestFailure.error
        }
        stream.failure(TestFailure.error)
        stream.failure(TestFailure.error)
        XCTAssertFutureStreamFails(recovered, context: TestContext.immediate, validations: [
            { error in
                XCTAssertEqualErrors(error, TestFailure.error)
            },
            { error in
                XCTAssertEqualErrors(error, TestFailure.error)
            }
        ])
    }

    func testRecoverWith_WhenFutureStreamSucceedsAndRecoveryReturnsFuture_RecoverWithNotCalledCompletesSuccessfully() {
        let stream = FutureStream<Bool>()
        let recoveredResult = Future<Bool>()
        let recovered = stream.recoverWith(context: TestContext.immediate) { error -> Future<Bool> in
            XCTFail()
            return recoveredResult
        }
        stream.success(true)
        stream.success(true)
        XCTAssertFutureStreamSucceeds(recovered, context: TestContext.immediate, validations: [
            { value in
                XCTAssert(value)
            },
            { value in
                XCTAssert(value)
            }
        ])
    }

    func testRecoverWith_WhenFutureStreamFailsAndRecoveryReturnsSuccesfullFuture_RecoverWithCalledCompletesSuccessfully() {
        let stream = FutureStream<Bool>()
        let recoveredResult = Future<Bool>()
        let recovered = stream.recoverWith(context: TestContext.immediate) { error -> Future<Bool> in
            return recoveredResult
        }
        stream.failure(TestFailure.error)
        stream.failure(TestFailure.error)
        recoveredResult.success(true)
        XCTAssertFutureStreamSucceeds(recovered, context: TestContext.immediate, validations: [
            { value in
                XCTAssert(value)
            },
            { value in
                XCTAssert(value)
            }
        ])
    }

    func testRecoverWith_WhenFutureStreamFailsAndRecoveryReturnsFailedFuture_RecoverWithCalledCompletesWithError() {
        let stream = FutureStream<Bool>()
        let recoveredResult = Future<Bool>()
        let recovered = stream.recoverWith(context: TestContext.immediate) { error -> Future<Bool> in
            return recoveredResult
        }
        stream.failure(TestFailure.error)
        stream.failure(TestFailure.error)
        recoveredResult.failure(TestFailure.error)
        XCTAssertFutureStreamFails(recovered, context: TestContext.immediate, validations: [
            { error in
                XCTAssertEqualErrors(error, TestFailure.error)
            },
            { error in
                XCTAssertEqualErrors(error, TestFailure.error)
            }
        ])
    }

    func testRecoverWith_WhenFutureStreamFailsAndFutureRecoveryFails_RecoverWithCalledCompletesWithError() {
        let stream = FutureStream<Bool>()
        let recovered = stream.recoverWith(context: TestContext.immediate) {error -> Future<Bool> in
            throw TestFailure.recoveryError
        }
        stream.failure(TestFailure.error)
        stream.failure(TestFailure.error)
        XCTAssertFutureStreamFails(recovered, context: TestContext.immediate, validations: [
            { error in
                XCTAssertEqualErrors(error, TestFailure.recoveryError)
            },
            { error in
                XCTAssertEqualErrors(error, TestFailure.recoveryError)
            }
        ])
    }

    // MARK: - withFilter -

    func testWithFilter_WhenFututreStreamSucceedsAndFilterSucceds_WithFilterCalledCompletesSuccessfully() {
        let stream = FutureStream<Int>()
        let filtered = stream.withFilter(context: TestContext.immediate) { value -> Bool in
            return value < 1
        }
        stream.success(0)
        stream.success(-1)
        XCTAssertFutureStreamSucceeds(filtered, context: TestContext.immediate, validations: [
            { value in
                XCTAssertEqual(0, value)
            },
            { value in
                XCTAssertEqual(-1, value)
            }
        ])
    }

    func testWithFilter_WhenFututreStreamSucceedsAndFilterFails_WithFilterCalledCompletesWithError() {
        let stream = FutureStream<Int>()
        let filtered = stream.withFilter(context: TestContext.immediate) { value -> Bool in
            return value < 1
        }
        stream.success(1)
        stream.success(2)
        XCTAssertFutureStreamFails(filtered, context: TestContext.immediate, validations: [
            { error in
                XCTAssertEqualErrors(error, FuturesError.noSuchElement)
            },
            { error in
                XCTAssertEqualErrors(error, FuturesError.noSuchElement)
            }
        ])
    }

    func testWithFilter_WhenFututreStreamFails_WithFilterNotCalledCompletesWithError() {
        let stream = FutureStream<Int>()
        let filtered = stream.withFilter(context: TestContext.immediate) { value -> Bool in
            XCTFail()
            return value < 1
        }
        stream.failure(TestFailure.error)
        stream.failure(TestFailure.error)
        XCTAssertFutureStreamFails(filtered, context: TestContext.immediate, validations: [
            { error in
                XCTAssertEqualErrors(error, TestFailure.error)
            },
            { error in
                XCTAssertEqualErrors(error, TestFailure.error)
            }
        ])
    }

    func testWithFilter_WhenFututreStreamSucceedsAndFilterThrows_WithFilterCalledCompletesWithError() {
        let stream = FutureStream<Int>()
        let filtered = stream.withFilter(context: TestContext.immediate) { value -> Bool in
            throw TestFailure.error
        }
        stream.success(0)
        stream.success(1)
        XCTAssertFutureStreamFails(filtered, context: TestContext.immediate, validations: [
            { error in
                XCTAssertEqualErrors(error, TestFailure.error)
            },
            { error in
                XCTAssertEqualErrors(error, TestFailure.error)
            }
        ])
    }

    // MARK: - forEach -

    func testForEach_WhenFutureStreamSucceeds_ForEachCalledCompletesSuccessfully() {
        let stream = FutureStream<Int>()
        var forEachCount = 0
        stream.forEach(context: TestContext.immediate) { value in
            forEachCount += value
        }
        stream.success(1)
        stream.success(2)
        XCTAssertEqual(forEachCount, 3)
        XCTAssertFutureStreamSucceeds(stream, context: TestContext.immediate, validations: [
            { value in
                XCTAssertEqual(1, value)
            },
            { value in
                XCTAssertEqual(2, value)
            }
        ])
    }

    func testForEach_WhenFutureStreamfailes_ForNotEachCalledCompletesWithError() {
        let stream = FutureStream<Int>()
        stream.forEach(context: TestContext.immediate) { value in
            XCTFail()
        }
        stream.failure(TestFailure.error)
        stream.failure(TestFailure.error)
        XCTAssertFutureStreamFails(stream, context: TestContext.immediate, validations: [
            { error in
                XCTAssertEqualErrors(error, TestFailure.error)
            },
            { error in
                XCTAssertEqualErrors(error, TestFailure.error)
            }
        ])
    }


    // MARK: - andThen -

    func testAndThen_WhenFutureStreamSucceeds_AndThenCalledCompletesSuccessfully() {
        let stream = FutureStream<Bool>()
        var andThenCalled = 0
        let andThen = stream.andThen(context: TestContext.immediate) { _ in
            andThenCalled += 1
        }
        stream.success(true)
        stream.success(true)
        XCTAssertFutureStreamSucceeds(andThen, context: TestContext.immediate, validations: [
            { value in
                XCTAssertTrue(value)
            },
            { value in
                XCTAssertTrue(value)
            }
        ])
        XCTAssertEqual(andThenCalled, 2)
    }

    func testAndThen_WhenFutureStreamFails_AndThenNotCalledCompletesWithFailure() {
        let stream = FutureStream<Bool>()
        let andThen = stream.andThen(context: TestContext.immediate) {result in
            XCTFail()
        }
        stream.failure(TestFailure.error)
        stream.failure(TestFailure.error)
        XCTAssertFutureStreamFails(andThen, context: TestContext.immediate, validations: [
            { error in
                XCTAssertEqualErrors(error, TestFailure.error)
            },
            { error in
                XCTAssertEqualErrors(error, TestFailure.error)
            }
        ])
    }

    // MARK: - mapError -

    func testMapError_WhenFutureStreamSucceeds_MapErrorNotCalledCompletesSuccessfully() {
        let stream = FutureStream<Int>()
        let mapError = stream.mapError(context: TestContext.immediate) { _ in
            XCTFail()
            return TestFailure.mappedError
        }
        stream.success(1)
        stream.success(2)
        XCTAssertFutureStreamSucceeds(mapError, context: TestContext.immediate, validations: [
            { value in
                XCTAssertEqual(value, 1)
            },
            { value in
                XCTAssertEqual(value, 2)
            }
        ])
    }

    func testMapError_WhenFutureStreamFails_MapErrorCalledCompletesWithMappedError() {
        let stream = FutureStream<Int>()
        let mapError = stream.mapError(context: TestContext.immediate) { _ in
            return TestFailure.mappedError
        }
        stream.failure(TestFailure.error)
        stream.failure(TestFailure.error)
        XCTAssertFutureStreamFails(mapError, context: TestContext.immediate, validations: [
            { error in
                XCTAssertEqualErrors(error, TestFailure.mappedError)
            },
            { error in
                XCTAssertEqualErrors(error, TestFailure.mappedError)
            }
        ])
    }

    // MARK: - cancel -

    func testCancel_ForOnSuccess_DoesNotComplete() {
        let stream = FutureStream<Int>()
        let cancelToken = CancelToken()
        stream.onSuccess(context: TestContext.immediate, cancelToken: cancelToken) { _ in
            XCTFail()
        }
        let status = stream.cancel(cancelToken)
        stream.success(1)
        XCTAssertTrue(status)
    }

    func testCancel_ForOnSuccessWhenFutureStreamCompletedBeforeAndAfterCancel_DoesNotCompleteAfterCancel() {
        let stream = FutureStream<Int>()
        let cancelToken = CancelToken()
        var onSuccessCalled = 0
        stream.onSuccess(context: TestContext.immediate, cancelToken: cancelToken) { _ in
            onSuccessCalled += 1
        }
        stream.success(1)
        let status = stream.cancel(cancelToken)
        stream.success(1)
        XCTAssertTrue(status)
        XCTAssertEqual(onSuccessCalled, 1)
    }

    func testCancel_ForOnSuccessWithInvalidCancelToken_CancelFails() {
        let stream = FutureStream<Int>()
        let cancelToken = CancelToken()
        var onSuccessCalled = 0
        stream.onSuccess(context: TestContext.immediate) { _ in
            onSuccessCalled += 1
        }
        stream.success(1)
        let status = stream.cancel(cancelToken)
        XCTAssertFalse(status)
        XCTAssertEqual(onSuccessCalled, 1)
    }

    func testCancel_ForOnFailure_DoesNotComplete() {
        let stream = FutureStream<Int>()
        let cancelToken = CancelToken()
        stream.onFailure(context: TestContext.immediate, cancelToken: cancelToken) { _ in
            XCTFail()
        }
        let status = stream.cancel(cancelToken)
        stream.success(1)
        XCTAssertTrue(status)
    }

    func testCancel_ForMap_DoesNotComplete() {
        let stream = FutureStream<Int>()
        let cancelToken = CancelToken()
        let mapped = stream.map(context: TestContext.immediate, cancelToken: cancelToken) { _ -> Bool in
            XCTFail()
            return false
        }
        mapped.onSuccess(context: TestContext.immediate) { _ in
            XCTFail()
        }
        let status = stream.cancel(cancelToken)
        stream.success(1)
        XCTAssertTrue(status)
    }

    func testCancel_MultipleCancelations_CancelSucceeedsAndDoesNotComplete() {
        let stream = FutureStream<Int>()
        let cancelToken = CancelToken()
        stream.onSuccess(context: TestContext.immediate, cancelToken: cancelToken) { _ in
            XCTFail()
        }
        let mapped = stream.map(context: TestContext.immediate, cancelToken: cancelToken) { _ -> Bool in
            XCTFail()
            return false
        }
        mapped.onSuccess(context: TestContext.immediate) { _ in
            XCTFail()
        }
        let status = stream.cancel(cancelToken)
        stream.success(1)
        XCTAssertTrue(status)
    }

    func testCancel_ForFlatMapReturningFutureStream_DoesNotComplete() {
        let stream = FutureStream<Int>()
        let result = FutureStream<Bool>()
        let cancelToken = CancelToken()
        let flatMapped = stream.flatMap(context: TestContext.immediate, cancelToken: cancelToken) { _ -> FutureStream<Bool> in
            XCTFail()
            return result
        }
        flatMapped.onSuccess(context: TestContext.immediate) { _ in
            XCTFail()
        }
        let status = stream.cancel(cancelToken)
        stream.success(1)
        XCTAssertTrue(status)
    }

    func testCanel_ForFlatMapReturningFuture_DoesNotComplete() {
        let stream = FutureStream<Int>()
        let cancelToken = CancelToken()
        let flatMapped = stream.flatMap(context: TestContext.immediate, cancelToken: cancelToken) { _ -> Future<Bool> in
            XCTFail()
            return Future(value: true)
        }
        flatMapped.onSuccess(context: TestContext.immediate) { _ in
            XCTFail()
        }
        let status = stream.cancel(cancelToken)
        stream.success(1)
        XCTAssertTrue(status)
    }

    func testCancel_ForAndThen_DoesNotComplete() {
        let stream = FutureStream<Int>()
        let cancelToken = CancelToken()
        let andThen = stream.andThen(context: TestContext.immediate, cancelToken: cancelToken) { _ in
            XCTFail()
        }
        andThen.onSuccess(context: TestContext.immediate) { _ in
            XCTFail()
        }
        let status = stream.cancel(cancelToken)
        stream.success(1)
        XCTAssertTrue(status)
    }

    func testCancel_ForRecover_DoesNotComplete() {
        let stream = FutureStream<Int>()
        let cancelToken = CancelToken()
        let recovered = stream.recover(context: TestContext.immediate, cancelToken: cancelToken) { _ in
            XCTFail()
            return 2
        }
        recovered.onSuccess(context: TestContext.immediate) { _ in
            XCTFail()
        }
        let status = stream.cancel(cancelToken)
        stream.success(1)
        XCTAssertTrue(status)
    }

    func testCancel_ForRecoverWith_DoesNotComplete() {
        let stream = FutureStream<Int>()
        let result = FutureStream<Int>()
        let cancelToken = CancelToken()
        let recovered = stream.recoverWith(context: TestContext.immediate, cancelToken: cancelToken) { _ -> FutureStream<Int> in
            XCTFail()
            return result
        }
        recovered.onSuccess(context: TestContext.immediate) { _ in
            XCTFail()
        }
        let status = stream.cancel(cancelToken)
        stream.success(1)
        XCTAssertTrue(status)
    }

    func testCanel_ForRecoverWithReturningFuture_DoesNotComplete() {
        let stream = FutureStream<Int>()
        let cancelToken = CancelToken()
        let recovered = stream.recoverWith(context: TestContext.immediate, cancelToken: cancelToken) { _ -> Future<Int> in
            XCTFail()
            return Future(value: 1)
        }
        recovered.onSuccess(context: TestContext.immediate) { _ in
            XCTFail()
        }
        let status = stream.cancel(cancelToken)
        stream.success(1)
        XCTAssertTrue(status)
    }

    func testCancel_ForWithFilter_DoesNotComplete() {
        let stream = FutureStream<Int>()
        let cancelToken = CancelToken()
        let filtered = stream.withFilter(context: TestContext.immediate, cancelToken: cancelToken) { _ in
            XCTFail()
            return true
        }
        filtered.onSuccess(context: TestContext.immediate) { _ in
            XCTFail()
        }
        let status = stream.cancel(cancelToken)
        stream.success(1)
        XCTAssertTrue(status)
    }

    func testCancel_ForForEach_DoesNotComplete() {
        let stream = FutureStream<Int>()
        let cancelToken = CancelToken()
        stream.forEach(context: TestContext.immediate, cancelToken: cancelToken) { _ in
            XCTFail()
        }
        let status = stream.cancel(cancelToken)
        stream.success(1)
        XCTAssertTrue(status)
    }

    func testCancel_ForMapError_DoesNotComplete() {
        let stream = FutureStream<Int>()
        let cancelToken = CancelToken()
        let mappedError = stream.mapError(context: TestContext.immediate, cancelToken: cancelToken) { _ in
            XCTFail()
            return TestFailure.mappedError
        }
        mappedError.onFailure(context: TestContext.immediate) { _ in
            XCTFail()
        }
        let status = stream.cancel(cancelToken)
        stream.failure(TestFailure.error)
        XCTAssertTrue(status)
    }

    // MARK: - StreamPromise -

    func testStreamPromiseSuccess_WhenCompleted_CompeletesSuccessfully() {
        let promise = StreamPromise<Bool>()
        promise.success(true)
        promise.success(false)
        XCTAssertFutureStreamSucceeds(promise.stream, context: TestContext.immediate, validations: [
            { value in
                XCTAssertTrue(value)
            },
            { value in
                XCTAssertFalse(value)
            }
        ])
    }

    func testStreamPromiseFailure_WhenCompleted_CompeletesWithError() {
        let promise = StreamPromise<Bool>()
        promise.failure(TestFailure.error)
        promise.failure(TestFailure.error)
        XCTAssertFutureStreamFails(promise.stream, context: TestContext.immediate, validations: [
            { error in
                XCTAssertEqualErrors(error, TestFailure.error)
            },
            { error in
                XCTAssertEqualErrors(error, TestFailure.error)
            }
        ])
    }

}
