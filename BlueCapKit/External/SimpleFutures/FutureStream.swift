//
//  Stream.swift
//  BlueCapKit
//
//  Created by Troy Stribling on 12/7/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation

public class StreamPromise<T> {

    let futureStream    = FutureStream<T>()
    
    public init() {
    }
    
    public func succes(value:T) {
        let promise = Promise<T>()
        promise.success(value)
        self.completeWith(promise.future)
    }
    
    public func failure(error:NSError) {
        let promise = Promise<T>()
        promise.failure(error)
        self.completeWith(promise.future)
    }
    
    public func completeWith(future:Future<T>) {
        self.futureStream.completeWith(future)
    }
    

}

public class FutureStream<T> {
    
    private var futures         = [Future<T>]()
    private typealias InFuture  = Future<T> -> Void
    private var saveCompletes   = [InFuture]()
    
    public func onComplete(complete:Try<T> -> Void) {
        self.onComplete(QueueContext.main, complete)
    }
    
    public func onComplete(executionContext:ExecutionContext, complete:Try<T> -> Void) {
        let futureComplete : InFuture = {future in
            future.onComplete(executionContext, complete)
        }
        Queue.simpleFutureStreams.sync {
            self.saveCompletes.append(futureComplete)
            for future in self.futures {
                futureComplete(future)
            }
        }
    }

    public func onSuccesss(success:T -> Void) {
        self.onSuccesss(QueueContext.main, success:success)
    }

    public func onSuccesss(executionContext:ExecutionContext, success:T -> Void) {
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
        self.onFailure(QueueContext.main, failure:failure)
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
    
    public func map<M>(mapping:T -> M) -> Future<M> {
        return self.map(QueueContext.main, mapping)
    }
    
    public func map<M>(executionContext:ExecutionContext, mapping:T -> M) -> Future<M> {
        let promise = Promise<M>()
        return promise.future
    }
    
    public func flatMap<M>(mapping:T -> Future<M>) -> Future<M> {
        return self.flatMap(QueueContext.main, mapping)
    }

    public func flatMap<M>(executionContext:ExecutionContext, mapping:T -> Future<M>) -> Future<M> {
        let promise = Promise<M>()
        return promise.future
    }
    
    internal init() {
    }
    
    internal func completeWith(future:Future<T>) {
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