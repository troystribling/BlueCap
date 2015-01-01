//
//  Try.swift
//  Wrappers
//
//  Created by Troy Stribling on 12/21/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation

public struct TryError {
    public static let domain = "Wrappers"
    public static let filterFailed = NSError(domain:domain, code:1, userInfo:[NSLocalizedDescriptionKey:"Filter failed"])
}

public enum Try<T> {

    case Success(Box<T>)
    case Failure(NSError)
    
    public init(_ value:T) {
        self = .Success(Box(value))
    }

    public init(_ value:Box<T>) {
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
        case .Success(let box):
            return Try<M>(box.map(mapping))
        case .Failure(let error):
            return Try<M>(error)
        }
    }
    
    public func flatmap<M>(mapping:T -> Try<M>) -> Try<M> {
        switch self {
        case .Success(let box):
            return mapping(box.value)
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
        case .Success(let box):
            return Try(box)
        case .Failure(let error):
            return recovery(error)
        }
    }
    
    public func filter(predicate:T -> Bool) -> Try<T> {
        switch self {
        case .Success(let box):
            if !predicate(box.value) {
                return Try<T>(TryError.filterFailed)
            } else {
                return Try(box)
            }
        case .Failure(let error):
            return self
        }
    }
    
    public func foreach(apply:T -> Void) {
        switch self {
        case .Success(let box):
            apply(box.value)
        case .Failure:
            return
        }
    }
    
    public func toOptional() -> Optional<T> {
        switch self {
        case .Success(let box):
            return Optional<T>(box.value)
        case .Failure(let error):
            return Optional<T>()
        }
    }
    
    public func getOrElse(failed:T) -> T {
        switch self {
        case .Success(let box):
            return box.value
        case .Failure(let error):
            return failed
        }
    }
    
    public func orElse(failed:Try<T>) -> Try<T> {
        switch self {
        case .Success(let box):
            return Try(box)
        case .Failure(let error):
            return failed
        }
    }
    
}

public func flatten<T>(try:Try<Try<T>>) -> Try<T> {
    switch try {
    case .Success(let box):
        return box.value
    case .Failure(let error):
        return Try<T>(error)
    }
}

public func forcomp<T,U>(f:Try<T>, g:Try<U>, #apply:(T,U) -> Void) {
    f.foreach {fvalue in
        g.foreach {gvalue in
            apply(fvalue, gvalue)
        }
    }
}

public func forcomp<T,U,V>(f:Try<T>, g:Try<U>, h:Try<V>, #apply:(T,U,V) -> Void) {
    f.foreach {fvalue in
        g.foreach {gvalue in
            h.foreach {hvalue in
                apply(fvalue, gvalue, hvalue)
            }
        }
    }
}

public func forcomp<T,U,V>(f:Try<T>, g:Try<U>, #yield:(T,U) -> V) -> Try<V> {
    return f.flatmap {fvalue in
        g.map {gvalue in
            yield(fvalue, gvalue)
        }
    }
}

public func forcomp<T,U,V,W>(f:Try<T>, g:Try<U>, h:Try<V>, #yield:(T,U,V) -> W) -> Try<W> {
    return f.flatmap {fvalue in
        g.flatmap {gvalue in
            h.map {hvalue in
                yield(fvalue, gvalue, hvalue)
            }
        }
    }
}

public func forcomp<T,U>(f:Try<T>, g:Try<U>, #filter:(T,U) -> Bool, #apply:(T,U) -> Void) {
    f.foreach {fvalue in
        g.filter{gvalue in
            filter(fvalue, gvalue)
            }.foreach {gvalue in
                apply(fvalue, gvalue)
        }
    }
}

public func forcomp<T,U,V>(f:Try<T>, g:Try<U>, h:Try<V>, #filter:(T,U,V) -> Bool, #apply:(T,U,V) -> Void) {
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

public func forcomp<T,U,V>(f:Try<T>, g:Try<U>, #filter:(T,U) -> Bool, #yield:(T,U) -> V) -> Try<V> {
    return f.flatmap {fvalue in
        g.filter {gvalue in
            filter(fvalue, gvalue)
            }.map {gvalue in
                yield(fvalue, gvalue)
        }
    }
}

public func forcomp<T,U,V,W>(f:Try<T>, g:Try<U>, h:Try<V>, #filter:(T,U,V) -> Bool, #yield:(T,U,V) -> W) -> Try<W> {
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

