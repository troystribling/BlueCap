// Playground - noun: a place where people can play
import Foundation
import CoreBluetooth

// function types
var a : (()->())?
func heyYou(){println("Hey You")}
a = heyYou

if (a) {
    a!()
} else {
    println("a undefined")
}

class FuncCheck {
    var f:(()->())?
    func setF(f:()->()){self.f = f}
    func callF() {
        if self.f {
            self.f!()
        } else {
            println("f is undefined")
        }
    }
}

var fc = FuncCheck()
fc.callF()
fc.setF({println("Hey It Works")})
fc.callF()

class Junk {
    let v = 2
}

var f1 : ((j:Junk) -> Int)?
var f2 : ((j:Junk, s:String) -> String)?

func addOne(j:Junk) -> Int {
    return j.v+1
}

func addOnePlus(j:Junk, s:String!) -> String {
    println("addOnePlus")
    if s {
        println("Custom")
        return "\(s):\(j.v+1)"
    } else {
        println("Default")
        return "Default: \(j.v+1)"
    }
}

addOne(Junk())

f1 = addOne
f2 = addOnePlus

f1!(j:Junk())
f2!(j:Junk(), s:"Test")

var x = ["1":"a", "2":"b", "3":"c"]
Array(x.values)

let cc : CBCharacteristicProperties = .Read
cc.toRaw() | CBCharacteristicProperties.Write.toRaw()
