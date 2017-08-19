//
//  SimpleFutures.swift
//  SimpleFutures
//
//  Created by Troy Stribling on 5/25/15.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import Foundation

// MARK: - Errors -

public enum FuturesError : Int, Swift.Error {
    case noSuchElement
    case invalidValue
}

// MARK: - Optional -

public extension Optional {

    func filter(_ predicate: (Wrapped) throws -> Bool) rethrows -> Wrapped? {
        switch self {
        case .some(let value):
            return try predicate(value) ? Optional(value) : nil
        case .none:
            return Optional.none
        }
    }
    
    func forEach(_ apply: (Wrapped) throws -> Void) rethrows {
        switch self {
        case .some(let value):
            try apply(value)
        case .none:
            break
        }
    }

}

// MARK: - Tryable -

public protocol Tryable {
    associatedtype T

    var value: T? { get }
    var error: Swift.Error? { get }

    init(_ value: T)
    init(_ error: Swift.Error)

    func map<M>(_ mapping: (T) throws -> M) -> Try<M>
}

// MARK: - Try -

public enum Try<T> : Tryable {

    case success(T)
    case failure(Swift.Error)

    public var value: T? {
        switch self {
        case .success(let value):
            return value
        case .failure:
            return nil
        }
    }

    public var error: Swift.Error? {
        switch self {
        case .success:
            return nil
        case .failure(let error):
            return error
        }
    }

    public init(_ value: T) {
        self = .success(value)
    }
    
    public init(_ error: Swift.Error) {
        self = .failure(error)
    }

    public init(_ task: () throws -> T) {
        do {
            self = try .success(task())
        } catch {
            self = .failure(error)
        }
    }
    
    public func isSuccess() -> Bool {
        switch self {
        case .success:
            return true
        case .failure:
            return false
        }
    }
    
    public func isFailure() -> Bool {
        switch self {
        case .success:
            return false
        case .failure:
            return true
        }
    }

    // MARK: Combinators

    public func map<M>(_ mapping: (T) throws -> M) -> Try<M> {
        switch self {
        case .success(let value):
            do {
                return try Try<M>(mapping(value))
            } catch {
                return Try<M>(error)
            }
        case .failure(let error):
            return Try<M>(error)
        }
    }
    
    public func flatMap<M>(_ mapping: (T) throws -> Try<M>) -> Try<M> {
        switch self {
        case .success(let value):
            do {
                return try mapping(value)
            } catch {
                return Try<M>(error)
            }
        case .failure(let error):
            return Try<M>(error)
        }
    }

    public func mapError(_ mapping: (Swift.Error) -> Swift.Error) -> Try<T> {
        switch self {
        case .success(let value):
            return Try(value)
        case .failure(let error):
            return Try(mapping(error))
        }
    }
    
    public func recover(_ recovery: (Swift.Error) throws -> T) -> Try<T> {
        switch self {
        case .success(let value):
            return Try(value)
        case .failure(let error):
            do {
                return try Try(recovery(error))
            } catch {
                return Try(error)
            }
        }
    }

    public func recoverWith(_ recovery: (Swift.Error) throws -> Try<T>) -> Try<T> {
        switch self {
        case .success(let value):
            return Try(value)
        case .failure(let error):
            do {
                return try recovery(error)
            } catch {
                return Try(error)
            }
        }
    }
    
    public func filter(_ predicate: (T) throws -> Bool) -> Try<T> {
        switch self {
        case .success(let value):
            do {
                if try !predicate(value) {
                    return Try<T>(FuturesError.noSuchElement)
                } else {
                    return .success(value)
                }
            } catch {
                return Try<T>(error)
            }
        case .failure(_):
            return self
        }
    }
    
    public func forEach(_ apply: (T) throws -> Void) {
        switch self {
        case .success(let value):
            do {
                try apply(value)
            } catch {
                return
            }
        case .failure:
            return
        }
    }

    public func orElse(_ failed: Try<T>) -> Try<T> {
        switch self {
        case .success(let value):
            return Try(value)
        case .failure(_):
            return failed
        }
    }

