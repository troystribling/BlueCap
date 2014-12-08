//
//  Stream.swift
//  BlueCapKit
//
//  Created by Troy Stribling on 12/7/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation

public class PromiseStream<T> {

    let streamFuture = FutureStream<T>()
}

public class FutureStream<T> {
    
    internal typealias OnComplete   = Try<T> -> Void
    internal typealias OnSuccess    = T -> Void
    public typealias   OnFailure    = NSError -> Void

    private var futures = [Future<T>]()
    
    public func onComplete(complete:OnComplete) {
        
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
    
    internal func appendFuture(future:Future<T>) {
        Queue.simplefutures.sync {
            self.futures.append(future)
        }
    }
    
}