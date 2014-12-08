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

// Try
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

// Promise
public class Promise<T> {
    
    public let future = Future<T>()
    
//    public var isCompleted : Bool {
//        
//    }
    
    public init() {
    }
    
    public func completeWith(future:Future<T>) {
        future.onComplete {result in
            self.complete(result)
        }
    }
    
    public func complete(result:Try<T>) {
        self.future.complete(result)
    }
    
    public func success(value:T) {
        self.future.success(value)
    }
    
    public func trySuccess(value:T) -> Bool {
        return self.future.trySuccess(value)
    }
    
    public func failure(error:NSError) {
        self.future.failure(error)
    }
    
    public func tryError(error:NSError) -> Bool {
        return self.future.tryError(error)
    }
    
    public func tryComplete(result:Try<T>) -> Bool {
        return self.future.tryComplete(result)
    }
    
}

// future
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

// Future
public class Future<T> {
    
    internal typealias OnComplete   = Try<T> -> Void
    internal typealias OnSuccess    = T -> Void
    public typealias   OnFailure    = NSError -> Void
    
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
        if let result = self.result {
            result.handle(success: success, failure:failure)
            return true
        }
        return false
    }
    
    public func onComplete(onCompletion:OnComplete) {
        self.onComplete(self.defaultExecutionContext, complete:onCompletion)
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
    }
    
    public func onSuccess(success:OnSuccess) {
        self.onSuccess(self.defaultExecutionContext, success:success)
    }
    
    public func onSuccess(executionContext:ExecutionContext, success:OnSuccess){
        self.onComplete(executionContext) {result in
            switch result {
            case .Success(let valueWrapper):
                success(valueWrapper.value)
            default:
                break
            }
        }
    }
    
    public func onFailure(failure:OnFailure) -> Void {
        return self.onFailure(self.defaultExecutionContext, failure)
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

    public func map<M>(mapping:T -> Try<M>) -> Future<M> {
        return map(QueueContext.main, mapping)
    }
    
    public func map<M>(executionContext:ExecutionContext, mapping:T -> Try<M>) -> Future<M> {
        let promise = Promise<M>()
            self.onComplete(executionContext) {result in
            switch result {
            case .Success(let valueWrapper):
                promise.complete(mapping(valueWrapper.value))
            case .Failure(let error):
                promise.failure(error)
            }
        }
        return promise.future
    }
    
    public func flatmap<M>(mapping:T -> Try<M>) -> Future<M> {
        return self.flatmap(QueueContext.main, mapping)
    }

    public func flatmap<M>(executionContext:ExecutionContext, mapping:T -> Try<M>) -> Future<M> {
        let promise = Promise<M>()
        return promise.future
    }
    
    public func andThen(complete:OnComplete) -> Future<T> {
        return self.andThen(QueueContext.main, complete)
    }
    
    public func andThen(executionContext:ExecutionContext, complete:OnComplete) -> Future<T> {
        let promise = Promise<T>()
        promise.future.onComplete(executionContext, complete)
        self.onComplete(executionContext) {result in
            promise.completeWith(self)
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
        for complete in self.savedCompletions {
            complete(result)
        }
        self.savedCompletions.removeAll()
    }
}
