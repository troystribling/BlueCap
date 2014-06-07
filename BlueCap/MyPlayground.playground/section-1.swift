// Playground - noun: a place where people can play
import Cocoa

// collections
var iarray : Int[] = []
iarray += 2
iarray += [3,4,5]
iarray.count
println(iarray)
println(iarray.count)

var idictionary : Dictionary<String, String> = [:]
idictionary["key1"] = "val1"
idictionary.count

// for loops
println("Array")
for v in iarray {
    println(v)
}
println("Enumerate")
for (i,v) in enumerate(iarray) {
    println("Index: \(i), Value: \(v)")
}
println("Exclusive Range")
for v in 0..4 {
    println(v)
}
println("Inclusive Range")
for v in 0...4 {
    println(v)
}
println("Disctionary")
for (k,v) in idictionary {
    println("key: \(k), value: \(v)")
}

// inheritance
class ClassTest {
    var a : Int
    var b : Int;
    init(a:Int) {
        self.a = a
        self.b = 0
    }
    init(setB b:Int) {
        self.b = b
        self.a = 1
    }
    convenience init() {
        self.init(a:2)
    }
    deinit {
        println("deinited")
    }
    func meth(c: Int) -> Int {
        return c + self.a + self.b
    }
    func meth(c:Int, withB:Int) -> Int {
        return c + self.a + withB
    }
}

class ChildTest : ClassTest {
    init(setB b: Int)  {
        super.init(a: 2)
        self.b = b
    }
    override func meth(c:Int) -> Int {
        return c*self.a*self.b
    }
}

var x = ClassTest(a:3)
var y = ClassTest()
var z = ClassTest(setB: 4)
var w = ChildTest(setB: 5)

x.meth(3)
x.meth(3, withB:10)
y.meth(5)
z.meth(5)
w.meth(6)

// class types
class ClassTypes {
    var data : Int[] = []
    class func sharedInstance() -> ClassTypes {
        if (!classTypes) {
             classTypes = ClassTypes()
        }
        return classTypes!;
    }
    func addData(a:Int) {
        self.data += a
    }
}

var classTypes : ClassTypes? = nil

let a = ClassTypes.sharedInstance()
a.addData(2)
a.data

// function external varaiable names
func thing(hasThis data: Int) -> Int[] {
    return [data]
}

println(thing(hasThis:3))

// function types
var f : (Int) -> Int

func addValues(a:Int) -> Int {return a + 3}
f = addValues
f(2)

func printResult(c:Int, b:(Int) -> Int) {
    println("Result: \(b(c))")
}

printResult(2,f)

var v : () -> ()
func printThing() {println("TheThing")}
v = printThing
func callStuff(b:()->()) {b()}
callStuff(v)

// Closure Expression Syntax
printResult(3, {(c:Int)->(Int) in return c*c})
printResult(2, {c in return c*c})
printResult(4, {$0 * $0})
printResult(10){$0 * $0}
printResult(8){(var c)->Int in return c+1}

callStuff({() -> () in println("Calling Stuff")})
callStuff({println("Did it again")})
callStuff(){println("One more time")}

// curring
func multiply(a:Int)(b:Int) -> Int {
    return a * b
}
multiply(4)(b:5)
var multi4 = multiply(4)
multi4(b: 6)

