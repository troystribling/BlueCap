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
    }
    
    public func failure(error:NSError) {
    }
    
    internal func write(future:Future<T>) {
        self.futureStream.write(future)
    }
    

}

public class FutureStream<T> {
    
    private typealias InFuture     = Future<T> -> Void
    public  typealias OnComplete   = Try<T> -> Void
    public  typealias OnSuccess    = T -> Void
    public  typealias OnFailure    = NSError -> Void
    
    private var futures         = [Future<T>]()
    private var saveCompletes   = [InFuture]()
    
    public func onComplete(complete:OnComplete) {
        self.onComplete(QueueContext.main, complete)
    }
    
    public func onComplete(executionContext:ExecutionContext, complete:OnComplete) {
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

    public func onSuccesss(success:OnSuccess) {
        self.onSuccesss(QueueContext.main, success:success)
    }

    public func onSuccesss(executionContext:ExecutionContext, success:OnSuccess) {
        self.onComplete(executionContext) {result in
            switch result {
            case .Success(let resultWrapper):
                success(resultWrapper.value)
            default:
                break
            }
        }
    }
    
    public func onFailure(failure:OnFailure) {
        self.onFailure(QueueContext.main, failure:failure)
    }

    public func onFailure(executionContext:ExecutionContext, failure:OnFailure) {
        self.onComplete(executionContext) {result in
            switch result {
            case .Failure(let error):
                failure(error)
            default:
                break
            }
        }
    }
    
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