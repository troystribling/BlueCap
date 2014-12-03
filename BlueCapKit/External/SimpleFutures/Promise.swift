//
//  Promise.swift
//  BlueCapKit
//
//  Created by Troy Stribling on 12/3/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation

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
