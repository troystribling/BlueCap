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
    
    typealias           OnComplete          = Try<T> -> Void
    typealias           OnSuccess           = T -> Void
    public typealias    OnFailure           = NSError -> Void
    
    var result:Try<T>?
    
    let defaultExecutionContext: ExecutionContext   = QueueContext.main
    var savedCompletions                            = [OnComplete]()
    
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
            case .Success(let resultWrapper):
                success(resultWrapper.value)
            default:
                break
            }
        }
        return
    }
    
    public func onFailure(callback:OnFailure) -> Void {
        return self.onFailure(self.defaultExecutionContext, callback)
    }
    
    public func onFailure(executionContext:ExecutionContext, callback:OnFailure) -> Void {
        self.onComplete(executionContext) { result in
            switch result {
            case .Failure(let error):
                callback(error)
            default:
                break
            }
        }
        return
    }

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
    
    func trySuccess(value:T) -> Bool {
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
    
    private func runSavedCompletions(result:Try<T>) {
        Queue.simplefutures.async {
            for complete in self.savedCompletions {
                complete(result)
            }
            self.savedCompletions.removeAll()
        }
    }
}
