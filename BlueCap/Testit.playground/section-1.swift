// Playground - noun: a place where people can play

import UIKit

let a = [1,2,3,4]
a[0]
a[1...a.count-1]
a[a.count..<a.count]

func f(pred:@autoclosure()-> Bool) {
    if pred() {
        println("TRUE")
    } else {
        println("FALSE")
    }
}

f(2==3)
f(3 > 2)
f(2 > 3)


let z : Int! = nil
func x(b:Int?) {
    if let b = b {
        println(b)
    } else {
        println("It is nil")
    }
}

x(z)





