//
//  Future.swift
//  SimpleFutures
//
//  Created by Troy Stribling on 7/5/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation

public final class TryWrapper<T> {
    public let value: T
    
    init(_ value: T) {
        self.value = value
    }
}

public enum Try<T> {
    case Success(TryWrapper<T>)
    case Failure(NSError)
    
    init(_ value: T) {
        self = .Success(TryWrapper(value))
    }
    
    init(_ error: NSError) {
        self = .Failure(error)
    }
    
    public func failed(failure:(NSError -> Void)? = nil) -> Bool {
        switch self {
            
        case .Success(_):
            return false
            
        case .Failure(let error):
            if let failure = failure {
                failure(error)
            }
            return true
        }
    }
    
    public func succeeded(success:(T -> Void)? = nil) -> Bool {
        switch self {
        case .Success(let result):
            if let success = success {
                success(result.value)
            }
            return true
        case .Failure(let err):
            return false
        }
    }
    
    public func handle(success:(T -> Void)? = nil, failure:(NSError -> Void)? = nil) {
        switch self {
        case .Success(let val):
            if let success = success {
                success(val.value)
            }
        case .Failure(let err):
            if let failure = failure {
                failure(err)
            }
        }
    }
}


public class Future<T> {
    
    typealias           CompletionFuture    = Future<T> -> Void
    typealias           Completion          = Try<T> -> Void
    typealias           Success             = T -> Void
    public typealias    Failure             = NSError -> Void
    
    var result:Try<T>?

    let internalQueue       = Queue("us.gnos.simplefutures")
    var completionFutures   = [CompletionFuture]()
    var executionContext    = QueueContext.main
    
    public func succeeded(success:(T -> Void)? = nil) -> Bool {
        if let result = self.result {
            return result.succeeded(success)
        } else {
            return false
        }
    }
    
    public func failed(failed:(NSError -> Void)? = nil) -> Bool {
        if let result = self.result {
            return result.failed(failed)
        }
        return false
    }
    
    public func completed(success:(T -> Void)? = nil, failure:(NSError -> Void)? = nil) -> Bool{
        if let res = self.result {
            res.handle(success: success, failure: failure)
            return true
        }
        return false
    }
    
    internal init() {
    }
    
    func complete(result:Try<T>) {
        let succeeded = tryComplete(result)
        assert(succeeded)
    }
    
    func tryComplete(result:Try<T>) -> Bool {
        switch result {
        case .Success(let success):
            return self.trySuccess(success.value)
        case .Failure(let error):
            return self.tryError(error)
        }
    }
    
    func success(value:T) {
        let succeeded = self.trySuccess(value)
        assert(succeeded)
    }
    
    func trySuccess(value:T) -> Bool {
        return self.internalQueue.sync {
            if self.result != nil {
                return false;
            }
            self.result = Try(value)
            self.runCallbacks()
            return true;
        };
    }
    
    func error(error: NSError) {
        let succeeded = self.tryError(error)
        assert(succeeded)
    }
    
    func tryError(error: NSError) -> Bool {
        return self.internalQueue.sync {
            if self.result != nil {
                return false;
            }
            self.result = Try(error)
            self.runCallbacks()
            return true;
        };
    }

    public func onComplete(callback:Completion) -> Future<T> {
        return self.onComplete(self.executionContext, callback:callback)
    }
    
    public func onComplete(context:ExecutionContext, callback:Completion) -> Future<T> {
        self.executionContext = context
        q.sync {
            let wrappedCallback : Future<T> -> () = { future in
                if let realRes = self.result {
                    c.execute {
                        callback(result: realRes)
                    }
                }
            }
            
            if self.result == nil {
                self.callbacks.append(wrappedCallback)
            } else {
                wrappedCallback(self)
            }
        }
        
        return self
    }

    public func onSuccess(callback: SuccessCallback) -> Future<T> {
        return self.onSuccess(context: self.callbackExecutionContext, callback)
    }
    
    public func onSuccess(context c: ExecutionContext, callback: SuccessCallback) -> Future<T> {
        self.onComplete(context: c) { result in
            switch result {
            case .Success(let val):
                callback(val.value)
            default:
                break
            }
        }
        
        return self
    }
    
    public func onFailure(callback: FailureCallback) -> Future<T> {
        return self.onFailure(context: self.callbackExecutionContext, callback)
    }
    
    public func onFailure(context c: ExecutionContext, callback: FailureCallback) -> Future<T> {
        self.onComplete(context: c) { result in
            switch result {
            case .Failure(let err):
                callback(err)
            default:
                break
            }
        }
        return self
    }
    
    public func recover(task: (NSError) -> T) -> Future<T> {
        return self.recover(context: self.callbackExecutionContext, task)
    }
    
    public func recover(context c: ExecutionContext, task: (NSError) -> T) -> Future<T> {
        return self.recoverWith(context: c) { error -> Future<T> in
            return Future.succeeded(task(error))
        }
    }
    
    public func recoverWith(task: (NSError) -> Future<T>) -> Future<T> {
        return self.recoverWith(context: self.callbackExecutionContext, task: task)
    }
    
    public func recoverWith(context c: ExecutionContext, task: (NSError) -> Future<T>) -> Future<T> {
        let p = Promise<T>()
        
        self.onComplete(context: c) { result -> () in
            switch result {
            case .Failure(let err):
                p.completeWith(task(err))
            case .Success(let val):
                p.completeWith(self)
            }
        }
        
        return p.future;
    }
        
    private func runCallbacks() {
        self.callbackExecutionContext.execute {
            for callback in self.callbacks {
                callback(future: self)
            }
            
            self.callbacks.removeAll()
        }
    }
}
