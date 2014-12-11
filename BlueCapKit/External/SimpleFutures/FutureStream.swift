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
        self.write(promise.future)
    }
    
    public func failure(error:NSError) {
        let promise = Promise<T>()
        promise.failure(error)
        self.write(promise.future)
    }
    
    public func write(future:Future<T>) {
        self.futureStream.write(future)
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
    
//    public func map<M>(executionContext:ExecutionContext, mapping:T -> M) -> Future<M> {
//    }
//    
//    public func flatMap<M>(executionContext:ExecutionContext, mapping:T -> Future<M>) -> Future<M> {
//        
//    }
    
    internal init() {
    }
    
    internal func write(future:Future<T>) {
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