// Playground - noun: a place where people can play

// Playground - noun: a place where people can play

import UIKit
import BlueCapKit

let x : [UInt16] = [122,6789]
let data = NSData.serialize(x)
data.hexStringValue()
let v : [UInt16] = Serde.deserialize(data)
println("\(v[0])")
v[0]




