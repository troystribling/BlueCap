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

// swap
func uint16LittleToHost(value:UInt16) -> UInt16 {
    return value;
}

func uint16HostToLittle(value:UInt16) -> UInt16 {
    return value;
}

func uint16BigToHost(value:UInt16) -> UInt16 {
    return (value << 8) | (value >> 8);
}

func uint16HostToBig(value:UInt16) -> UInt16 {
    return (value << 8) | (value >> 8);
}

func int16LittleToHost(value:Int16) -> Int16 {
    return value;
}

func int16HostToLittle(value:Int16) -> Int16 {
    return value;
}

func int16BigToHost(value:Int16) -> Int16 {
    return (value << 8) | (value >> 8);
}

func int16HostToBig(value:Int16) -> Int16 {
    return (value << 8) | (value >> 8);
}

extension NSData {
    
    // Byte
    convenience init(byte value:Byte) {
        self.init(bytes:[value], length:1)
    }
    
    convenience init(bytes values:Byte[]) {
        self.init(bytes:values, length:values.count)
    }
    
    func byteValue() -> Byte {
        var value : Byte = 0
        self.getBytes(&value, length:1)
        return value
    }

    func byteValue(start:Int) -> Byte {
        var value : Byte = 0
        self.getBytes(&value, range: NSMakeRange(start, 1))
        return value
    }

    // Int8
    convenience init(int8 value:Int8) {
        self.init(bytes:[value], length:1)
    }

    convenience init(int8s values:Int8[]) {
        self.init(bytes:values, length:values.count)
    }
    
    func int8Value() -> Int8 {
        var value : Int8 = 0
        self.getBytes(&value, length:1)
        return value
    }
    
    func int8Value(start:Int) -> Int8 {
        var value : Int8 = 0
        self.getBytes(&value, range: NSMakeRange(start, 1))
        return value
    }

    // UInt16
    convenience init(uint16ToLittle value:UInt16) {
        self.init(bytes:[uint16HostToLittle(value)], length:1)
    }
    
    convenience init(uint16ArrayToLittle values:UInt16[]) {
        let littleValues = values.map{value in uint16HostToLittle(value)}
        self.init(bytes:littleValues, length:2*littleValues.count)
    }
    
    func uint16FromLittleValue() -> UInt16 {
        var value : UInt16 = 0
        self.getBytes(&value, length:2)
        return uint16LittleToHost(value)
    }
    
    func uint16FromLittleValue(start:Int) -> UInt16 {
        var value : UInt16 = 0
        self.getBytes(&value, range:NSMakeRange(start, 2))
        return uint16LittleToHost(value)
    }
    
    convenience init(uint16ToBig value:UInt16) {
        self.init(bytes:[uint16HostToBig(value)], length:2)
    }
    
    convenience init(uint16ArrayToBig values:UInt16[]) {
        let bigValues = values.map{value in uint16HostToBig(value)}
        self.init(bytes:bigValues, length:2*bigValues.count)
    }
    
    func uint16FromBigValue() -> UInt16 {
        var value : UInt16 = 0
        self.getBytes(&value, length:2)
        return uint16BigToHost(value)
    }
    
    func uint16FromBigValue(start:Int) -> UInt16 {
        var value : UInt16 = 0
        self.getBytes(&value, range:NSMakeRange(start, 2))
        return uint16BigToHost(value)
    }
    
    // Int16
    convenience init(int16ToLittle value:Int16) {
        self.init(bytes:[int16HostToLittle(value)], length:2)
    }
    
    convenience init(int16ArrayToLittle values:Int16[]) {
        let littleValues = values.map{value in int16HostToLittle(value)}
        self.init(bytes:littleValues, length:2*littleValues.count)
    }
    
    func int16FromLittleValue() -> Int16 {
        var value : Int16 = 0
        self.getBytes(&value, length: 2)
        return int16LittleToHost(value)
    }
    
    func int16FromLittleValue(start:Int) -> Int16 {
        var value : Int16 = 0
        self.getBytes(&value, range:NSMakeRange(start,2))
        return int16LittleToHost(value)
    }
    
    convenience init(int16ToBig value:Int16) {
        self.init(bytes:[int16HostToBig(value)], length:2)
    }
    
    convenience init(int16ArrayToBig values:Int16[]) {
        let bigValues = values.map{value in int16HostToBig(value)}
        self.init(bytes:bigValues, length:2*bigValues.count)
    }
    
    func int16FromBigValue() -> Int16 {
        var value : Int16 = 0
        self.getBytes(&value, length:2)
        return int16BigToHost(value)
    }
    
    func int16FromBigValue(start:Int) -> Int16 {
        var value : Int16 = 0
        self.getBytes(&value, range:NSMakeRange(start,2))
        return int16BigToHost(value)
    }
    
    // string value
    func hexStringValue() -> String {
        var dataBytes = Array<Byte>(count:self.length, repeatedValue:0x0)
        self.getBytes(&dataBytes, length:self.length)
        var hexString = dataBytes.reduce(""){(out:String, dataByte:Byte) in
            out +  NSString(format:"%02lx", dataByte)
        }
        return hexString
    }
}

var test = NSData(int16ToBig:(-101))
test.hexStringValue()
println(test.int16FromBigValue())
