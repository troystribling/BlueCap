// Playground - noun: a place where people can play
import Foundation

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
        if (self.f) {
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

