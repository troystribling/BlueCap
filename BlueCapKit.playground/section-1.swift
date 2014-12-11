// Playground - noun: a place where people can play

import UIKit
import BlueCapKit

let hexStr = "10af22cc"
let hexData = hexStr.dataFromHexString()
hexData.hexStringValue()

class ResultWrapper<T> {
    let value : T
    init(_ value:T) {
        self.value = value
    }
}

enum Result<T> {
    case Success(ResultWrapper<T>)
    case Error(NSError)
    
    init(_ value:T) {
        self = .Success(ResultWrapper(value))
    }
    
    init (_ error:NSError) {
        self = .Error(error)
    }
}

let val = Result<Int>(2)

switch val {
case .Success(let result):
    println("result: \(result.value)")
case .Error(let error):
    println("error")
}

