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

public func future<T>(calculateResult:Void -> Try<T>) -> Future<T> {
    return future(QueueContext.global, calculateResult)
}

public func future<T>(calculateResult:@autoclosure() -> Try<T>) -> Future<T> {
    return future(QueueContext.global, calculateResult)
}

public func future<T>(executionContext:ExecutionContext, calculateResult:@autoclosure() -> Try<T>) -> Future<T> {
    return future(executionContext, calculateResult)
}

public func future<T>(executionContext:ExecutionContext, calculateResult:Void -> Try<T>) -> Future<T> {
    let promise = Promise<T>()
    executionContext.execute {
        promise.complete(calculateResult())
    }
    return promise.future
}

public class Future<T> {
    
    typealias           OnComplete          = Try<T> -> Void
    typealias           OnSuccess           = T -> Void
    public typealias    OnFailure           = NSError -> Void
    
    private var result:Try<T>?
    
    private let defaultExecutionContext: ExecutionContext   = QueueContext.main
    private var savedCompletions                            = [OnComplete]()
    
    
    // public interface
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
            res.handle(success: success, failure:failure)
            return true
        }
        return false
    }
    
    public func onComplete(onCompletion:OnComplete) -> Void {
        return self.onComplete(self.defaultExecutionContext, complete:onCompletion)
    }
    
    public func onComplete(executionContext:ExecutionContext, complete:OnComplete) -> Void {
        Queue.simplefutures.sync {
            let savedCompletion : OnComplete = {result in
                executionContext.execute {
                    complete(result)
                }
            }
            if let result = self.result {
                savedCompletion(result)
            } else {
                self.savedCompletions.append(savedCompletion)
            }
        }
        
        return
    }
    
    public func onSuccess(success:OnSuccess) -> Void {
        return self.onSuccess(self.defaultExecutionContext, success:success)
    }
    
    public func onSuccess(executionContext:ExecutionContext, success:OnSuccess) -> Void {
        self.onComplete(executionContext) {result in
            switch result {
            case .Success(let valueWrapper):
                success(valueWrapper.value)
            default:
                break
            }
        }
        return
    }
    
    public func onFailure(failure:OnFailure) -> Void {
        return self.onFailure(self.defaultExecutionContext, failure)
    }
    
    public func onFailure(executionContext:ExecutionContext, failure:OnFailure) -> Void {
        self.onComplete(executionContext) {result in
            switch result {
            case .Failure(let error):
                failure(error)
            default:
                break
            }
        }
        return
    }

    public func map<M>(mapping:T -> Try<M>) -> Future<M> {
        return map(QueueContext.main, mapping)
    }
    
    public func map<M>(executionContext:ExecutionContext, mapping:T -> Try<M>) -> Future<M> {
        let promise = Promise<M>()
        Queue.simplefutures.sync {
            self.onComplete(executionContext) {result in
                switch result {
                case .Success(let valueWrapper):
                    promise.complete(mapping(valueWrapper.value))
                case .Failure(let error):
                    promise.failure(error)
                }
            }
        }
        return promise.future
    }
    
    // internal interface
    internal init() {
    }
    
    internal func complete(result:Try<T>) {
        let succeeded = tryComplete(result)
        assert(succeeded)
    }
    
    internal func tryComplete(result:Try<T>) -> Bool {
        switch result {
        case .Success(let success):
            return self.trySuccess(success.value)
        case .Failure(let error):
            return self.tryError(error)
        }
    }
    
    internal func success(value:T) {
        let succeeded = self.trySuccess(value)
        assert(succeeded)
    }
    
    internal func trySuccess(value:T) -> Bool {
        return Queue.simplefutures.sync {
            if self.result != nil {
                return false;
            }
            self.result = Try(value)
            self.runSavedCompletions(self.result!)
            return true;
        };
    }
    
    internal func failure(error: NSError) {
        let succeeded = self.tryError(error)
        assert(succeeded)
    }
    
    internal func tryError(error: NSError) -> Bool {
        return Queue.simplefutures.sync {
            if self.result != nil {
                return false;
            }
            self.result = Try(error)
            self.runSavedCompletions(self.result!)
            return true;
        };
    }
    
    // private interface
    private func runSavedCompletions(result:Try<T>) {
        Queue.simplefutures.async {
            for complete in self.savedCompletions {
                complete(result)
            }
            self.savedCompletions.removeAll()
        }
    }
}
