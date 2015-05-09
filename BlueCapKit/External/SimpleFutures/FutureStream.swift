//
//  FutureStream.swift
//  BlueCapKit
//
//  Created by Troy Stribling on 12/7/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import Foundation

public class StreamPromise<T> {

    public let future : FutureStream<T>
    
    public init(capacity:Int?=nil) {
        self.future = FutureStream<T>(capacity:capacity)
    }
    
    public func complete(result:Try<T>) {
        self.future.complete(result)
    }
    
    public func completeWith(future:Future<T>) {
        self.completeWith(self.future.defaultExecutionContext, future:future)
    }
    
    public func completeWith(executionContext:ExecutionContext, future:Future<T>) {
        future.completeWith(future)
    }

    public func success(value:T) {
        self.future.success(value)
    }
    
    public func failure(error:NSError) {
        self.future.failure(error)
    }

    public func completeWith(stream:FutureStream<T>) {
        self.completeWith(self.future.defaultExecutionContext, stream:stream)
    }
    
    public func completeWith(executionContext:ExecutionContext, stream:FutureStream<T>) {
        future.completeWith(stream)
    }
    
}

public class FutureStream<T> {
    
    private var futures         = [Future<T>]()
    private typealias InFuture  = Future<T> -> Void
    private var saveCompletes   = [InFuture]()
    private var capacity        : Int?
    
    internal let defaultExecutionContext: ExecutionContext  = QueueContext.main

    public var count : Int {
        return futures.count
    }
    
    public init(capacity:Int?=nil) {
        self.capacity = capacity
    }
    
    // Futureable protocol
    public func onComplete(executionContext:ExecutionContext, complete:Try<T> -> Void) {
        Queue.simpleFutureStreams.sync {
            let futureComplete : InFuture = {future in
                future.onComplete(executionContext, complete:complete)
            }
            self.saveCompletes.append(futureComplete)
            for future in self.futures {
                futureComplete(future)
            }
        }
    }

    internal func complete(result:Try<T>) {
        let future = Future<T>()
        future.complete(result)
        Queue.simpleFutureStreams.sync {
            self.addFuture(future)
            for complete in self.saveCompletes {
                complete(future)
            }
        }
    }
    
    // should be future mixin
    public func onComplete(complete:Try<T> -> Void) {
        self.onComplete(self.defaultExecutionContext, complete:complete)
    }
    
    public func onSuccess(success:T -> Void) {
        self.onSuccess(self.defaultExecutionContext, success:success)
    }

    public func onSuccess(executionContext:ExecutionContext, success:T -> Void) {
        self.onComplete(executionContext) {result in
            switch result {
            case .Success(let resultBox):
                success(resultBox.value)
            default:
                break
            }
        }
    }

