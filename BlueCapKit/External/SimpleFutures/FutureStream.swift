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
    
    public func write(future:Future<T>) {
        self.futureStream.write(future)
    }
}

public class FutureStream<T> {
    
    internal typealias OnComplete   = Try<T> -> Void
    internal typealias OnSuccess    = T -> Void
    internal typealias OnWrite      = Void -> Void
    public   typealias OnFailure    = NSError -> Void
    
    private var futures     = [Future<T>]()
    private var onWrites    = [OnWrite]()
    
    public func onComplete(complete:OnComplete) {
        self.onComplete(QueueContext.main, complete)
    }
    
    public func onComplete(executionContext:ExecutionContext, complete:OnComplete) {
    }

    public func onSuccesss(success:OnSuccess) {
    }

    public func onSuccesss(executionContext:ExecutionContext, success:OnSuccess) {
    }
    
    public func onFailure(failure:OnFailure) {
    }

    public func onFailure(executionContext:ExecutionContext, failure:OnFailure) {
    }
    
    internal init() {
    }
    
    internal func write(future:Future<T>) {
        if future.isCompleted == false {
            future.failure(NSError(domain:SimpleFuturesError.domain,
                code:SimpleFuturesError.FutureNotCompleted.code,
                userInfo:[NSLocalizedDescriptionKey:SimpleFuturesError.FutureNotCompleted.description]))
        }
        Queue.simplefutures.sync {
            self.futures.append(future)
        }
    }
    
    private onWrite() {
    }
    
}