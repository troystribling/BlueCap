// Playground - noun: a place where people can play

import UIKit

protocol DoinIt {
    func addVal(val:Int) -> Self
}

extension Int : DoinIt {
    func addVal(val: Int) -> Int {
        return self + val
    }
}

struct Thing<T : DoinIt> {
    let x = 2
    func doit(t:T) -> T {
        return t.addVal(2)
    }
}

let zz = Thing<Int>()

zz.doit(5)

