//
//  Future.swift
//  SimpleFutures
//
//  Created by Troy Stribling on 7/5/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation

public final class ResultWrapper<T> {
    public let value: T
    
    init(_ value: T) {
        self.value = value
    }
}

public enum Result<T> {
    case Success(ResultWrapper<T>)
    case Failure(NSError)
    
    init(_ value: T) {
        self = .Success(ResultWrapper(value))
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
    
    public func handle(success:(T->Void)? = nil, failure:(NSError->Void)? = nil) {
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
    
    typealias FutureCallback            = Future<T> -> Void
    typealias CompletionCallback        = Result<T> -> Void
    typealias SuccessCallback           = T -> Void
    public typealias FailureCallback    = NSError -> Void
    
    let internalQueue = Queue("us.gnos.simplefutures")
    
    var result: Result<T>? = nil
    
    var futureCallbacks = [FutureCallback]()
    
    public func succeeded(fn: (T -> ())? = nil) -> Bool {
        if let res = self.result {
            return res.succeeded(fn)
        }
        return false
    }
    
    public func failed(fn: (NSError -> ())? = nil) -> Bool {
        if let res = self.result {
            return res.failed(fn)
        }
        return false
    }
    
    public func completed(success: (T->())? = nil, failure: (NSError->())? = nil) -> Bool{
        if let res = self.result {
            res.handle(success: success, failure: failure)
            return true
        }
        return false
    }
    
    public class func succeeded(value: T) -> Future<T> {
        let res = Future<T>();
        res.result = Result(value)
        
        return res
    }
    
    public class func failed(error: NSError) -> Future<T> {
        let res = Future<T>();
        res.result = Result(error)
        
        return res
    }
    
    public class func completeAfter(delay: NSTimeInterval, withValue value: T) -> Future<T> {
        let res = Future<T>()
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(delay * NSTimeInterval(NSEC_PER_SEC))), Queue.global.queue) {
            res.success(value)
        }
        
        return res
    }
    
    internal init() {
    }
    
    /**
     * Returns a Future that will never succeed
     */
    public class func never() -> Future<T> {
        return Future<T>()
    }
    
    func complete(result: Result<T>) {
        let succeeded = tryComplete(result)
        assert(succeeded)
    }
    
    func tryComplete(result: Result<T>) -> Bool {
        switch result {
        case .Success(let val):
            return self.trySuccess(val.value)
        case .Failure(let err):
            return self.tryError(err)
        }
    }
    
    func success(value: T) {
        let succeeded = self.trySuccess(value)
        assert(succeeded)
    }
    
    func trySuccess(value: T) -> Bool {
        return q.sync {
            if self.result != nil {
                return false;
            }
            
            self.result = Result(value)
            self.runCallbacks()
            return true;
        };
    }
    
    func error(error: NSError) {
        let succeeded = self.tryError(error)
        assert(succeeded)
    }
    
    func tryError(error: NSError) -> Bool {
        return q.sync {
            if self.result != nil {
                return false;
            }
            
            self.result = Result(error)
            self.runCallbacks()
            return true;
        };
    }

    public func onComplete(callback: CompletionCallback) -> Future<T> {
        return self.onComplete(context: self.callbackExecutionContext, callback: callback)
    }
    
    public func onComplete(context c: ExecutionContext, callback: CompletionCallback) -> Future<T> {
        self.callbackExecutionContext = c
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
