//
//  Future.swift
//  SimpleFutures
//
//  Created by Troy Stribling on 7/5/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation

public struct SimpleFuturesError {
    static let domain = "SimpleFutures"
    struct FutureCompleted {
        static let code = 1
        static let description = "Future has been completed"
    }
    struct FutureNotCompleted {
        static let code = 2
        static let description = "Future has not been completed"
    }
}

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
    
    public init(_ value: T) {
        self = .Success(TryWrapper(value))
    }
    
    public init(_ error: NSError) {
        self = .Failure(error)
    }
    
}

// Promise
public class Promise<T> {
    
    public let future = Future<T>()
    
    public var isCompleted : Bool {
        return self.future.isCompleted
    }
    
    public init() {
    }
    
    public func completeWith(future:Future<T>) {
        self.completeWith(self.future.defaultExecutionContext, future:future)
    }
    
    public func completeWith(executionContext:ExecutionContext, future:Future<T>) {
        if self.isCompleted == false {
            future.onComplete(executionContext) {result in
                self.complete(result)
            }
        } else {
            self.failure(NSError(domain:SimpleFuturesError.domain,
                code:SimpleFuturesError.FutureCompleted.code,
                userInfo:[NSLocalizedDescriptionKey:SimpleFuturesError.FutureCompleted.description]))
        }
    }
    
    public func complete(result:Try<T>) {
        self.future.complete(result)
    }
    
    public func success(value:T) {
        self.future.success(value)
    }

    public func failure(error:NSError)  {
        self.future.failure(error)
    }
    

    public func tryComplete(result:Try<T>) -> Bool {
        return self.future.tryComplete(result)
    }
    
    public func trySuccess(value:T) -> Bool {
        return self.future.trySuccess(value)
    }
    
    public func tryError(error:NSError) -> Bool {
        return self.future.tryError(error)
    }
    
}

// future construct
public func future<T>(computeResult:Void -> Try<T>) -> Future<T> {
    return future(QueueContext.global, computeResult)
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
    
    private var result:Try<T>?
    
    internal let defaultExecutionContext: ExecutionContext  = QueueContext.main
    typealias OnComplete                                    = Try<T> -> Void
    private var saveCompletes                               = [OnComplete]()
    
    // public interface
    public init() {
    }
    
    public var isCompleted : Bool {
        return self.result != nil
    }
    
    public func onComplete(complete:Try<T> -> Void) {
        self.onComplete(self.defaultExecutionContext, complete)
    }
    
    public func onComplete(executionContext:ExecutionContext, complete:Try<T> -> Void) -> Void {
        Queue.simpleFutures.sync {
            let savedCompletion : OnComplete = {result in
                executionContext.execute {
                    complete(result)
                }
            }
            if let result = self.result {
                savedCompletion(result)
            } else {
                self.saveCompletes.append(savedCompletion)
            }
        }
    }
    
    public func onSuccess(success:T -> Void) {
        self.onSuccess(self.defaultExecutionContext, success)
    }
    
    public func onSuccess(executionContext:ExecutionContext, success:T -> Void){
        self.onComplete(executionContext) {result in
            switch result {
            case .Success(let valueWrapper):
                success(valueWrapper.value)
            default:
                break
            }
        }
    }
    
    public func onFailure(failure:NSError -> Void) -> Void {
        return self.onFailure(self.defaultExecutionContext, failure)
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

    public func complete(result:Try<T>) {
        let succeeded = tryComplete(result)
        if succeeded == false {
            NSException(name:"Future complete error", reason: "Future previously completed.", userInfo: nil).raise()
        }
    }
    
    public func success(value:T) {
        let succeeded = self.trySuccess(value)
        if succeeded == false {
            NSException(name:"Future success error", reason: "Future previously completed.", userInfo: nil).raise()
        }
    }

    public func failure(error: NSError) {
        let succeeded = self.tryError(error)
        if succeeded == false {
            NSException(name:"Future failure error", reason: "Future previously completed.", userInfo: nil).raise()
        }
    }
    

    public func map<M>(mapping:T -> Try<M>) -> Future<M> {
        return map(self.defaultExecutionContext, mapping)
    }
    
    public func map<M>(executionContext:ExecutionContext, mapping:T -> Try<M>) -> Future<M> {
        let promise = Promise<M>()
        self.onComplete(executionContext) {result in
            switch result {
            case .Success(let resultWrapper):
                promise.complete(mapping(resultWrapper.value))
            case .Failure(let error):
                promise.failure(error)
            }
        }
        return promise.future
    }
    
    public func flatmap<M>(mapping:T -> Future<M>) -> Future<M> {
        return self.flatmap(self.defaultExecutionContext, mapping)
    }

    public func flatmap<M>(executionContext:ExecutionContext, mapping:T -> Future<M>) -> Future<M> {
        let promise = Promise<M>()
        self.onComplete(executionContext) {result in
            switch result {
            case .Success(let resultWrapper):
                promise.completeWith(executionContext, future:mapping(resultWrapper.value))
            case .Failure(let error):
                promise.failure(error)
            }
        }
        return promise.future
    }
    
    public func andThen(complete:Try<T> -> Void) -> Future<T> {
        return self.andThen(self.defaultExecutionContext, complete)
    }
    
    public func andThen(executionContext:ExecutionContext, complete:Try<T> -> Void) -> Future<T> {
        let promise = Promise<T>()
        promise.future.onComplete(executionContext, complete)
        self.onComplete(executionContext) {result in
            promise.complete(result)
        }
        return promise.future
    }
    
    public func recover(recovery: NSError -> Try<T>) -> Future<T> {
        return self.recover(self.defaultExecutionContext, recovery)
    }
    
    public func recover(executionContext:ExecutionContext, recovery:NSError -> Try<T>) -> Future<T> {
        let promise = Promise<T>()
        self.onComplete(executionContext) {result in
            switch result {
            case .Success(let resultWrapper):
                promise.success(resultWrapper.value)
            case .Failure(let error):
                promise.complete(recovery(error))
            }
        }
        return promise.future
    }
    
    public func recoverWith(recovery:NSError -> Future<T>) -> Future<T> {
        return self.recoverWith(self.defaultExecutionContext, recovery)
    }
    
    public func recoverWith(executionContext:ExecutionContext, recovery:NSError -> Future<T>) -> Future<T> {
        let promise = Promise<T>()
            self.onComplete(executionContext) {result in
            switch result {
            case .Success(let resultWrapper):
                promise.success(resultWrapper.value)
            case .Failure(let error):
                promise.completeWith(executionContext, future:recovery(error))
            }
        }
        return promise.future
    }
    
    // internal interface
    internal func tryComplete(result:Try<T>) -> Bool {
        switch result {
        case .Success(let success):
            return self.trySuccess(success.value)
        case .Failure(let error):
            return self.tryError(error)
        }
    }
    
    
    internal func trySuccess(value:T) -> Bool {
        return Queue.simpleFutures.sync {
            if self.result != nil {
                return false;
            }
            self.result = Try(value)
            self.runSavedCompletions(self.result!)
            return true;
        };
    }
    
    internal func tryError(error: NSError) -> Bool {
        return Queue.simpleFutures.sync {
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
        for complete in self.saveCompletes {
            complete(result)
        }
        self.saveCompletes.removeAll()
    }
}
