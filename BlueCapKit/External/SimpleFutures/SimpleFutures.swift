//
//  SimpleFutures.swift
//  SimpleFutures
//
//  Created by Troy Stribling on 5/25/15.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import Foundation

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Optional
extension Optional {
    
    func flatmap<M>(mapping:Wrapped -> M?) -> M? {
        switch self {
        case .Some(let value):
            return mapping(value)
        case .None:
            return nil
        }
    }
    
    func filter(predicate:Wrapped -> Bool) -> Wrapped? {
        switch self {
        case .Some(let value):
            return predicate(value) ? Optional(value) : nil
        case .None:
            return Optional()
        }
    }
    
    func foreach(apply:Wrapped -> Void) {
        switch self {
        case .Some(let value):
            apply(value)
        case .None:
            break
        }
    }
    
}

public func flatmap<T,M>(maybe:T?, mapping:T -> M?) -> M? {
    return maybe.flatmap(mapping)
}

public func foreach<T>(maybe:T?, apply:T -> Void) {
    maybe.foreach(apply)
}

public func filter<T>(maybe:T?, predicate:T -> Bool) -> T? {
    return maybe.filter(predicate)
}

public func forcomp<T,U>(f:T?, g:U?, apply:(T,U) -> Void) {
    f.foreach {fvalue in
        g.foreach {gvalue in
            apply(fvalue, gvalue)
        }
    }
}
public func flatten<T>(maybe:T??) -> T? {
    switch maybe {
    case .Some(let value):
        return value
    case .None:
        return Optional()
    }
}

public func forcomp<T,U,V>(f:T?, g:U?, h:V?, apply:(T,U,V) -> Void) {
    f.foreach {fvalue in
        g.foreach {gvalue in
            h.foreach {hvalue in
                apply(fvalue, gvalue, hvalue)
            }
        }
    }
}

public func forcomp<T,U,V>(f:T?, g:U?, yield:(T,U) -> V) -> V? {
    return f.flatmap {fvalue in
        g.map {gvalue in
            yield(fvalue, gvalue)
        }
    }
}

public func forcomp<T,U,V, W>(f:T?, g:U?, h:V?, yield:(T,U,V) -> W) -> W? {
    return f.flatmap {fvalue in
        g.flatmap {gvalue in
            h.map {hvalue in
                yield(fvalue, gvalue, hvalue)
            }
        }
    }
}

public func forcomp<T,U>(f:T?, g:U?, filter:(T,U) -> Bool, apply:(T,U) -> Void) {
    f.foreach {fvalue in
        g.filter{gvalue in
            filter(fvalue, gvalue)
        }.foreach {gvalue in
            apply(fvalue, gvalue)
        }
    }
}

public func forcomp<T,U,V>(f:T?, g:U?, h:V?, filter:(T,U,V) -> Bool, apply:(T,U,V) -> Void) {
    f.foreach {fvalue in
        g.foreach {gvalue in
            h.filter{hvalue in
                filter(fvalue, gvalue, hvalue)
            }.foreach {hvalue in
                apply(fvalue, gvalue, hvalue)
            }
        }
    }
}

public func forcomp<T,U,V>(f:T?, g:U?, filter:(T,U) -> Bool, yield:(T,U) -> V) -> V? {
    return f.flatmap {fvalue in
        g.filter {gvalue in
            filter(fvalue, gvalue)
        }.map {gvalue in
            yield(fvalue, gvalue)
        }
    }
}

