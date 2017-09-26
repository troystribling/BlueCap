//
//  FutureTests.swift
//  SimpleFuturesTests
//
//  Created by Troy Stribling on 8/7/16.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import XCTest
@testable import BlueCapKit

class FutureTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }


    // MARK: - onSuccess -

    func testOnSuccess_WhenCompletedBeforeCallbacksDefined_CompletesSuccessfully() {
        let future = Future<Bool>()
        var onSuccessCalled = false
        future.success(true)
        future.onSuccess(context: TestContext.immediate) { value in
            onSuccessCalled = true
            XCTAssertTrue(value)
        }
        future.onFailure(context: TestContext.immediate) { _ in
            XCTFail()
        }
        XCTAssertTrue(onSuccessCalled)
    }

    func testOnSuccess_WhenCompletedAfterCallbacksDefined_CompletesSuccessfully() {
        let future = Future<Bool>()
        var onSuccessCalled = false
        future.onSuccess(context: TestContext.immediate) { value in
            onSuccessCalled = true
            XCTAssertTrue(value)
        }
        future.onFailure(context: TestContext.immediate) { _ in
            XCTFail()
        }
        future.success(true)
        XCTAssertTrue(onSuccessCalled)
    }

    func testOnSuccess_WhenCompletedWithMultipleCallbacksDefined_CompletesSuccessfully() {
        let future = Future<Bool>()
        var onSuccessCalled1 = false
        var onSuccessCalled2 = false
        future.onSuccess(context: TestContext.immediate) { value in
            onSuccessCalled1 = true
            XCTAssertTrue(value)
        }
        future.onFailure(context: TestContext.immediate) { _ in
            XCTFail()
        }
        future.onSuccess(context: TestContext.immediate) { value in
            onSuccessCalled2 = true
            XCTAssertTrue(value)
        }
        future.onFailure(context: TestContext.immediate) { _ in
            XCTFail()
        }
        future.success(true)
        XCTAssertTrue(onSuccessCalled1)
        XCTAssertTrue(onSuccessCalled2)
    }

    // MARK: - onFailure -

    func testOnFailure_CompletedBeforeCallbacksDefined_CompletesWithError() {
        let future = Future<Bool>()
        future.failure(TestFailure.error)
        XCTAssertFutureFails(future, context: TestContext.immediate) { error in
            XCTAssertEqualErrors(error, TestFailure.error)
        }
    }

    func testOnFailure_CompletedAfterCallbacksDefined_CompletesWithError() {
        let future = Future<Bool>()
        var onFailureCalled = false
        future.onSuccess(context: TestContext.immediate) { _ in
            XCTFail()
        }
        future.onFailure(context: TestContext.immediate) { error in
            onFailureCalled = true
            XCTAssertEqualErrors(error, TestFailure.error)
        }
        future.failure(TestFailure.error)
        XCTAssertTrue(onFailureCalled)
    }

    func testOnFailure_WithMultipleCallbacksDefined_CompletesWithError() {
        let future = Future<Bool>()
        var onFailure1Called = false
        var onFailure2Called = false
        future.onSuccess(context: TestContext.immediate) { value in
            XCTFail()
        }
        future.onFailure(context: TestContext.immediate) { error in
            onFailure1Called = true
            XCTAssertEqualErrors(error, TestFailure.error)
        }
        future.onSuccess(context: TestContext.immediate) { value in
            XCTFail()
        }
        future.onFailure(context: TestContext.immediate) { error in
            onFailure2Called = true
            XCTAssertEqualErrors(error, TestFailure.error)
        }
        future.failure(TestFailure.error)
        XCTAssertTrue(onFailure1Called)
        XCTAssertTrue(onFailure2Called)
    }

    // MARK: - completeWith -

    func testCompletesWith_WhenDependentFutureCompletedFirst_CompletesSuccessfullyWithDependentValue() {
        let future = Future<Bool>()
        let dependentFuture = Future<Bool>()

        dependentFuture.success(true)
        future.completeWith(context: TestContext.immediate, future: dependentFuture)

        XCTAssertFutureSucceeds(future, context: TestContext.immediate) { value in
            XCTAssertTrue(value)
        }
    }

    func testCompletesWith_WhenDependentFutureCompletedLast_CompletesSuccessfullyWithDependentValue() {
        let future = Future<Bool>()
        let dependentFuture = Future<Bool>()

        future.completeWith(context: TestContext.immediate, future: dependentFuture)
        dependentFuture.success(true)

        XCTAssertFutureSucceeds(future, context: TestContext.immediate) { value in
            XCTAssertTrue(value)
        }
    }

    func testCompletesWith_WhenDependentFutureFails_CompletesWithDependantError() {
        let future =  Future<Bool>()
        let dependentFuture = Future<Bool>()

        future.completeWith(context: TestContext.immediate, future: dependentFuture)
        dependentFuture.failure(TestFailure.error)
        
        XCTAssertFutureFails(future, context: TestContext.immediate) { error in
            XCTAssertEqualErrors(error, TestFailure.error)
        }

    }

    func testCompletesWith_WhenDependentFutureStreamSucceeds_CompletesWithDependantValue() {
        let future = Future<Int>()
        let dependentStream = FutureStream<Int>()

        future.completeWith(context: TestContext.immediate, stream: dependentStream)
        dependentStream.success(1)

        XCTAssertFutureSucceeds(future, context: TestContext.immediate) { value in
            XCTAssertEqual(value, 1)
        }
    }

    func testCompletesWith_WhenDependentFutureStreamFails_CompletesWithDependantError() {
        let future = Future<Int>()
        let dependentStream = FutureStream<Int>()

        future.completeWith(context: TestContext.immediate, stream: dependentStream)
        dependentStream.failure(TestFailure.error)

        XCTAssertFutureFails(future, context: TestContext.immediate) { error in
            XCTAssertEqualErrors(error, TestFailure.error)
        }
    }

    // MARK: - map -

    func testMap_WhenFutureAndMapSucceed_MapCalledCompletesSuccessfully() {
        let future = Future<Bool>()
        let mapped = future.map(context: TestContext.immediate) { value -> Int in
            return 1
        }
        future.success(true)
        XCTAssertFutureSucceeds(mapped, context: TestContext.immediate) { value in
            XCTAssertEqual(value, 1)
        }
    }

    func testMap_WhenFutureSucceedsAndMapFails_MapCalledCompletesWithError() {
        let future = Future<Bool>()
        let mapped = future.map(context: TestContext.immediate) { _ -> Int in
            throw TestFailure.error
        }
        future.success(true)
        XCTAssertFutureFails(mapped, context: TestContext.immediate) { error in
            XCTAssertEqualErrors(error, TestFailure.error)
        }
    }

    func testMap_WhenFutureFails_MapNotCalledCompletesWithError() {
        let future = Future<Bool>()
        let mapped = future.map(context: TestContext.immediate) { value -> Int in
            XCTFail()
            return 1
        }
        future.failure(TestFailure.error)
        XCTAssertFutureFails(mapped, context: TestContext.immediate) { error in
            XCTAssertEqualErrors(error, TestFailure.error)
        }
    }

    // MARK: - flatMap -

    func testFlatMap_WhenFutureAndFlatMapSucceed_FlatMapCalledCompletesSuccessfully() {
        let future = Future<Bool>()
        let mapped = future.flatMap(context: TestContext.immediate) {value -> Future<Int> in
            return Future<Int>(value: 1)
        }
        future.success(true)
        XCTAssertFutureSucceeds(mapped, context: TestContext.immediate) { value in
            XCTAssertEqual(value, 1)
        }
    }

    func testFlatMap_WhenFutureSucceedsAndFlatMapFails_FlatMapCalledCompletesWithError() {
        let future = Future<Bool>()
        let mapped = future.flatMap(context: TestContext.immediate) { value -> Future<Int> in
            throw TestFailure.error
        }
        future.success(true)
        XCTAssertFutureFails(mapped, context: TestContext.immediate) { error in
            XCTAssertEqualErrors(error, TestFailure.error)
        }
    }

    func testFlatMap_WhenFutureFailsAndFlatMapReturnsFuture_FlatMapNotCalledCompletesWithError() {
        let future = Future<Bool>()
        let mapped = future.flatMap(context: TestContext.immediate) { value -> Future<Int> in
            XCTFail()
            return Future<Int>(value: 1)
        }
        future.failure(TestFailure.error)
        XCTAssertFutureFails(mapped, context: TestContext.immediate) { error in
            XCTAssertEqualErrors(error, TestFailure.error)
        }
    }

    func testFlatMap_WhenFutureSucceedsAndFlatMapFutureFails_FlatMapCalledCompletesWithError() {
        let future = Future<Bool>()
        let mapped = future.flatMap(context: TestContext.immediate) { value -> Future<Int> in
            return Future<Int>(error: TestFailure.error)
        }
        future.success(true)
        XCTAssertFutureFails(mapped, context: TestContext.immediate) { error in
            XCTAssertEqualErrors(error, TestFailure.error)
        }
    }

    func testFlatMap_WhenFutureSucceedsAndFlatMapReturnsSuccessfulFutureStream_FlatCalledCompletesSuccessfully() {
        let future = Future<Bool>()
        let stream = FutureStream<Int>()
        let mapped = future.flatMap(context: TestContext.immediate) { value -> FutureStream<Int> in
            return stream
        }
        future.success(true)
        stream.success(1)
        XCTAssertFutureStreamSucceeds(mapped, context: TestContext.immediate, validations: [
            { value in
                XCTAssertEqual(value, 1)
            }
        ])
    }

    func testFlatMap_WhenFutureFailsFlatMapReturnsFutureStream_FlatMapNotCalledCompletesWithError() {
        let future = Future<Bool>()
        let stream = FutureStream<Int>()
        let mapped = future.flatMap(context: TestContext.immediate) { value -> FutureStream<Int> in
            XCTFail()
            return stream
        }
        future.failure(TestFailure.error)
        stream.success(1)
        XCTAssertFutureStreamFails(mapped, context: TestContext.immediate, validations: [
            { error in
                XCTAssertEqualErrors(error, TestFailure.error)
            }
        ])
    }

    func testFlatMap_WhenFlatMapFailsReturningFutureStream_FlatMapNotCalledCompletesWithError() {
        let future = Future<Bool>()
        let stream = FutureStream<Int>()
        let mapped = future.flatMap(context: TestContext.immediate) { value -> FutureStream<Int> in
            throw TestFailure.error
        }
        future.failure(TestFailure.error)
        stream.success(1)
        XCTAssertFutureStreamFails(mapped, context: TestContext.immediate, validations: [
            { error in
                XCTAssertEqualErrors(error, TestFailure.error)
            }
        ])
    }

    func testFlatMap_WhenFutureSucceedsAndFlatMapReturnsFailedFutureStream_FlatMapCalledCompletesWithError() {
        let future = Future<Bool>()
        let stream = FutureStream<Int>()
        let mapped = future.flatMap(context: TestContext.immediate) { value -> FutureStream<Int> in
            return stream
        }
        future.success(true)
        stream.failure(TestFailure.error)
        XCTAssertFutureStreamFails(mapped, context: TestContext.immediate, validations: [
            { error in
                XCTAssertEqualErrors(error, TestFailure.error)

            }
        ])
    }

    // MARK: - recover -

    func testRecover_WhenFutureSucceeds_RecoverNotCalledCompletesSuccessfully() {
        let future = Future<Bool>()
        let recovered = future.recover(context: TestContext.immediate) { error -> Bool in
            XCTFail()
            return false
        }
        future.success(true)
        XCTAssertFutureSucceeds(recovered, context: TestContext.immediate) { value in
            XCTAssertTrue(value)
        }
    }

    func testRecover_WhenFutureFailsAndRecoverySucceeds_RecoverCalledCompletesSuccessfully() {
        let future = Future<Bool>()
        let recovered = future.recover(context: TestContext.immediate) { _ -> Bool in
            return true
        }
        future.failure(TestFailure.error)
        XCTAssertFutureSucceeds(recovered, context: TestContext.immediate) { value in
            XCTAssertTrue(value)
        }
    }

    func testRecover_WhenFutureFailsAndRecoveryFails_RecoverCalledCompletesWithError() {
        let future = Future<Bool>()
        let recovered = future.recover(context: TestContext.immediate) { _ -> Bool in
            throw TestFailure.recoveryError
        }
        future.failure(TestFailure.error)
        XCTAssertFutureFails(recovered, context: TestContext.immediate) { error in
            XCTAssertEqualErrors(error, TestFailure.recoveryError)
        }
    }

    // MARK: - recoverWith -

    func testRecoverWith_WhenFutureSucceeds_RecoverWithNotCalledCompletesSuccessfully() {
        let future = Future<Bool>()
        let recovered = future.recoverWith(context: TestContext.immediate) { _ -> Future<Bool> in
            XCTFail()
            return Future<Bool>()
        }
        future.success(true)
        XCTAssertFutureSucceeds(recovered, context: TestContext.immediate) { value in
            XCTAssertTrue(value)
        }
    }

    func testRecoverWith_WhenFutureFailsAndRecoverySucceeds_RecoverWithCalledCompletesSuccessfully() {
        let future = Future<Bool>()
        let recovered = future.recoverWith(context: TestContext.immediate) { error -> Future<Bool> in
            return Future<Bool>(value: true)
        }
        future.failure(TestFailure.error)
        XCTAssertFutureSucceeds(recovered, context: TestContext.immediate) { value in
            XCTAssertTrue(value)
        }
    }

    func testRecoverWith_WhenFutureFailsAndRecoveryFails_RecoverWithCalledCompletesWithError() {
        let future = Future<Bool>()
        let recovered = future.recoverWith(context: TestContext.immediate) { error -> Future<Bool> in
            throw TestFailure.recoveryError
        }
        future.failure(TestFailure.error)
        XCTAssertFutureFails(recovered, context: TestContext.immediate) { error in
            XCTAssertEqualErrors(error, TestFailure.recoveryError)
        }
    }

    func testRecoverWith_WhenFutureSucceedsAndRecoveryReturnsFutureStream_RecoverWithNotCalledCompletesSuccessfully() {
        let future = Future<Bool>()
        let stream = FutureStream<Bool>()
        let recovered = future.recoverWith(context: TestContext.immediate) { error -> FutureStream<Bool> in
            XCTFail()
            return stream
        }
        future.success(true)
        XCTAssertFutureStreamSucceeds(recovered, context: TestContext.immediate, validations: [
            { value in
                XCTAssert(value)
            }
        ])
    }

    func testRecoverWith_WhenFutureFailsAndRecoveryReturnsSuccessfulFutureStream_RecoverWithCalledCompletesSuccessfully() {
        let future = Future<Bool>()
        let stream = FutureStream<Bool>()
        let recovered = future.recoverWith(context: TestContext.immediate) { error -> FutureStream<Bool> in
            return stream
        }
        future.failure(TestFailure.error)
        stream.success(false)
        XCTAssertFutureStreamSucceeds(recovered, context: TestContext.immediate, validations: [
            { value in
                XCTAssertFalse(value)
            }
        ])
    }

    func testRecoverWith_WhenFutureFailsAndRecoveryReturnsFailedFutureStream_RecoverWithCalledCompletesWithError() {
        let future = Future<Bool>()
        let stream = FutureStream<Bool>()
        let recovered = future.recoverWith(context: TestContext.immediate) { error -> FutureStream<Bool> in
            return stream
        }
        future.failure(TestFailure.error)
        stream.failure(TestFailure.recoveryError)
        XCTAssertFutureStreamFails(recovered, context: TestContext.immediate, validations: [
            { error in
                XCTAssertEqualErrors(error, TestFailure.recoveryError)
            }
        ])
    }

    func testRecoverWith_WhenFutureFailsAndFutureStreamRecoveryFails_RecoverWithCalledCompletesWithError() {
        let future = Future<Bool>()
        let recovered = future.recoverWith(context: TestContext.immediate) { error -> FutureStream<Bool> in
            throw TestFailure.recoveryError
        }
        future.failure(TestFailure.error)
        XCTAssertFutureStreamFails(recovered, context: TestContext.immediate, validations: [
            { error in
                XCTAssertEqualErrors(error, TestFailure.recoveryError)
            }
        ])
    }

    // MARK: - withFilter -

    func testWithFilter_WhenFutureAndFilterSucceed_WithFilterCalledCompletesSuccessfully() {
        let future = Future<Int>()
        let filtered = future.withFilter(context: TestContext.immediate) { value -> Bool in
            return value < 1
        }
        future.success(0)
        XCTAssertFutureSucceeds(filtered, context: TestContext.immediate) { value in
            XCTAssertEqual(0, value)
        }
    }

    func testWithFilter_WhenFutureSuccedsAndFilterFails_WithFilterCalledCompletesWithNoSuchElementError() {
        let future = Future<Int>()
        let filtered = future.withFilter(context: TestContext.immediate) { value -> Bool in
            return value < 1
        }
        future.success(1)
        XCTAssertFutureFails(filtered, context: TestContext.immediate) { error in
            XCTAssertEqualErrors(error, FuturesError.noSuchElement)
        }
    }

    func testWithFilter_WhenFutureFails_WithFilterNotCalledCompletesWithError() {
        let future = Future<Int>()
        let filtered = future.withFilter(context: TestContext.immediate) { value -> Bool in
            XCTFail()
            return value < 1
        }
        future.failure(TestFailure.error)
        XCTAssertFutureFails(filtered, context: TestContext.immediate) { error in
            XCTAssertEqualErrors(error, TestFailure.error)
        }
    }

    func testWithFilter_WhenFutureSucceedsAndFilterThrows_WithFilterCalledCompletesWithError() {
        let future = Future<Int>()
        let filtered = future.withFilter(context: TestContext.immediate) { value -> Bool in
            throw TestFailure.error
        }
        future.failure(TestFailure.error)
        XCTAssertFutureFails(filtered, context: TestContext.immediate) { error in
            XCTAssertEqualErrors(error, TestFailure.error)
        }
    }

    // MARK: - forEach -

    func testForEach_WhenFutureSucceeds_ForEachCalled() {
        let future = Future<Bool>()
        var forEachCalled = false
        future.forEach(context: TestContext.immediate) { value in
            forEachCalled = true
            XCTAssertTrue(value)
        }
        future.success(true)
        XCTAssertTrue(forEachCalled)
        XCTAssertFutureSucceeds(future, context: TestContext.immediate) { value in
            XCTAssertTrue(value)
        }
    }

    func testForEach_WhenFutureFails_ForEachNotCalled() {
        let future = Future<Bool>()
        future.forEach(context: TestContext.immediate) { _ in
            XCTFail()
        }
        future.failure(TestFailure.error)
        XCTAssertFutureFails(future, context: TestContext.immediate) { error in
            XCTAssertEqualErrors(error, TestFailure.error)
        }
    }

    // MARK: - andThen -

    func testAndThen_WhenFutureSucceeds_AndThenCalledCompletesdSuccessfully() {
        let future = Future<Bool>()
        var andThenCalled = false
        let andThen = future.andThen(context: TestContext.immediate) { _ in
            andThenCalled = true
        }
        future.success(true)
        XCTAssertFutureSucceeds(andThen, context: TestContext.immediate) { value in
            XCTAssert(value, "andThen onSuccess value invalid")
            XCTAssertTrue(andThenCalled)
        }
    }

    func testAndThen_WhenFutureFails_AndThenNotCalledCompletesWithError() {
        let future = Future<Bool>()
        let andThen = future.andThen(context: TestContext.immediate) { _ in
            XCTFail()
        }
        future.failure(TestFailure.error)
        XCTAssertFutureFails(andThen, context: TestContext.immediate) { error in
            XCTAssertEqualErrors(error, TestFailure.error)
        }
    }

    // MARK: - mapError -

    func testMapError_WhenFutureSucceeds_MapErrorNotCalledCompletesSuccessfully() {
        let future = Future(value: 1)
        let mapError = future.mapError(context: TestContext.immediate) { _ in
            XCTFail()
            return TestFailure.mappedError
        }
        XCTAssertFutureSucceeds(mapError, context: TestContext.immediate) { value in
            XCTAssertEqual(value, 1)
        }
    }

    func testMapError_WhenFutureFails_MapErrorCalledCompletesWithMappedError() {
        let future = Future<Int>(error: TestFailure.error)
        let mapError = future.mapError(context: TestContext.immediate) { _ in
            return TestFailure.mappedError
        }
        XCTAssertFutureFails(mapError, context: TestContext.immediate) { error in
            XCTAssertEqualErrors(error, TestFailure.mappedError)
        }
    }

    // MARK: - cancel -

    func testCancel_ForOnSuccess_CancelSucceeedsAndDoesNotComplete() {
        let future = Future<Int>()
        let cancelToken = CancelToken()
        future.onSuccess(context: TestContext.immediate, cancelToken: cancelToken) { _ in
            XCTFail()
        }
        let status = future.cancel(cancelToken)
        future.success(1)
        XCTAssertTrue(status)
    }

    func testCancel_ForOnSuccessWhenFutureCompleted_CancelFails() {
        let future = Future<Int>()
        let cancelToken = CancelToken()
        var onSuccessCalled = false
        future.onSuccess(context: TestContext.immediate) { _ in
            onSuccessCalled = true
        }
        future.success(1)
        let status = future.cancel(cancelToken)
        XCTAssertFalse(status)
        XCTAssertTrue(onSuccessCalled)
    }

    func testCancel_ForOnSuccessWithInvalidCancelToken_CancelFails() {
        let future = Future<Int>()
        let cancelToken = CancelToken()
        var onSuccessCalled = false
        future.onSuccess(context: TestContext.immediate) { _ in
            onSuccessCalled = true
        }
        let status = future.cancel(cancelToken)
        future.success(1)
        XCTAssertFalse(status)
        XCTAssertTrue(onSuccessCalled)
    }

    func testCancel_ForOnFailure_DoesNotComplete() {
        let future = Future<Int>()
        let cancelToken = CancelToken()
        future.onFailure(context: TestContext.immediate, cancelToken: cancelToken) { _ in
            XCTFail()
        }
        let status = future.cancel(cancelToken)
        future.failure(TestFailure.error)
        XCTAssertTrue(status)
    }

    func testCancel_ForMap_DoesNotComplete() {
        let future = Future<Int>()
        let cancelToken = CancelToken()
        let mapped = future.map(context: TestContext.immediate, cancelToken: cancelToken) { _ -> Bool in
            XCTFail()
            return true
        }
        mapped.onSuccess(context: TestContext.immediate) { _ in
            XCTFail()
        }
        let status = future.cancel(cancelToken)
        future.success(1)
        XCTAssertTrue(status)
    }

    func testCancel_MultipleCancelations_CancelSucceeedsAndDoesNotComplete() {
        let future = Future<Int>()
        let cancelToken = CancelToken()
        future.onSuccess(context: TestContext.immediate, cancelToken: cancelToken) { _ in
            XCTFail()
        }
        let mapped = future.map(context: TestContext.immediate, cancelToken: cancelToken) { _ -> Bool in
            XCTFail()
            return true
        }
        mapped.onSuccess(context: TestContext.immediate) { _ in
            XCTFail()
        }
        let status = future.cancel(cancelToken)
        future.success(1)
        XCTAssertTrue(status)
    }

    func testCancel_ForFlatMapRetuningFuture_DoesNotComplete() {
        let future = Future<Int>()
        let cancelToken = CancelToken()
        let flatMapped = future.flatMap(context: TestContext.immediate, cancelToken: cancelToken) { _ -> Future<Bool> in
            XCTFail()
            return Future(value: true)
        }
        flatMapped.onSuccess(context: TestContext.immediate) { _ in
            XCTFail()
        }
        let status = future.cancel(cancelToken)
        future.success(1)
        XCTAssertTrue(status)
    }

    func testCancel_ForFlatMapReturningFutureStream_DoesNotComplete() {
        let future = Future<Int>()
        let stream = FutureStream<Bool>()
        let cancelToken = CancelToken()
        let flatMapped = future.flatMap(context: TestContext.immediate, cancelToken: cancelToken) { value -> FutureStream<Bool> in
            XCTFail()
            return stream
        }
        flatMapped.onSuccess(context: TestContext.immediate) { _ in
            XCTFail()
        }
        let status = future.cancel(cancelToken)
        future.success(1)
        XCTAssertTrue(status)
    }

    func testCancel_ForAndThen_DoesNotComplete() {
        let future = Future<Int>()
        let cancelToken = CancelToken()
        let andThen = future.andThen(context: TestContext.immediate, cancelToken: cancelToken) { _ in
            XCTFail()
        }
        andThen.onSuccess(context: TestContext.immediate) { _ in
            XCTFail()
        }
        let status = future.cancel(cancelToken)
        future.success(1)
        XCTAssertTrue(status)
    }

    func testCancel_ForRecover_DoesNotComplete() {
        let future = Future<Int>()
        let cancelToken = CancelToken()
        let recovered = future.recover(context: TestContext.immediate, cancelToken: cancelToken) { _ in
            XCTFail()
            return 2
        }
        recovered.onSuccess(context: TestContext.immediate) { _ in
            XCTFail()
        }
        let status = future.cancel(cancelToken)
        future.success(1)
        XCTAssertTrue(status)
    }

    func testCancel_ForRecoverWithReturningFuture_DoesNotComplete() {
        let future = Future<Int>()
        let cancelToken = CancelToken()
        let recovered = future.recoverWith(context: TestContext.immediate, cancelToken: cancelToken) { _ -> Future<Int> in
            XCTFail()
            return Future(value: 2)
        }
        recovered.onSuccess(context: TestContext.immediate) { _ in
            XCTFail()
        }
        let status = future.cancel(cancelToken)
        future.success(1)
        XCTAssertTrue(status)
    }

    func testCancel_ForRecoverWithReturningFutureStream_DoesNotComplete() {
        let future = Future<Int>()
        let stream = FutureStream<Int>()
        let cancelToken = CancelToken()
        let recovered = future.recoverWith(context: TestContext.immediate, cancelToken: cancelToken) { _ -> FutureStream<Int> in
            XCTFail()
            return stream
        }
        recovered.onSuccess(context: TestContext.immediate) { _ in
            XCTFail()
        }
        let status = future.cancel(cancelToken)
        future.success(1)
        XCTAssertTrue(status)
    }

    func testCancel_ForWithFilter_DoesNotComplete() {
        let future = Future<Int>()
        let cancelToken = CancelToken()
        let filtered = future.withFilter(context: TestContext.immediate, cancelToken: cancelToken) { _ in
            XCTFail()
            return true
        }
        filtered.onSuccess(context: TestContext.immediate) { _ in
            XCTFail()
        }
        let status = future.cancel(cancelToken)
        future.success(1)
        XCTAssertTrue(status)
    }

    func testCancel_ForForEach_DoesNotComplete() {
        let future = Future<Int>()
        let cancelToken = CancelToken()
        future.forEach(context: TestContext.immediate, cancelToken: cancelToken) { _ in
            XCTFail()
        }
        let status = future.cancel(cancelToken)
        future.success(1)
        XCTAssertTrue(status)
    }

    func testCancel_ForMapError_DoesNotComplete() {
        let future = Future<Int>()
        let cancelToken = CancelToken()
        let mappedError = future.mapError(context: TestContext.immediate, cancelToken: cancelToken) { _ in
            XCTFail()
            return TestFailure.mappedError
        }
        mappedError.onFailure(context: TestContext.immediate)  { _ in
            XCTFail()
        }
        let status = future.cancel(cancelToken)
        future.failure(TestFailure.error)
        XCTAssertTrue(status)
    }

    // MARK: - future -

    func testFuture_WhenClosureSucceeds_CompletesSuccessfully() {
        let result = future(context: TestContext.immediate) {
            return 1
        }
        XCTAssertFutureSucceeds(result, context: TestContext.immediate) { value in
            XCTAssertEqual(value, 1)
        }
    }

    func testFuture_WhenClosureFails_CompletesWithError() {
        let result = future(context: TestContext.immediate) { () -> Int in
            throw TestFailure.error
        }
        XCTAssertFutureFails(result, context: TestContext.immediate) { error in
            XCTAssertEqualErrors(TestFailure.error, error)
        }
    }

    func testFuture_WithAutoclosure_CompletesSuccessfully() {
        let result = future(1 < 2)
        XCTAssertFutureSucceeds(result, context: TestContext.immediate) { value in
            XCTAssertTrue(value)
        }
    }

    func testFuture_WithValueErrorCallbackCompletedWithValidValue_CompletesSuccessfully() {
        func testMethod(_ completion: (Int?, Swift.Error?) -> Void) {
            completion(1, nil)
        }
        let result = future(method: testMethod)
        XCTAssertFutureSucceeds(result, context: TestContext.immediate) { value in
            XCTAssertEqual(value, 1)
        }
    }

    func testFuture_WithValueErrorCallbackCompletedWithInvalidValue_CompletesWithInvalidValueError() {
        func testMethod(_ completion: (Int?, Swift.Error?) -> Void) {
            completion(nil, nil)
        }
        let result = future(method: testMethod)
        XCTAssertFutureFails(result, context: TestContext.immediate) { error in
            XCTAssertEqualErrors(error, FuturesError.invalidValue)
        }
    }

    func testFuture_WithValueErrorCallbackCompletedWithWrror_CompletesWithError() {
        func testMethod(_ completion: (Int?, Swift.Error?) -> Void) {
            completion(nil, TestFailure.error)
        }
        let result = future(method: testMethod)
        XCTAssertFutureFails(result, context: TestContext.immediate) { error in
            XCTAssertEqualErrors(error, TestFailure.error)
        }
    }

    func testFuture_WithErrorCallbackCompletedWithNoError_CompletesSuccessfully() {
        func testMethod(_ completion: (Swift.Error?) -> Void) {
            completion(nil)
        }
        let result = future(method: testMethod)
        XCTAssertFutureSucceeds(result, context: TestContext.immediate)
    }

    func testFuture_WithErrorCallbackCompletedWithWrror_CompletesWithError() {
        func testMethod(_ completion: (Swift.Error?) -> Void) {
            completion(TestFailure.error)
        }
        let result = future(method: testMethod)
        XCTAssertFutureFails(result, context: TestContext.immediate) { error in
            XCTAssertEqualErrors(error, TestFailure.error)
        }
    }

    func testFuture_WithValueCallbackCompletedWithValidValue_CompletesSuccessfully() {
        func testMethod(_ completion: (Int) -> Void) {
            completion(1)
        }
        let result = future(method: testMethod)
        XCTAssertFutureSucceeds(result, context: TestContext.immediate) { value in
            XCTAssertEqual(value, 1)
        }
    }

    // MARK: - fold -

    func testFold_WhenFuturesSucceed_CompletesSuccessfully() {
        let futures = [future(Int(1)), future(Int(2)), future(Int(3))]
        let result = futures.fold(context: TestContext.immediate, initial: 0) { $0 + $1 }
        XCTAssertFutureSucceeds(result, context: TestContext.immediate) { value in
            XCTAssertEqual(value, 6)
        }
    }

    func testFold_WhenFutureFails_CompletesWithError() {
        let futures = [future(Int(1)),
                       future(context: TestContext.immediate) { () -> Int in throw TestFailure.error },
                       future(Int(2))]
        let result = futures.fold(context: TestContext.immediate, initial: 0) { $0 + $1 }
        XCTAssertFutureFails(result, context: TestContext.immediate) { error in
            XCTAssertEqualErrors(error, TestFailure.error)
        }
    }


    // MARK: - sequence -

    func testSequence_WhenFuturesSucceed_CompletesSuccessfully() {
        let futures = [future(Int(1)), future(Int(2)), future(Int(3))]
        let result = futures.sequence(context: TestContext.immediate)
        XCTAssertFutureSucceeds(result, context: TestContext.immediate) { value in
            XCTAssertEqual(value, [1, 2, 3])
        }
    }

    func testSequence_WhenFutureFails_CompletesWithError() {
        let futures = [future(Int(1)),
                       future(context: TestContext.immediate) { () -> Int in throw TestFailure.error },
                       future(Int(2))]
        let result = futures.sequence(context: TestContext.immediate)
        XCTAssertFutureFails(result, context: TestContext.immediate) { error in
            XCTAssertEqualErrors(error, TestFailure.error)
        }
    }

    // MARK: - Promise -

    func testPromiseSuccess_WhenCompleted_CompeletesSuccessfully() {
        let promise = Promise<Bool>()
        promise.success(false)
        XCTAssertFutureSucceeds(promise.future, context: TestContext.immediate) { value in
            XCTAssertFalse(value)
        }
    }

    func testPromiseFailure_WhenCompleted_CompeletesWithError() {
        let promise = Promise<Bool>()
        promise.failure(TestFailure.error)
        XCTAssertFutureFails(promise.future, context: TestContext.immediate) { error in
            XCTAssertEqualErrors(error, TestFailure.error)
        }
    }

}
