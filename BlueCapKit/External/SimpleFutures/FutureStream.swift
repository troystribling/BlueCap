//
//  Stream.swift
//  BlueCapKit
//
//  Created by Troy Stribling on 12/7/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation

public class StreamPromise<T> {

    public let future = FutureStream<T>()
    
    public init() {
    }
    
    public func success(value:T) {
        let promise = Promise<T>()
        promise.success(value)
        self.write(promise.future)
    }
    
    public func failure(error:NSError) {
        let promise = Promise<T>()
        promise.failure(error)
        self.write(promise.future)
    }
    
    public func complete(result:Try<T>) {
        let promise = Promise<T>()
        promise.complete(result)
        self.write(promise.future)
    }
    
    public func completeWith(future:Future<T>) {
        self.completeWith(self.future.defaultExecutionContext, future:future)
    }
    
    public func completeWith(executionContext:ExecutionContext, future:Future<T>) {
        future.onComplete(executionContext) {result in
            self.complete(result)
        }
    }
    
    public func write(future:Future<T>) {
        self.future.write(future)
    }
    

}

public class FutureStream<T> {
    
    private var futures                                     = [Future<T>]()
    private typealias InFuture                              = Future<T> -> Void
    private var saveCompletes                               = [InFuture]()
    
    internal let defaultExecutionContext: ExecutionContext  = QueueContext.main

    public func onComplete(complete:Try<T> -> Void) {
        self.onComplete(self.defaultExecutionContext, complete)
    }
    
    public func onComplete(executionContext:ExecutionContext, complete:Try<T> -> Void) {
        Queue.simpleFutureStreams.sync {
            let futureComplete : InFuture = {future in
                future.onComplete(executionContext, complete)
            }
            self.saveCompletes.append(futureComplete)
            for future in self.futures {
                futureComplete(future)
            }
        }
    }

    public func onSuccess(success:T -> Void) {
        self.onSuccess(self.defaultExecutionContext, success:success)
    }

    public func onSuccess(executionContext:ExecutionContext, success:T -> Void) {
        self.onComplete(executionContext) {result in
            switch result {
            case .Success(let resultWrapper):
                success(resultWrapper.value)
            default:
                break
            }
        }
    }
    
    public func onFailure(failure:NSError -> Void) {
        self.onFailure(self.defaultExecutionContext, failure:failure)
    }

    public func onFailure(executionContext:ExecutionContext, failure:NSError -> Void) {
        self.onComplete(executionContext) {result in
            switch result {
            case .Failure(let error):
                failure(error)
            default:
                break
            }
        }
    }
    
    public func map<M>(mapping:T -> Try<M>) -> FutureStream<M> {
        return self.map(self.defaultExecutionContext, mapping)
    }
    
    public func map<M>(executionContext:ExecutionContext, mapping:T -> Try<M>) -> FutureStream<M> {
        let promise = StreamPromise<M>()
        self.onComplete(executionContext) {result in
            switch result {
            case .Success(let resultWrapper):
                promise.complete(mapping(resultWrapper.value))
            case .Failure(let error):
                promise.failure(error)
            }
        }
        return promise.future
    }
    
    public func flatmap<M>(mapping:T -> Future<M>) -> FutureStream<M> {
        return self.flatMap(self.defaultExecutionContext, mapping)
    }

    public func flatMap<M>(executionContext:ExecutionContext, mapping:T -> Future<M>) -> FutureStream<M> {
        let promise = StreamPromise<M>()
        self.onComplete(executionContext) {result in
            switch result {
            case .Success(let resultWrapper):
                promise.completeWith(executionContext, future:mapping(resultWrapper.value))
            case .Failure(let error):
                promise.failure(error)
            }
        }
        return promise.future
    }
    
    public func recover(recovery:NSError -> Try<T>) -> FutureStream<T> {
        return self.recover(self.defaultExecutionContext, recovery:recovery)
    }
    
    public func recover(executionContext:ExecutionContext, recovery:NSError -> Try<T>) -> FutureStream<T> {
        let promise = StreamPromise<T>()
        self.onComplete(executionContext) {result in
            switch result {
            case .Success(let resultWrapper):
                promise.success(resultWrapper.value)
            case .Failure(let error):
                promise.complete(recovery(error))
            }
        }
        return promise.future
    }
    
    public func andThen(complete:Try<T> -> Void) -> FutureStream<T> {
        return self.andThen(self.defaultExecutionContext, complete:complete)
    }
    
    public func andThen(executionContext:ExecutionContext, complete:Try<T> -> Void) -> FutureStream<T> {
        let promise = StreamPromise<T>()
        promise.future.onComplete(executionContext, complete:complete)
        self.onComplete(executionContext) {result in
            promise.complete(result)
        }
        return promise.future
    }
    
    public init() {
    }
    
    public func write(future:Future<T>) {
        if future.isCompleted == false {
            future.failure(NSError(domain:SimpleFuturesError.domain,
                code:SimpleFuturesError.FutureNotCompleted.code,
                userInfo:[NSLocalizedDescriptionKey:SimpleFuturesError.FutureNotCompleted.description]))
        }
        Queue.simpleFutureStreams.sync {
            self.futures.append(future)
            for complete in self.saveCompletes {
                complete(future)
            }
        }
    }
    
}