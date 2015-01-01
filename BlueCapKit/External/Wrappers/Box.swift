//
//  Utilities.swift
//  Wrappers
//
//  Created by Troy Stribling on 12/21/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation

public final class Box<T> {
    
    public let value: T
    
    public init(_ value:T) {
        self.value = value
    }
    
    public func map<M>(mapping:T -> M) -> Box<M> {
        return Box<M>(mapping(self.value))
    }
    
    public func flatmap<M>(mapping:T -> Box<M>) -> Box<M> {
        return mapping(self.value)
    }
}