public func forcomp<T,U,V,W>(f:T?, g:U?, h:V?, filter:(T,U,V) -> Bool, yield:(T,U,V) -> W) -> W? {
    return f.flatmap {fvalue in
        g.flatmap {gvalue in
            h.filter {hvalue in
                filter(fvalue, gvalue, hvalue)
            }.map {hvalue in
                yield(fvalue, gvalue, hvalue)
            }
        }
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Try
public struct TryError {
    public static let domain = "Wrappers"
    public static let filterFailed = NSError(domain:domain, code:1, userInfo:[NSLocalizedDescriptionKey:"Filter failed"])
}

public enum Try<T> {
    
    case Success(T)
    case Failure(NSError)
    
    public init(_ value:T) {
        self = .Success(value)
    }
    
    public init(_ error:NSError) {
        self = .Failure(error)
    }
    
    public func isSuccess() -> Bool {
        switch self {
        case .Success:
            return true
        case .Failure:
            return false
        }
    }
    
    public func isFailure() -> Bool {
        switch self {
        case .Success:
            return false
        case .Failure:
            return true
        }
    }
    
    public func map<M>(mapping:T -> M) -> Try<M> {
        switch self {
        case .Success(let value):
            return Try<M>(mapping(value))
        case .Failure(let error):
            return Try<M>(error)
        }
    }
    
    public func flatmap<M>(mapping:T -> Try<M>) -> Try<M> {
        switch self {
        case .Success(let value):
            return mapping(value)
        case .Failure(let error):
            return Try<M>(error)
        }
    }
    
    public func recover(recovery:NSError -> T) -> Try<T> {
        switch self {
        case .Success(let box):
            return Try(box)
        case .Failure(let error):
            return Try<T>(recovery(error))
        }
    }
    
    public func recoverWith(recovery:NSError -> Try<T>) -> Try<T> {
        switch self {
        case .Success(let value):
            return Try(value)
        case .Failure(let error):
            return recovery(error)
        }
    }
    
    public func filter(predicate:T -> Bool) -> Try<T> {
        switch self {
        case .Success(let value):
            if !predicate(value) {
                return Try<T>(TryError.filterFailed)
            } else {
                return Try(value)
            }
        case .Failure(_):
            return self
        }
    }
    
    public func foreach(apply:T -> Void) {
        switch self {
        case .Success(let value):
            apply(value)
        case .Failure:
            return
        }
    }
    
    public func toOptional() -> Optional<T> {
        switch self {
        case .Success(let value):
            return Optional<T>(value)
        case .Failure(_):
            return Optional<T>()
        }
    }
    
    public func getOrElse(failed:T) -> T {
        switch self {
        case .Success(let value):
            return value
        case .Failure(_):
            return failed
        }
    }
    
    public func orElse(failed:Try<T>) -> Try<T> {
        switch self {
        case .Success(let box):
            return Try(box)
        case .Failure(_):
            return failed
        }
    }
    
}

public func flatten<T>(result:Try<Try<T>>) -> Try<T> {
    switch result {
    case .Success(let value):
        return value
    case .Failure(let error):
        return Try<T>(error)
    }
}

public func forcomp<T,U>(f:Try<T>, g:Try<U>, apply:(T,U) -> Void) {
    f.foreach {fvalue in
        g.foreach {gvalue in
            apply(fvalue, gvalue)
        }
    }
}

public func forcomp<T,U,V>(f:Try<T>, g:Try<U>, h:Try<V>, apply:(T,U,V) -> Void) {
    f.foreach {fvalue in
        g.foreach {gvalue in
            h.foreach {hvalue in
                apply(fvalue, gvalue, hvalue)
            }
        }
    }
}

public func forcomp<T,U,V>(f:Try<T>, g:Try<U>, yield:(T,U) -> V) -> Try<V> {
    return f.flatmap {fvalue in
        g.map {gvalue in
            yield(fvalue, gvalue)
        }
    }
}

public func forcomp<T,U,V,W>(f:Try<T>, g:Try<U>, h:Try<V>, yield:(T,U,V) -> W) -> Try<W> {
    return f.flatmap {fvalue in
        g.flatmap {gvalue in
            h.map {hvalue in
                yield(fvalue, gvalue, hvalue)
            }
        }
    }
}

public func forcomp<T,U>(f:Try<T>, g:Try<U>, filter:(T,U) -> Bool, apply:(T,U) -> Void) {
    f.foreach {fvalue in
        g.filter{gvalue in
            filter(fvalue, gvalue)
        }.foreach {gvalue in
            apply(fvalue, gvalue)
        }
    }
}

public func forcomp<T,U,V>(f:Try<T>, g:Try<U>, h:Try<V>, filter:(T,U,V) -> Bool, apply:(T,U,V) -> Void) {
    f.foreach {fvalue in
        g.foreach {gvalue in
            h.filter{hvalue in
                filter(fvalue, gvalue, hvalue)
            }.foreach {hvalue in
                apply(fvalue, gvalue, hvalue)
            }
        }
    }
}

public func forcomp<T,U,V>(f:Try<T>, g:Try<U>, filter:(T,U) -> Bool, yield:(T,U) -> V) -> Try<V> {
    return f.flatmap {fvalue in
        g.filter {gvalue in
            filter(fvalue, gvalue)
        }.map {gvalue in
            yield(fvalue, gvalue)
        }
    }
}

public func forcomp<T,U,V,W>(f:Try<T>, g:Try<U>, h:Try<V>, filter:(T,U,V) -> Bool, yield:(T,U,V) -> W) -> Try<W> {
    return f.flatmap {fvalue in
        g.flatmap {gvalue in
            h.filter {hvalue in
                filter(fvalue, gvalue, hvalue)
            }.map {hvalue in
                yield(fvalue, gvalue, hvalue)
            }
        }
    }
    
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// ExecutionContext
public protocol ExecutionContext {
    
    func execute(task:Void->Void)
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// QueueContext
public struct QueueContext : ExecutionContext {
    
    public static let main =  QueueContext(queue:Queue.main)
    
    public static let global = QueueContext(queue:Queue.global)
    
    let queue:Queue
    
    public init(queue:Queue) {
        self.queue = queue
    }
    
    public func execute(task:Void -> Void) {
        queue.async(task)
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Queue
public struct Queue {
    
    public static let main              = Queue(dispatch_get_main_queue());
    public static let global            = Queue(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0))
    
    internal static let simpleFutures       = Queue("us.gnos.simpleFutures")
    internal static let simpleFutureStreams = Queue("us.gnos.simpleFutureStreams")
    
    var queue: dispatch_queue_t
    
    
    public init(_ queueName:String) {
        self.queue = dispatch_queue_create(queueName, DISPATCH_QUEUE_SERIAL)
    }
    
    public init(_ queue:dispatch_queue_t) {
        self.queue = queue
    }
    
    public func sync(block:Void -> Void) {
        dispatch_sync(self.queue, block)
    }
    
    public func sync<T>(block:Void -> T) -> T {
        var result:T!
        dispatch_sync(self.queue, {
            result = block();
        });
        return result;
    }
    
    public func async(block:dispatch_block_t) {
        dispatch_async(self.queue, block);
    }
    
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
public struct SimpleFuturesError {
    static let domain = "SimpleFutures"
    static let futureCompleted      = NSError(domain:domain, code:1, userInfo:[NSLocalizedDescriptionKey:"Future has been completed"])
    static let futureNotCompleted   = NSError(domain:domain, code:2, userInfo:[NSLocalizedDescriptionKey:"Future has not been completed"])
}

public struct SimpleFuturesException {
    static let futureCompleted = NSException(name:"Future complete error", reason: "Future previously completed.", userInfo:nil)
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Promise
public class Promise<T> {
    
    public let future = Future<T>()
    
    public var completed : Bool {
        return self.future.completed
    }
    
    public init() {
    }
    
    public func completeWith(future:Future<T>) {
        self.completeWith(self.future.defaultExecutionContext, future:future)
    }
    
    public func completeWith(executionContext:ExecutionContext, future:Future<T>) {
        self.future.completeWith(executionContext, future:future)
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
    
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Future
public class Future<T> {
    
    private var result:Try<T>?
    
    internal let defaultExecutionContext: ExecutionContext  = QueueContext.main
    typealias OnComplete                                    = Try<T> -> Void
    private var saveCompletes                               = [OnComplete]()
    
    public var completed : Bool {
        return self.result != nil
    }
    
    public init() {
    }
    
    // should be future mixin
    internal func complete(result:Try<T>) {
        Queue.simpleFutures.sync {
            if self.result != nil {
                SimpleFuturesException.futureCompleted.raise()
            }
            self.result = result
            for complete in self.saveCompletes {
                complete(result)
            }
            self.saveCompletes.removeAll()
        }
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
    
    public func onComplete(complete:Try<T> -> Void) {
        self.onComplete(self.defaultExecutionContext, complete:complete)
    }
    
    public func onSuccess(success:T -> Void) {
        self.onSuccess(self.defaultExecutionContext, success:success)
    }
    
    public func onSuccess(executionContext:ExecutionContext, success:T -> Void){
        self.onComplete(executionContext) {result in
            switch result {
            case .Success(let value):
                success(value)
            default:
                break
            }
        }
    }
    
    public func onFailure(failure:NSError -> Void) -> Void {
        return self.onFailure(self.defaultExecutionContext, failure:failure)
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
    
    public func map<M>(mapping:T -> Try<M>) -> Future<M> {
        return map(self.defaultExecutionContext, mapping:mapping)
    }
    
    public func map<M>(executionContext:ExecutionContext, mapping:T -> Try<M>) -> Future<M> {
        let future = Future<M>()
        self.onComplete(executionContext) {result in
            future.complete(result.flatmap(mapping))
        }
        return future
    }
    
    public func flatmap<M>(mapping:T -> Future<M>) -> Future<M> {
        return self.flatmap(self.defaultExecutionContext, mapping:mapping)
    }
    
    public func flatmap<M>(executionContext:ExecutionContext, mapping:T -> Future<M>) -> Future<M> {
        let future = Future<M>()
        self.onComplete(executionContext) {result in
            switch result {
            case .Success(let value):
                future.completeWith(executionContext, future:mapping(value))
            case .Failure(let error):
                future.failure(error)
            }
        }
        return future
    }
    
    public func andThen(complete:Try<T> -> Void) -> Future<T> {
        return self.andThen(self.defaultExecutionContext, complete:complete)
    }
    
    public func andThen(executionContext:ExecutionContext, complete:Try<T> -> Void) -> Future<T> {
        let future = Future<T>()
        future.onComplete(executionContext, complete:complete)
        self.onComplete(executionContext) {result in
            future.complete(result)
        }
        return future
    }
    
    public func recover(recovery: NSError -> Try<T>) -> Future<T> {
        return self.recover(self.defaultExecutionContext, recovery:recovery)
    }
    
    public func recover(executionContext:ExecutionContext, recovery:NSError -> Try<T>) -> Future<T> {
        let future = Future<T>()
        self.onComplete(executionContext) {result in
            future.complete(result.recoverWith(recovery))
        }
        return future
    }
    
    public func recoverWith(recovery:NSError -> Future<T>) -> Future<T> {
        return self.recoverWith(self.defaultExecutionContext, recovery:recovery)
    }
    
    public func recoverWith(executionContext:ExecutionContext, recovery:NSError -> Future<T>) -> Future<T> {
        let future = Future<T>()
        self.onComplete(executionContext) {result in
            switch result {
            case .Success(let value):
                future.success(value)
            case .Failure(let error):
                future.completeWith(executionContext, future:recovery(error))
            }
        }
        return future
    }
    
    public func withFilter(filter:T -> Bool) -> Future<T> {
        return self.withFilter(self.defaultExecutionContext, filter:filter)
    }
    
    public func withFilter(executionContext:ExecutionContext, filter:T -> Bool) -> Future<T> {
        let future = Future<T>()
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
    
    internal func completeWith(future:Future<T>) {
        self.completeWith(self.defaultExecutionContext, future:future)
    }
    
    internal func completeWith(executionContext:ExecutionContext, future:Future<T>) {
        let isCompleted = Queue.simpleFutures.sync {Void -> Bool in
            return self.result != nil
        }
        if isCompleted == false {
            future.onComplete(executionContext) {result in
                self.complete(result)
            }
        }
    }
    
    internal func success(value:T) {
        self.complete(Try(value))
    }
    
    internal func failure(error:NSError) {
        self.complete(Try<T>(error))
    }
    
    // future stream extensions
    public func flatmap<M>(capacity:Int, mapping:T -> FutureStream<M>) -> FutureStream<M> {
        return self.flatMapStream(capacity, executionContext:self.defaultExecutionContext, mapping:mapping)
    }
    
    public func flatmap<M>(mapping:T -> FutureStream<M>) -> FutureStream<M> {
        return self.flatMapStream(nil, executionContext:self.defaultExecutionContext, mapping:mapping)
    }
    
    public func flatmap<M>(capacity:Int, executionContext:ExecutionContext, mapping:T -> FutureStream<M>) -> FutureStream<M>  {
        return self.flatMapStream(capacity, executionContext:self.defaultExecutionContext, mapping:mapping)
    }
    
    public func flatmap<M>(executionContext:ExecutionContext, mapping:T -> FutureStream<M>) -> FutureStream<M>  {
        return self.flatMapStream(nil, executionContext:self.defaultExecutionContext, mapping:mapping)
    }
    
    public func recoverWith(recovery:NSError -> FutureStream<T>) -> FutureStream<T> {
        return self.recoverWithStream(nil, executionContext:self.defaultExecutionContext, recovery:recovery)
    }
    
    public func recoverWith(capacity:Int, recovery:NSError -> FutureStream<T>) -> FutureStream<T> {
        return self.recoverWithStream(capacity, executionContext:self.defaultExecutionContext, recovery:recovery)
    }
    
    public func recoverWith(executionContext:ExecutionContext, recovery:NSError -> FutureStream<T>) -> FutureStream<T> {
        return self.recoverWithStream(nil, executionContext:executionContext, recovery:recovery)
    }
    
    public func recoverWith(capacity:Int, executionContext:ExecutionContext, recovery:NSError -> FutureStream<T>) -> FutureStream<T> {
        return self.recoverWithStream(capacity, executionContext:executionContext, recovery:recovery)
    }
    
    internal func completeWith(stream:FutureStream<T>) {
        self.completeWith(self.defaultExecutionContext, stream:stream)
    }
    
    internal func completeWith(executionContext:ExecutionContext, stream:FutureStream<T>) {
        stream.onComplete(executionContext) {result in
            self.complete(result)
        }
    }
    
    internal func flatMapStream<M>(capacity:Int?, executionContext:ExecutionContext, mapping:T -> FutureStream<M>) -> FutureStream<M> {
        let stream = FutureStream<M>(capacity:capacity)
        self.onComplete(executionContext) {result in
            switch result {
            case .Success(let value):
                stream.completeWith(executionContext, stream:mapping(value))
            case .Failure(let error):
                stream.failure(error)
            }
        }
        return stream
    }
    
    internal func recoverWithStream(capacity:Int?, executionContext:ExecutionContext, recovery:NSError -> FutureStream<T>) -> FutureStream<T> {
        let stream = FutureStream<T>(capacity:capacity)
        self.onComplete(executionContext) {result in
            switch result {
            case .Success(let value):
                stream.success(value)
            case .Failure(let error):
                stream.completeWith(executionContext, stream:recovery(error))
            }
        }
        return stream
    }
    
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// create futures
public func future<T>(computeResult:Void -> Try<T>) -> Future<T> {
    return future(QueueContext.global, calculateResult:computeResult)
}

public func future<T>(executionContext:ExecutionContext, calculateResult:Void -> Try<T>) -> Future<T> {
    let promise = Promise<T>()
    executionContext.execute {
        promise.complete(calculateResult())
    }
    return promise.future
}

public func forcomp<T,U>(f:Future<T>, g:Future<U>, apply:(T,U) -> Void) -> Void {
    return forcomp(f.defaultExecutionContext, f:f, g:g, apply:apply)
}

public func forcomp<T,U>(executionContext:ExecutionContext, f:Future<T>, g:Future<U>, apply:(T,U) -> Void) -> Void {
    f.foreach(executionContext) {fvalue in
        g.foreach(executionContext) {gvalue in
            apply(fvalue, gvalue)
        }
    }
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// for comprehensions
public func forcomp<T,U>(f:Future<T>, g:Future<U>, filter:(T,U) -> Bool, apply:(T,U) -> Void) -> Void {
    return forcomp(f.defaultExecutionContext, f:f, g:g, filter:filter, apply:apply)
}

public func forcomp<T,U>(executionContext:ExecutionContext, f:Future<T>, g:Future<U>, filter:(T,U) -> Bool, apply:(T,U) -> Void) -> Void {
    f.foreach(executionContext) {fvalue in
        g.withFilter(executionContext) {gvalue in
            filter(fvalue, gvalue)
        }.foreach(executionContext) {gvalue in
            apply(fvalue, gvalue)
        }
    }
}

public func forcomp<T,U,V>(f:Future<T>, g:Future<U>, h:Future<V>, apply:(T,U,V) -> Void) -> Void {
    return forcomp(f.defaultExecutionContext, f:f, g:g, h:h, apply:apply)
}

public func forcomp<T,U,V>(executionContext:ExecutionContext, f:Future<T>, g:Future<U>, h:Future<V>, apply:(T,U,V) -> Void) -> Void {
    f.foreach(executionContext) {fvalue in
        g.foreach(executionContext) {gvalue in
            h.foreach(executionContext) {hvalue in
                apply(fvalue, gvalue, hvalue)
            }
        }
    }
}

public func forcomp<T,U,V>(f:Future<T>, g:Future<U>, h:Future<V>, filter:(T,U,V) -> Bool, apply:(T,U,V) -> Void) -> Void {
    return forcomp(f.defaultExecutionContext, f:f, g:g, h:h, filter:filter, apply:apply)
}

public func forcomp<T,U,V>(executionContext:ExecutionContext, f:Future<T>, g:Future<U>, h:Future<V>, filter:(T,U,V) -> Bool, apply:(T,U,V) -> Void) -> Void {
    f.foreach(executionContext) {fvalue in
        g.foreach(executionContext) {gvalue in
            h.withFilter(executionContext) {hvalue in
                filter(fvalue, gvalue, hvalue)
            }.foreach(executionContext) {hvalue in
                apply(fvalue, gvalue, hvalue)
            }
        }
    }
}

public func forcomp<T,U,V>(f:Future<T>, g:Future<U>, yield:(T,U) -> Try<V>) -> Future<V> {
    return forcomp(f.defaultExecutionContext, f:f, g:g, yield:yield)
}

public func forcomp<T,U,V>(executionContext:ExecutionContext, f:Future<T>, g:Future<U>, yield:(T,U) -> Try<V>) -> Future<V> {
    return f.flatmap(executionContext) {fvalue in
        g.map(executionContext) {gvalue in
            yield(fvalue, gvalue)
        }
    }
}

public func forcomp<T,U,V>(f:Future<T>, g:Future<U>, filter:(T,U) -> Bool, yield:(T,U) -> Try<V>) -> Future<V> {
    return forcomp(f.defaultExecutionContext, f:f, g:g, filter:filter, yield:yield)
}

public func forcomp<T,U,V>(executionContext:ExecutionContext, f:Future<T>, g:Future<U>, filter:(T,U) -> Bool, yield:(T,U) -> Try<V>) -> Future<V> {
    return f.flatmap(executionContext) {fvalue in
        g.withFilter(executionContext) {gvalue in
            filter(fvalue, gvalue)
        }.map(executionContext) {gvalue in
            yield(fvalue, gvalue)
        }
    }
}

public func forcomp<T,U,V,W>(f:Future<T>, g:Future<U>, h:Future<V>, yield:(T,U,V) -> Try<W>) -> Future<W> {
    return forcomp(f.defaultExecutionContext, f:f, g:g, h:h, yield:yield)
}

public func forcomp<T,U,V,W>(executionContext:ExecutionContext, f:Future<T>, g:Future<U>, h:Future<V>, yield:(T,U,V) -> Try<W>) -> Future<W> {
    return f.flatmap(executionContext) {fvalue in
        g.flatmap(executionContext) {gvalue in
            h.map(executionContext) {hvalue in
                yield(fvalue, gvalue, hvalue)
            }
        }
    }
}

public func forcomp<T,U, V, W>(f:Future<T>, g:Future<U>, h:Future<V>, filter:(T,U,V) -> Bool, yield:(T,U,V) -> Try<W>) -> Future<W> {
    return forcomp(f.defaultExecutionContext, f:f, g:g, h:h, filter:filter, yield:yield)
}

public func forcomp<T,U, V, W>(executionContext:ExecutionContext, f:Future<T>, g:Future<U>, h:Future<V>, filter:(T,U,V) -> Bool, yield:(T,U,V) -> Try<W>) -> Future<W> {
    return f.flatmap(executionContext) {fvalue in
        g.flatmap(executionContext) {gvalue in
            h.withFilter(executionContext) {hvalue in
                filter(fvalue, gvalue, hvalue)
            }.map(executionContext) {hvalue in
                yield(fvalue, gvalue, hvalue)
            }
        }
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// StreamPromise
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
        future.completeWith(executionContext, future:future)
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
        future.completeWith(executionContext, stream:stream)
    }
    
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// FutureStream
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
    
    // should be future mixin
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
    
    public func onComplete(complete:Try<T> -> Void) {
        self.onComplete(self.defaultExecutionContext, complete:complete)
    }
    
    public func onSuccess(success:T -> Void) {
        self.onSuccess(self.defaultExecutionContext, success:success)
    }
    
    public func onSuccess(executionContext:ExecutionContext, success:T -> Void) {
        self.onComplete(executionContext) {result in
            switch result {
            case .Success(let value):
                success(value)
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
            case .Success(let value):
                future.completeWith(executionContext, stream:mapping(value))
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
            case .Success(let value):
                future.success(value)
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
            case .Success(let value):
                future.completeWith(executionContext, future:mapping(value))
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
            case .Success(let value):
                future.success(value)
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

