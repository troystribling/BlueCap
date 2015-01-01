//
//  Optional.swift
//  Wrappers
//
//  Created by Troy Stribling on 12/21/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation

extension Optional {
    
    func flatmap<M>(mapping:T -> M?) -> M? {
        switch self {
        case .Some(let value):
            return mapping(value)
        case .None:
            return nil
        }
    }
    
    func filter(predicate:T -> Bool) -> T? {
        switch self {
        case .Some(let value):
            return predicate(value) ? Optional(value) : nil
        case .None:
            return Optional()
        }
    }

    func foreach(apply:T -> Void) {
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

public func forcomp<T,U>(f:T?, g:U?, #apply:(T,U) -> Void) {
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

public func forcomp<T,U,V>(f:T?, g:U?, h:V?, #apply:(T,U,V) -> Void) {
    f.foreach {fvalue in
        g.foreach {gvalue in
            h.foreach {hvalue in
                apply(fvalue, gvalue, hvalue)
            }
        }
    }
}

public func forcomp<T,U,V>(f:T?, g:U?, #yield:(T,U) -> V) -> V? {
    return f.flatmap {fvalue in
        g.map {gvalue in
            yield(fvalue, gvalue)
        }
    }
}

public func forcomp<T,U,V, W>(f:T?, g:U?, h:V?, #yield:(T,U,V) -> W) -> W? {
    return f.flatmap {fvalue in
        g.flatmap {gvalue in
            h.map {hvalue in
                yield(fvalue, gvalue, hvalue)
            }
        }
    }
}

public func forcomp<T,U>(f:T?, g:U?, #filter:(T,U) -> Bool, #apply:(T,U) -> Void) {
    f.foreach {fvalue in
        g.filter{gvalue in
            filter(fvalue, gvalue)
        }.foreach {gvalue in
            apply(fvalue, gvalue)
        }
    }
}

public func forcomp<T,U,V>(f:T?, g:U?, h:V?, #filter:(T,U,V) -> Bool, #apply:(T,U,V) -> Void) {
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

public func forcomp<T,U,V>(f:T?, g:U?, #filter:(T,U) -> Bool, #yield:(T,U) -> V) -> V? {
    return f.flatmap {fvalue in
        g.filter {gvalue in
            filter(fvalue, gvalue)
        }.map {gvalue in
            yield(fvalue, gvalue)
        }
    }
}

public func forcomp<T,U,V,W>(f:T?, g:U?, h:V?, #filter:(T,U,V) -> Bool, #yield:(T,U,V) -> W) -> W? {
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