    // MARK: Coversion

    public func toOptional() -> Optional<T> {
        switch self {
        case .success(let value):
            return Optional<T>(value)
        case .failure(_):
            return Optional<T>.none
        }
    }
    
    public func getOrElse(_ failed: T) -> T {
        switch self {
        case .success(let value):
            return value
        case .failure(_):
            return failed
        }
    }

}

public func ??<T>(left: Try<T>, right: T) -> T {
    return left.getOrElse(right)
}

// MARK: - Try SequenceType -

extension Sequence where Iterator.Element: Tryable {

    public func sequence() -> Try<[Iterator.Element.T]> {
        return reduce(Try([])) { accumulater, element  in
            switch accumulater {
            case .success(let value):
                return element.map { value + [$0] }
            case .failure:
                return accumulater
            }
        }
    }
}

// MARK: - ExecutionContext -

public protocol ExecutionContext {

    func execute(_ task: @escaping () -> Void)

}

public class ImmediateContext : ExecutionContext {

    public init() {}
    public func execute(_ task: @escaping () -> Void) {
        task()
    }

}

public struct QueueContext : ExecutionContext {

    public static var futuresDefault = QueueContext.main
    public static let main = QueueContext(queue: Queue.main)
    public static let global = QueueContext(queue: Queue.global)
    public let queue: Queue

    public init(queue: Queue) {
        self.queue = queue
    }

    public func execute(_ task: @escaping () -> Void) {
        queue.async(task)
    }

}

public struct MaxStackDepthContext : ExecutionContext {

    static let taskDepthKey = "us.gnos.taskDepthKey"
    let maxDepth: Int

    init(maxDepth: Int = 20) {
        self.maxDepth = maxDepth
    }

    public func execute(_ task: @escaping () -> Void) {
        let localThreadDictionary = Thread.current.threadDictionary
        let previousDepth = localThreadDictionary[MaxStackDepthContext.taskDepthKey] as? Int ?? 0
        if previousDepth < maxDepth {
            localThreadDictionary[MaxStackDepthContext.taskDepthKey] = previousDepth + 1
            task()
            localThreadDictionary[MaxStackDepthContext.taskDepthKey] = previousDepth
        } else {
            QueueContext.global.execute(task)
        }
    }

}

// MARK: - Queue -

public struct Queue {

    public static let main = Queue(DispatchQueue.main);
    public static let global = Queue(DispatchQueue.global(qos: .background))

    public let queue: DispatchQueue
    
    public init(_ queueName: String) {
        self.queue = DispatchQueue(label: queueName, qos: .background)
    }
    
    public init(_ queue: DispatchQueue) {
        self.queue = queue
    }
    
    public func sync(_ block: @escaping () -> Void) {
        queue.sync(execute: block)
    }
    
    public func sync<T>(_ block: @escaping () -> T) -> T {
        return queue.sync(execute: block);
    }
    
    public func async(_ block:  @escaping () -> Void) {
        queue.async(execute: block);
    }
    
