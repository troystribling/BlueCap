// Playground - noun: a place where people can play
import Foundation

// function types
var a : (()->())?
func heyYou(){println("Hey You")}
a = heyYou

if a != nil {
    a!()
} else {
    println("a undefined")
}

class FuncCheck {
    var f:(()->())?
    func setF(f:()->()){self.f = f}
    func callF() {
        if self.f != nil {
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
    if s != nil {
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

var z = {(value:Int) -> Int in
    return value + 3
}

z(3)

// store closues in dictionary
class Methods {
    var meths : Dictionary<Int, (Int)->Int> = [:]
    func addMeth(val:Int, meth:(Int)->Int) {
        meths[val] = meth
    }
}

var holder = Methods()
holder.addMeth(2){(value) in
    return value + 1
}
holder.addMeth(4){(value) in
    return value * 2
}
if let f = holder.meths[2] {
    f(2)
}
if let v = holder.meths[4] {
    v(4)
}

