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
    
    typealias           OnCompleteInFuture  = Future<T> -> Void
    typealias           OnComplete          = Try<T> -> Void
    typealias           OnSuccess           = T -> Void
    public typealias    OnFailure           = NSError -> Void
    
    var result:Try<T>?

    let internalQueue                       = Queue("us.gnos.simplefutures")
    var onCompleteFutures                   = [OnCompleteInFuture]()
    var executionContext : ExecutionContext = QueueContext.main
    
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

    public func onComplete(onCompletion:OnComplete) -> Future<T> {
        return self.onComplete(self.executionContext, complete:onCompletion)
    }
    
    public func onComplete(executionCcontext:ExecutionContext, complete:OnComplete) -> Future<T> {
        self.executionContext = executionCcontext
        self.internalQueue.sync {
            let wrappedCallback : Future<T> -> () = { future in
                if let result = self.result {
                    self.executionContext.execute {
                        complete(result)
                    }
                }
            }
            
            if self.result == nil {
                self.onCompleteFutures.append(wrappedCallback)
            } else {
                wrappedCallback(self)
            }
        }
        
        return self
    }

    public func onSuccess(success:OnSuccess) -> Future<T> {
        self.onComplete(self.executionContext) {result in
            switch result {
            case .Success(let resultWrapper):
                success(resultWrapper.value)
            default:
                break
            }
        }
        
        return self
    }
    
    public func onSuccess(executionCcontext:ExecutionContext, callback:OnSuccess) -> Future<T> {
        self.executionContext = executionCcontext
        return self.onSuccess(callback)
    }
    
    public func onFailure(callback:OnFailure) -> Future<T> {
        self.onComplete(self.executionContext) { result in
            switch result {
            case .Failure(let err):
                callback(err)
            default:
                break
            }
        }
        return self
    }
    
    public func onFailure(executionContext:ExecutionContext, callback:OnFailure) -> Future<T> {
        self.executionContext = executionContext
        return self.onFailure(self.executionContext, callback)
    }
    
    private func runCallbacks() {
        self.executionContext.execute {
            for complete in self.onCompleteFutures {
                complete(self)
            }
            self.onCompleteFutures.removeAll()
        }
    }
}
