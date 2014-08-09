// Playground - noun: a place where people can play

import Foundation

var bytes : [UInt8] = [0xFF, 0x10, 0xaf]
var data = NSData(bytes:bytes, length: 3)
data.length
var dataBytes = Array<UInt8>(count:3, repeatedValue:0x0)
data.getBytes(&dataBytes, length:3)
dataBytes.reduce(""){(out:String, byte:Byte) in
     return out + NSString(format:"%02lx", byte)
}

let clongBytes = strtol("0a", nil, 16)
let byte = Array<UInt8>(count:1, repeatedValue:0)
var allBytes = [UInt8(clongBytes)]
let allData = NSData(bytes:allBytes, length:allBytes.count)
println(allData)

let a = "012345"
a[1..<3]
