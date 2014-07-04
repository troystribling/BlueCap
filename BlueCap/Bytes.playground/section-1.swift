// Playground - noun: a place where people can play

import Foundation

var bytes : Byte[] = [0xFF, 0x10, 0xaf]
var data = NSData(bytes:bytes, length: 3)
data.length
var dataBytes = Array<Byte>(count:3, repeatedValue:0x0)
data.getBytes(&dataBytes, length:3)
dataBytes.reduce(""){(out:String, byte:Byte) in
     return out + NSString(format:"%02lx", byte)
}

var allBytes : Byte[] = []
let clongBytes = strtol("0a", nil, 16)
let byte = Array<Byte>(count:1, repeatedValue:0)
allBytes += Byte(clongBytes)
let allData = NSData(bytes:allBytes, length:allBytes.count)
println(allData)