    public func onFailure(failure:NSError -> Void) {
        self.onFailure(self.defaultExecutionContext, failure:failure)
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
    
    public func map<M>(mapping:T -> Try<M>) -> FutureStream<M> {
        return self.map(self.defaultExecutionContext, mapping:mapping)
    }
    
    public func map<M>(executionContext:ExecutionContext, mapping:T -> Try<M>) -> FutureStream<M> {
        let future = FutureStream<M>(capacity:self.capacity)
        self.onComplete(executionContext) {result in
            future.complete(result.flatmap(mapping))
        }
        return future
    }
    
    public func flatmap<M>(mapping:T -> FutureStream<M>) -> FutureStream<M> {
        return self.flatMap(self.defaultExecutionContext, mapping:mapping)
    }
    
    public func flatMap<M>(executionContext:ExecutionContext, mapping:T -> FutureStream<M>) -> FutureStream<M> {
        let future = FutureStream<M>(capacity:self.capacity)
        self.onComplete(executionContext) {result in
            switch result {
            case .Success(let resultBox):
                future.completeWith(executionContext, stream:mapping(resultBox.value))
            case .Failure(let error):
                future.failure(error)
            }
        }
        return future
    }

    public func andThen(complete:Try<T> -> Void) -> FutureStream<T> {
        return self.andThen(self.defaultExecutionContext, complete:complete)
    }
    
    public func andThen(executionContext:ExecutionContext, complete:Try<T> -> Void) -> FutureStream<T> {
        let future = FutureStream<T>(capacity:self.capacity)
        future.onComplete(executionContext, complete:complete)
        self.onComplete(executionContext) {result in
            future.complete(result)
        }
        return future
    }
    
    public func recover(recovery:NSError -> Try<T>) -> FutureStream<T> {
        return self.recover(self.defaultExecutionContext, recovery:recovery)
    }
    
    public func recover(executionContext:ExecutionContext, recovery:NSError -> Try<T>) -> FutureStream<T> {
        let future = FutureStream<T>(capacity:self.capacity)
        self.onComplete(executionContext) {result in
            future.complete(result.recoverWith(recovery))
        }
        return future
    }
    
    public func recoverWith(recovery:NSError -> FutureStream<T>) -> FutureStream<T> {
        return self.recoverWith(self.defaultExecutionContext, recovery:recovery)
    }
    
    public func recoverWith(executionContext:ExecutionContext, recovery:NSError -> FutureStream<T>) -> FutureStream<T> {
        let future = FutureStream<T>(capacity:self.capacity)
        self.onComplete(executionContext) {result in
            switch result {
            case .Success(let resultBox):
                future.success(resultBox.value)
            case .Failure(let error):
                future.completeWith(executionContext, stream:recovery(error))
            }
        }
        return future
    }

    public func withFilter(filter:T -> Bool) -> FutureStream<T> {
        return self.withFilter(self.defaultExecutionContext, filter:filter)
    }
    
    public func withFilter(executionContext:ExecutionContext, filter:T -> Bool) -> FutureStream<T> {
        let future = FutureStream<T>(capacity:self.capacity)
        self.onComplete(executionContext) {result in
            future.complete(result.filter(filter))
        }
        return future
    }

    public func foreach(apply:T -> Void) {
        self.foreach(self.defaultExecutionContext, apply:apply)
    }
    
    public func foreach(executionContext:ExecutionContext, apply:T -> Void) {
        self.onComplete(executionContext) {result in
            result.foreach(apply)
        }
    }

    internal func completeWith(stream:FutureStream<T>) {
        self.completeWith(self.defaultExecutionContext, stream:stream)
    }
    
    internal func completeWith(executionContext:ExecutionContext, stream:FutureStream<T>) {
        stream.onComplete(executionContext) {result in
            self.complete(result)
        }
    }
    
    internal func success(value:T) {
        self.complete(Try(value))
    }
    
    internal func failure(error:NSError) {
        self.complete(Try<T>(error))
    }
    
    // future stream extensions
    public func flatmap<M>(mapping:T -> Future<M>) -> FutureStream<M> {
        return self.flatmap(self.defaultExecutionContext, mapping:mapping)
    }
    
    public func flatmap<M>(executionContext:ExecutionContext, mapping:T -> Future<M>) -> FutureStream<M> {
        let future = FutureStream<M>(capacity:self.capacity)
        self.onComplete(executionContext) {result in
            switch result {
            case .Success(let resultBox):
                future.completeWith(executionContext, future:mapping(resultBox.value))
            case .Failure(let error):
                future.failure(error)
            }
        }
        return future
    }

    public func recoverWith(recovery:NSError -> Future<T>) -> FutureStream<T> {
        return self.recoverWith(self.defaultExecutionContext, recovery:recovery)
    }
    
    public func recoverWith(executionContext:ExecutionContext, recovery:NSError -> Future<T>) -> FutureStream<T> {
        let future = FutureStream<T>(capacity:self.capacity)
        self.onComplete(executionContext) {result in
            switch result {
            case .Success(let resultBox):
                future.success(resultBox.value)
            case .Failure(let error):
                future.completeWith(executionContext, future:recovery(error))
            }
        }
        return future
    }
    
    internal func completeWith(future:Future<T>) {
        self.completeWith(self.defaultExecutionContext, future:future)
    }
    
    internal func completeWith(executionContext:ExecutionContext, future:Future<T>) {
        future.onComplete(executionContext) {result in
            self.complete(result)
        }
    }
    
    internal func addFuture(future:Future<T>) {
        if let capacity = self.capacity {
            if self.futures.count >= capacity {
                self.futures.removeAtIndex(0)
            }
        }
        self.futures.append(future)
    }
    
}