    public func delay(_ delay: TimeInterval, request: @escaping () -> Void) {
        let popTime = DispatchTime.now() + Double(Int64(Float(delay)*Float(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        queue.asyncAfter(deadline: popTime, execute: request)
    }

}

// MARK: - CompletionId -

public struct CompletionId : Hashable {

    let identifier = UUID()

    public var hashValue: Int {
        return identifier.hashValue
    }

}

public func ==(lhs: CompletionId, rhs: CompletionId) -> Bool {

    return lhs.identifier == rhs.identifier

}

// MARK: - CancelToken -

public struct CancelToken {

    let completionId = CompletionId()

    public init() { }

}

// MARK: - Futurable -

public protocol Futurable {
    associatedtype T

    var result: Try<T>? { get }

    init()
    init(value: T)
    init(error: Swift.Error)
    init(context: ExecutionContext, dependent: Self)

    func complete(_ result: Try<T>)
    func onComplete(context: ExecutionContext, cancelToken: CancelToken, completion: @escaping (Try<T>) -> Void) -> Void

}

public extension Futurable {

    //MARK: - Combinators -

    public func map<M>(context: ExecutionContext = QueueContext.futuresDefault, cancelToken: CancelToken = CancelToken(), mapping: @escaping (T) throws -> M) -> Future<M> {
        let future = Future<M>()
        onComplete(context: context, cancelToken: cancelToken) { result in
            future.complete(result.map(mapping))
        }
        return future
    }

    public func flatMap<M>(context: ExecutionContext = QueueContext.futuresDefault, cancelToken: CancelToken = CancelToken(), mapping: @escaping (T) throws -> Future<M>) -> Future<M> {
        let future = Future<M>()
        onComplete(context: context, cancelToken: cancelToken) { result in
            future.completeWith(context: context, future: result.map(mapping))
        }
        return future
    }

    public func withFilter(context: ExecutionContext = QueueContext.futuresDefault, cancelToken: CancelToken = CancelToken(), filter: @escaping (T) throws -> Bool) -> Future<T> {
        let future = Future<T>()
        onComplete(context: context, cancelToken: cancelToken) { result in
            future.complete(result.filter(filter))
        }
        return future
    }

    public func forEach(context:ExecutionContext = QueueContext.futuresDefault, cancelToken: CancelToken = CancelToken(), apply: @escaping (T) -> Void) {
        onComplete(context: context, cancelToken: cancelToken) { result in
            result.forEach(apply)
        }
    }

    public func andThen(context: ExecutionContext = QueueContext.futuresDefault, cancelToken: CancelToken = CancelToken(), completion: @escaping (T) -> Void) -> Future<T> {
        let future = Future<T>()
        future.onSuccess(context: context, cancelToken: cancelToken, completion: completion)
        onComplete(context: context, cancelToken: cancelToken) { result in
            future.complete(result)
        }
        return future
    }

    public func recover(context: ExecutionContext = QueueContext.futuresDefault, cancelToken: CancelToken = CancelToken(), recovery: @escaping (Swift.Error) throws -> T) -> Future<T> {
        let future = Future<T>()
        onComplete(context: context, cancelToken: cancelToken) { result in
            future.complete(result.recover(recovery))
        }
        return future
    }

    public func recoverWith(context: ExecutionContext = QueueContext.futuresDefault, cancelToken: CancelToken = CancelToken(), recovery: @escaping (Swift.Error) throws -> Future<T>) -> Future<T> {
        let future = Future<T>()
        self.onComplete(context: context, cancelToken: cancelToken) { result in
            switch result {
            case .success(let value):
                future.success(value)
            case .failure(let error):
                do {
                    try future.completeWith(context: context, future: recovery(error))
                } catch {
                    future.failure(error)
                }
            }
        }
        return future
    }

    public func mapError(context: ExecutionContext = QueueContext.futuresDefault, cancelToken: CancelToken = CancelToken(), mapping: @escaping (Swift.Error) -> Swift.Error) -> Future<T> {
        let future = Future<T>()
        onComplete(context: context, cancelToken: cancelToken) { result in
            future.complete(result.mapError(mapping))
        }
        return future
    }

}

// MARK: - Promise -

public final class Promise<T> {

    public let future: Future<T>
    
    public var completed: Bool {
        return future.completed
    }
    
    public init() {
        self.future = Future<T>()
    }

    public func completeWith(context: ExecutionContext = QueueContext.futuresDefault, future: Future<T>) {
        self.future.completeWith(context: context, future: future)
    }
    
    public func complete(_ result: Try<T>) {
        future.complete(result)
    }
    
    public func success(_ value: T) {
        future.success(value)
    }

    public func failure(_ error: Swift.Error)  {
        future.failure(error)
    }

}

// MARK: - Future -

public final class Future<T> : Futurable {

    typealias OnComplete = (Try<T>) -> Void
    private var savedCompletions = [CompletionId : [OnComplete]]()
    private let queue = Queue("us.gnos.simpleFutures.main")

    public private(set) var result: Try<T>? {
        willSet {
            assert(self.result == nil)
        }
    }

    public var completed: Bool {
        return result != nil
    }

    public init() {}

    public init(value: T) {
        self.result = Try(value)
    }

    public init(context: ExecutionContext = QueueContext.futuresDefault, dependent: Future<T>) {
        completeWith(context: context, future: dependent)
    }

    public init(error: Swift.Error) {
        self.result = Try(error)
    }

    public init(resolver: (@escaping (Try<T>) -> Void) -> Void) {
        resolver { value in
            self.complete(value)
        }
    }

    // MARK: Complete

    public func complete(_ result: Try<T>) {
        self.result = result
        queue.sync {
            self.savedCompletions.values.forEach { completions in
                completions.forEach { $0(result) }
            }
            self.savedCompletions.removeAll()
        }
    }

    public func success(_ value: T) {
        complete(Try(value))
    }

    public func failure(_ error: Swift.Error) {
        complete(Try<T>(error))
    }

    public func completeWith(context: ExecutionContext = QueueContext.futuresDefault, future: Future<T>) {
        future.onComplete(context: context) { result in
            self.complete(result)
        }
    }

    public func completeWith(context: ExecutionContext = QueueContext.futuresDefault, stream: FutureStream<T>) {
        stream.onComplete(context: context) { result in
            self.complete(result)
        }
    }

    public func completeWith(context: ExecutionContext = QueueContext.futuresDefault, future: Try<Future<T>>) {
        switch future {
        case .success(let future):
            future.onComplete(context: context) { result in
                self.complete(result)
            }
        case .failure(let error):
            failure(error)
        }
    }

    // MARK: Callbacks

    public func onComplete(context: ExecutionContext = QueueContext.futuresDefault, cancelToken: CancelToken = CancelToken(), completion: @escaping (Try<T>) -> Void) -> Void {
        let savedCompletion : OnComplete = { result in
            context.execute {
                completion(result)
            }
        }
        if let result = result {
            savedCompletion(result)
        } else {
            queue.sync {
                if let completions = self.savedCompletions[cancelToken.completionId] {
                    self.savedCompletions[cancelToken.completionId] = completions + [savedCompletion]
                } else {
                    self.savedCompletions[cancelToken.completionId] = [savedCompletion]
                }
            }
        }
    }
    
    public func onSuccess(context: ExecutionContext = QueueContext.futuresDefault, cancelToken: CancelToken = CancelToken(), completion: @escaping (T) -> Void){
        onComplete(context: context, cancelToken: cancelToken) { result in
            switch result {
            case .success(let value):
                completion(value)
            default:
                break
            }
        }
    }
    
    public func onFailure(context: ExecutionContext = QueueContext.futuresDefault, cancelToken: CancelToken = CancelToken(), completion: @escaping (Swift.Error) -> Void) {
        onComplete(context: context, cancelToken: cancelToken) { result in
            switch result {
            case .failure(let error):
                completion(error)
            default:
                break
            }
        }
    }

    public func cancel(_ cancelToken: CancelToken) -> Bool {
        return queue.sync {
            guard let _ = self.savedCompletions.removeValue(forKey: cancelToken.completionId) else {
                return false
            }
            return true
        }
    }

    // MARK: FutureStream Combinators

    public func flatMap<M>(capacity: Int = Int.max, context: ExecutionContext = QueueContext.futuresDefault, cancelToken: CancelToken = CancelToken(), mapping: @escaping (T) throws -> FutureStream<M>) -> FutureStream<M> {
        let stream = FutureStream<M>(capacity: capacity)
        onComplete(context: context, cancelToken: cancelToken) { result in
            stream.completeWith(context: context, stream: result.map(mapping))
        }
        return stream
    }
    
    public func recoverWith(capacity: Int = Int.max, context: ExecutionContext = QueueContext.futuresDefault, cancelToken: CancelToken = CancelToken(), recovery: @escaping (Swift.Error) throws -> FutureStream<T>) -> FutureStream<T> {
        let stream = FutureStream<T>(capacity: capacity)
        onComplete(context: context, cancelToken: cancelToken) { result in
            switch result {
            case .success(let value):
                stream.success(value)
            case .failure(let error):
                do {
                    try stream.completeWith(context: context, stream: recovery(error))
                } catch {
                    stream.failure(error)
                }
            }
        }
        return stream
    }

}

// MARK: - future -

public func future<T>( _ task: @autoclosure @escaping () -> T) -> Future<T> {
    return future(context: ImmediateContext(), task)
}

public func future<T>(context: ExecutionContext = QueueContext.futuresDefault, _ task: @escaping () throws -> T) -> Future<T> {
    let future = Future<T>()
    context.execute {
        future.complete(Try(task))
    }
    return future
}

public func future<T>(method: ((T?, Swift.Error?) -> Void) -> Void) -> Future<T> {
    return Future(resolver: { completion in
        method { value, error in
            if let value = value {
                completion(.success(value))
            } else if let error = error {
                completion(.failure(error))
            } else {
                completion(.failure(FuturesError.invalidValue))
            }
        }
    })
}


public func future(method: ((Swift.Error?) -> Void) -> Void) -> Future<Void> {
    return Future(resolver: { completion in
        method { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    })
}

public func future<T>(method: ((T) -> Void) -> Void) -> Future<T> {
    return Future(resolver: { completion in
        method { value in
            completion(.success(value))
        }
    })
}

public func ??<T>(lhs: Future<T>, rhs: @autoclosure @escaping  () throws -> T) -> Future<T> {
    return lhs.recover { _ in
        return try rhs()
    }
}

public func ??<T>(lhs: Future<T>, rhs: @autoclosure @escaping () throws -> Future<T>) -> Future<T> {
    return lhs.recoverWith { _ in
        return try rhs()
    }
}

// MARK: - Future SequenceType -

extension Sequence where Iterator.Element : Futurable {

    public func fold<R>(context: ExecutionContext = QueueContext.futuresDefault, initial: R,  combine: @escaping (R, Iterator.Element.T) throws -> R) -> Future<R> {
        return reduce(Future<R>(value: initial)) { accumulator, element in
            accumulator.flatMap(context: MaxStackDepthContext()) { accumulatorValue in
                return element.map(context: context) { elementValue in
                    return try combine(accumulatorValue, elementValue)
                }
            }
        }
    }

    public func sequence(context: ExecutionContext = QueueContext.futuresDefault) -> Future<[Iterator.Element.T]> {
        return traverse(context: context) { $0 }
    }
}

extension Sequence {

    public func traverse<U, F: Futurable>(context: ExecutionContext = QueueContext.futuresDefault, mapping: (Iterator.Element) -> F) -> Future<[U]> where F.T == U {
        return map(mapping).fold(context: context, initial: [U]()) { accumulator, element in
            return accumulator + [element]
        }
    }

}

// MARK: - StreamPromise -

public final class StreamPromise<T> {

    public let stream: FutureStream<T>
    
    public init(capacity: Int = Int.max) {
        stream = FutureStream<T>(capacity: capacity)
    }
    
    public func complete(_ result: Try<T>) {
        stream.complete(result)
    }
    
    public func success(_ value: T) {
        stream.success(value)
    }
    
    public func failure(_ error: Swift.Error) {
        stream.failure(error)
    }
    
    public func completeWith(context: ExecutionContext = QueueContext.futuresDefault, future: Future<T>) {
        stream.completeWith(context: context, future: future)
    }

    public func completeWith(context: ExecutionContext = QueueContext.futuresDefault, stream: FutureStream<T>) {
        self.stream.completeWith(context: context, stream: stream)
    }

}

// MARK: - FutureStream -

public final class FutureStream<T> {

    public private(set) var futures = [Future<T>]()

    private typealias InFuture = (Future<T>) -> Void
    private var savedCompletions = [CompletionId : [InFuture]]()
    let queue = Queue("us.gnos.simpleFuturesStreams.main")

    private let capacity: Int

    public var count: Int {
        return futures.count
    }
    
    public init(capacity: Int = Int.max) {
        self.capacity = capacity
    }

    public convenience init(capacity: Int = Int.max, context: ExecutionContext = QueueContext.futuresDefault, dependent: FutureStream<T>) {
        self.init(capacity: capacity)
        completeWith(context: context, stream: dependent)
    }

    public convenience init(value: T, capacity: Int = Int.max) {
        self.init(capacity: capacity)
        success(value)
    }

    public convenience init(error: Swift.Error, capacity: Int = Int.max) {
        self.init(capacity: capacity)
        failure(error)
    }


    // MARK: Callbacks

    func complete(_ result: Try<T>) {
        let future = Future<T>()
        future.complete(result)
        queue.sync {
            if self.futures.count >= self.capacity  {
                self.futures.remove(at: 0)
            }
            self.futures.append(future)
            self.savedCompletions.values.forEach { completions in
                completions.forEach { $0(future) }
            }
        }
    }

    func success(_ value: T) {
        complete(Try(value))
    }

    func failure(_ error: Swift.Error) {
        complete(Try<T>(error))
    }

    func completeWith(context: ExecutionContext = QueueContext.futuresDefault, stream: FutureStream<T>) {
        stream.onComplete(context: context) { result in
            self.complete(result)
        }
    }

    func completeWith(context: ExecutionContext = QueueContext.futuresDefault, future: Future<T>) {
        future.onComplete(context: context) {result in
            self.complete(result)
        }
    }

    public func completeWith(context: ExecutionContext = QueueContext.futuresDefault, stream: Try<FutureStream<T>>) {
        switch stream {
        case .success(let stream):
            stream.onComplete(context: context) { result in
                self.complete(result)
            }
        case .failure(let error):
            failure(error)
        }
    }

    public func completeWith(context: ExecutionContext = QueueContext.futuresDefault, future: Try<Future<T>>) {
        switch future {
        case .success(let future):
            future.onComplete(context: context) { result in
                self.complete(result)
            }
        case .failure(let error):
            failure(error)
        }
    }

    // MARK: Callbacks

    public func onComplete(context: ExecutionContext = QueueContext.futuresDefault, cancelToken: CancelToken = CancelToken(), completion: @escaping (Try<T>) -> Void) {
        let futureComplete : InFuture = { future in
            future.onComplete(context: context, completion: completion)
        }
        queue.sync {
            if let completions = self.savedCompletions[cancelToken.completionId] {
                self.savedCompletions[cancelToken.completionId] = completions + [futureComplete]
            } else {
                self.savedCompletions[cancelToken.completionId] = [futureComplete]
            }
            self.futures.forEach { futureComplete($0) }
        }
    }

    public func onSuccess(context:ExecutionContext = QueueContext.futuresDefault, cancelToken: CancelToken = CancelToken(), completion: @escaping (T) -> Void) {
        onComplete(context: context, cancelToken: cancelToken) { result in
            switch result {
            case .success(let value):
                completion(value)
            default:
                break
            }
        }
    }
    
    public func onFailure(context: ExecutionContext = QueueContext.futuresDefault, cancelToken: CancelToken = CancelToken(), completion: @escaping (Swift.Error) -> Void) {
        onComplete(context: context, cancelToken: cancelToken) { result in
            switch result {
            case .failure(let error):
                completion(error)
            default:
                break
            }
        }
    }

    public func cancel(_ cancelToken: CancelToken) -> Bool {
        return queue.sync {
            guard let _ = self.savedCompletions.removeValue(forKey: cancelToken.completionId) else {
                return false
            }
            return true
        }
    }

    // MARK: Combinators

    public func map<M>(context: ExecutionContext = QueueContext.futuresDefault, cancelToken: CancelToken = CancelToken(), mapping: @escaping (T) throws -> M) -> FutureStream<M> {
        let stream = FutureStream<M>(capacity: capacity)
        onComplete(context: context, cancelToken: cancelToken) { result in
            stream.complete(result.map(mapping))
        }
        return stream
    }
    
    public func flatMap<M>(context: ExecutionContext = QueueContext.futuresDefault, cancelToken: CancelToken = CancelToken(), mapping: @escaping (T) throws -> FutureStream<M>) -> FutureStream<M> {
        let stream = FutureStream<M>(capacity: capacity)
        onComplete(context: context, cancelToken: cancelToken) { result in
            stream.completeWith(context: context, stream: result.map(mapping))
        }
        return stream
    }
    
    public func recover(context: ExecutionContext = QueueContext.futuresDefault, cancelToken: CancelToken = CancelToken(), recovery: @escaping (Swift.Error) throws -> T) -> FutureStream<T> {
        let stream = FutureStream<T>(capacity: capacity)
        onComplete(context: context, cancelToken: cancelToken) { result in
            stream.complete(result.recover(recovery))
        }
        return stream
    }
    
    public func recoverWith(context: ExecutionContext = QueueContext.futuresDefault, cancelToken: CancelToken = CancelToken(), recovery: @escaping (Swift.Error) throws -> FutureStream<T>) -> FutureStream<T> {
        let stream = FutureStream<T>(capacity: capacity)
        onComplete(context: context, cancelToken: cancelToken) { result in
            switch result {
            case .success(let value):
                stream.success(value)
            case .failure(let error):
                do {
                    try stream.completeWith(context: context, stream: recovery(error))
                } catch {
                    stream.failure(error)
                }
            }
        }
        return stream
    }
    
    public func withFilter(context: ExecutionContext = QueueContext.futuresDefault, cancelToken: CancelToken = CancelToken(), filter: @escaping (T) throws  -> Bool) -> FutureStream<T> {
        let stream = FutureStream<T>(capacity: capacity)
        onComplete(context: context, cancelToken: cancelToken) { result in
            stream.complete(result.filter(filter))
        }
        return stream
    }
    
    public func forEach(context: ExecutionContext = QueueContext.futuresDefault, cancelToken: CancelToken = CancelToken(), apply: @escaping (T) -> Void) {
        onComplete(context: context, cancelToken: cancelToken) { result in
            result.forEach(apply)
        }
    }

    public func andThen(context: ExecutionContext = QueueContext.futuresDefault, cancelToken: CancelToken = CancelToken(), completion: @escaping (T) -> Void) -> FutureStream<T> {
        let stream = FutureStream<T>(capacity: capacity)
        stream.onSuccess(context: context, cancelToken: cancelToken, completion: completion)
        onComplete(context: context, cancelToken: cancelToken) { result in
            stream.complete(result)
        }
        return stream
    }

    public func mapError(context: ExecutionContext = QueueContext.futuresDefault, cancelToken: CancelToken = CancelToken(), mapping: @escaping (Swift.Error) -> Swift.Error) -> FutureStream<T> {
        let stream = FutureStream<T>(capacity: capacity)
        onComplete(context: context, cancelToken: cancelToken) { result in
            stream.complete(result.mapError(mapping))
        }
        return stream
    }

    // MARK: Future Combinators

    public func flatMap<M>(context: ExecutionContext = QueueContext.futuresDefault, cancelToken: CancelToken = CancelToken(), mapping: @escaping (T) throws  -> Future<M>) -> FutureStream<M> {
        let stream = FutureStream<M>(capacity: capacity)
        onComplete(context: context, cancelToken: cancelToken) { result in
            stream.completeWith(context: context, future: result.map(mapping))
        }
        return stream
    }
    
    public func recoverWith(context: ExecutionContext = QueueContext.futuresDefault, cancelToken: CancelToken = CancelToken(), recovery: @escaping (Swift.Error) throws  -> Future<T>) -> FutureStream<T> {
        let stream = FutureStream<T>(capacity: capacity)
        onComplete(context: context, cancelToken: cancelToken) { result in
            switch result {
            case .success(let value):
                stream.success(value)
            case .failure(let error):
                do {
                    try stream.completeWith(context: context, future: recovery(error))
                } catch {
                    stream.failure(error)
                }
            }
        }
        return stream
    }

}

