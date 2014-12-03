//
//  SimpleFutures.swift
//  SimpleFutures
//
//  Created by Troy Stribling on 7/5/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation

public class ExecutionContext {
    
    public class var main : ExecutionContext {
        struct Static {
            static let instance : ExecutionContext = ExecutionContext(queue:Queue.main)
        }
        return Static.instance
    }
    
    public class var global: ExecutionContext {
        struct Static {
            static let instance : ExecutionContext = ExecutionContext(queue:Queue.global)
        }
        return Static.instance
    }
    
    let queue:Queue?
    
    public init() {
    }
    
    public init(queue:Queue) {
        self.queue = queue
    }
    
    public func execute(task: Void -> Void) {
        if let queue = queue {
            queue.async(task)
        } else {
            task()
        }
    }
}

public struct Queue {
    
    public static let main = Queue(queue: dispatch_get_main_queue());
    public static let global = Queue(queue: dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0))
    
    var queue: dispatch_queue_t
    
    public init(queue: dispatch_queue_t = dispatch_queue_create("us.gnos.simplefutures", DISPATCH_QUEUE_SERIAL)) {
        self.queue = queue
    }
    
    public func sync(block:Void -> Void) {
        dispatch_sync(queue, block)
    }
    
    public func sync<T>(block: Void -> T) -> T {
        var result:T!
        dispatch_sync(self.queue, {
            result = block();
        });
        return result;
    }
    
    public func async(block: dispatch_block_t) {
        dispatch_async(queue, block);
    }
    
}


public let NoSuchElementError = "NoSuchElementError"

public class Future<T> {
    
    typealias CallbackInternal          = (future: Future<T>) -> Void
    typealias CompletionCallback        = (result:T) -> Void
    typealias SuccessCallback           = (T) -> Void
    public typealias FailureCallback    = (NSError) -> Void
    
    let q  = Queue()
    
    var result:T?
    
    var callbacks: [CallbackInternal] = Array<CallbackInternal>()
    
    public func succeeded(fn:(T -> Void)? = nil) -> Bool {
        if let result = self.result {
            return result.succeeded(fn)
        }
        return false
    }
    
    public func failed(fn:(NSError -> Void)? = nil) -> Bool {
        if let result = self.result {
            return result.failed(fn)
        }
        return false
    }
    
    public func completed(success:(T->Void)? = nil, failure:(NSError->Void)? = nil) -> Bool{
        if let result = self.result {
            result.handle(success:success, failure:failure)
            return true
        }
        return false
    }
    
    internal init() {
    }
    
    func complete(result:T?) {
        let succeeded = tryComplete(result)
        assert(succeeded)
    }
    
    func tryComplete(result:T?) -> Bool {
        if let result = result {
            return self.trySuccess(result)
        } else {
            return self.tryError(nil)
        }
    }
    
    func success(value:T) {
        let succeeded = self.trySuccess(value)
        assert(succeeded)
    }
    
    func trySuccess(value:T) -> Bool {
        return q.sync {
            if self.result != nil {
                return false;
            }
            self.result = value
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

public class Promise<T> {
    
    public let future: Future<T>
    
    public init() {
        self.future = Future<T>()
    }
    
    public func completeWith(future: Future<T>) {
        future.onComplete { result in
            switch result {
            case .Success(let val):
                self.success(val.value)
            case .Failure(let err):
                self.error(err)
            }
        }
    }
    
    public func success(value: T) {
        self.future.success(value)
    }
    
    public func trySuccess(value: T) -> Bool {
        return self.future.trySuccess(value)
    }
    
    public func error(error: NSError) {
        self.future.error(error)
    }
    
    public func tryError(error: NSError) -> Bool {
        return self.future.tryError(error)
    }
    
    public func tryComplete(result: Result<T>) -> Bool {
        return self.future.tryComplete(result)
    }
    
}
