## <a name="serde">Serialization/Deserialization</a>

Serialization and deserialization of device messages to and from `Data` objects requires `protocol` implementations that structurally define the message objects. Example implementations of each `protocol` can be found in the [TiSensorTag GATT Profile](/BlueCapKit/Service%20Profile%20Definitions/TISensorTagServiceProfiles.swift). Methods used for serialization and deserialization are class methods on `SerDe`. In the following sections an example for each `protocol` will be discussed. All of the examples shown here are available in a [Playground project](/Playgrounds).

## Contents

* [String](#serde_strings): String serialization and deserialization.
* [Deserializable Protocol](#serde_deserializable): Deserialize numeric types.
* [RawDeserializable Protocol](#serde_rawdeserializable): Deserialize messages with a single value of a single Deserializable type.
* [RawArrayDeserializable Protocol](#serde_rawarraydeserializable): Deserialize messages with multiple values of single Deserializable type.
* [RawPairDeserializable Protocol](#serde_rawpairdeserializable): Deserialize messages with two values of two different Deserializable types.
* [RawArrayPairDeserializable Protocol](#serde_rawarraypairdeserializable): Deserialize messages with multiple values of two different Deserializable types.

### <a name="serde_strings">Strings</a>

For Strings `SerDe` `serialize` and `deserialize` are defined by,

```swift
// Deserialize Strings
public static func deserialize(data: NSData, encoding: NSStringEncoding = NSUTF8StringEncoding) -> String?

// Serialize Strings
public static func serialize(value: String, encoding: NSStringEncoding = NSUTF8StringEncoding) -> NSData?
```

[NSStringEncoding](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSString_Class/#//apple_ref/c/tdef/NSStringEncoding) specifies the string encoding. 

to use in an application,

```swift
if let data = SerDe.serialize("Test") {
    if let value = SerDe.deserialize(data) {
        println(value)
    }
}
```

### <a name="serde_deserializable">Deserializable Protocol</a>

The `Deserializable` `protocol` is used for deserialization of numeric objects and is defined by,

```swift
public protocol Deserializable {
    // Size of object in bytes.
    static var size : Int { get }  
    // Deserialize entire message to object.
    static func deserialize(_ data: Data) -> Self?
    // Deserialize message starting at offset to object.
    static func deserialize(_ data: Data, start:Int) -> Self?
    // Deserialize entire message to array of objects.
    static func deserialize(_ data: Data) -> [Self]
}
```

BlueCalKit provides implementation of `Deserializable` for [UInt8](BlueCapKit/SerDe/Uint8Extensions.swift), [Int8](BlueCapKit/SerDe/Int8Extensions.swift), [UInt16](BlueCapKit/SerDe/UInt16Extensions.swift), [Int16](BlueCapKit/SerDe/Int16Extensions.swift), [Int32](BlueCapKit/SerDe/Int32Extensions.swift) and [UInt32](BlueCapKit/SerDe/UInt32Extensions.swift). The`SerDe` serialize and deserialize are defined by,

```swift
// Deserialize objects supporting Deserializable
public static func deserialize<T: Deserializable>(data: Data) -> T?

// Serialize objects supporting Deserializable
public static func serialize<T: Deserializable>(value: T) -> Data
```

For UInt8 data,

```swift
let data = SerDe.serialize(UInt8(31))
if let value : UInt8 = SerDe.deserialize(data) {
    print("\(value)")
}
```

### <a name="serde_rawdeserializable">RawDeserializable Protocol</a>

The `RawDeserializable` `protocol` is used for messages that contain a single value and is defined by,

```swift
public protocol RawDeserializable {
    associatedtype RawType
    // Characteristic UUID.
    static var uuid: String { get }
    // Characteristic RawType value.
    var rawValue: RawType { get }
    //Create object from rawValue.
    init?(rawValue: RawType)
}
```

The `SerDe` `serialize` and `deserialize` are defined by,

```swift
// Deserialize objects supporting RawDeserializable
public static func deserialize<T: RawDeserializable>(_ data: Data) -> T? where T.RawType: Deserializable

// Serialize objects supporting RawDeserializable
public static func serialize<T: RawDeserializable>(_ value: T) -> Data
```

Note that `RawType` is required to be `Deserializable`. An Enum partially supports `RawDeserializable`, so,

```swift
enum Enabled : UInt8, RawDeserializable {
    case No  = 0
    case Yes = 1
    static let uuid = "F000AA12-0451-4000-B000-000000000000"
}

let data2 = SerDe.serialize(Enabled.Yes)
if let value : Enabled = SerDe.deserialize(data2) {
    print("\(value.rawValue)")
}
```

`RawDeserializable` can also be implemented by a `struct` or `class`.

```swift
struct RawValue : RawDeserializable {
    
    let rawValue: UInt8
    static let uuid = "F000AA13-0451-4000-B000-000000000000"

    init?(rawValue:UInt8) {
        self.rawValue = rawValue
    }
}

if let initValue = RawValue(rawValue:10) {
    let data = SerDe.serialize(initValue)
    if let value : RawValue = SerDe.deserialize(data) {
        print("\(value.rawValue)")
    }
}
```

### <a name="serde_rawarraydeserializable">RawArrayDeserializable Protocol</a>

The `RawArrayDeserializable` `protocol` is used for messages that contain multiple values of a single type and is defined by,

```swift
public protocol RawArrayDeserializable {
    associatedtype RawType
    // Characteristic UUID.
    static var uuid: String { get }
    // Size of array.
    static var size: Int { get }
    // Characteristic RawType values.
    var rawValue: [RawType] { get }
    // Create object from rawValues.
    init?(rawValue: [RawType])
}
```

The`SerDe` `serialize` and `deserialize` are defined by,

```swift
// Deserialize objects supporting RawArrayDeserializable
public static func deserialize<T: RawArrayDeserializable>(_ data: Data) -> T? where T.RawType: Deserializable

// Serialize objects supporting RawArrayDeserializable
public static func serialize<T: RawArrayDeserializable>(_ value: T) -> Data
```

Note that `RawType` is required to be `Deserializable`. `RawArrayDeserializable` can be implemented in a `struct` or `class`.

```swift
struct RawArrayValue : RawArrayDeserializable {
    
    let rawValue: [UInt8]
    static let uuid: String = "F000AA13-0451-4000-B000-000000000000"
    
    static let size = 2
    
    init?(rawValue:[UInt8]) {
        if rawValue.count == 2 {
            self.rawValue = rawValue
        } else {
            return nil
        }
    }
}

if let initValue = RawArrayValue(rawValue:[4,10]) {
    let data = SerDe.serialize(initValue)
    if let value : RawArrayValue = SerDe.deserialize(data) {
        print("\(value.rawValue)")
    }
}
```

### <a name="serde_rawpairdeserializable">RawPairDeserializable Protocol</a>

The `RawPairDeserializable` `protocol` is used for messages that contain two values of different types and is defined by,

```swift
public protocol RawPairDeserializable {
    associatedtype RawType1
    associatedtype RawType2
    // Characteristic UUID.
    static var uuid: String { get }
    // Characteristic RawType1 value.
    var rawValue1: RawType1 { get }
    // Characteristic RawType2 value.
    var rawValue2: RawType2 { get }
    // Create object from rawValues.
    init?(rawValue1: RawType1, rawValue2: RawType2)
}
```

The `SerDe` `serialize` and `deserialize` are defined by,

```swift
// Deserialize objects supporting RawPairDeserializable
public static func deserialize<T: RawPairDeserializable where T.RawType1: Deserializable, T.RawType2: Deserializable>(data: NSData) -> T?

// Serialize objects supporting RawPairDeserializable
public static func serialize<T: RawPairDeserializable>(_ value: T) -> Data
```

Note that `RawType1` and `RawType2` are required to be `Deserializable`. `RawPairDeserializable` can be implemented in a struct or class.

```swift
struct RawPairValue : RawPairDeserializable {
    
    let rawValue1: UInt8
    let rawValue2: Int8
    static let uuid: String = "F000AA13-0451-4000-B000-000000000000"
    
    
    init?(rawValue1:UInt8, rawValue2:Int8) {
        self.rawValue1 = rawValue1
        self.rawValue2 = rawValue2
    }
}

if let initValue = RawPairValue(rawValue1: 10, rawValue2: -10) {
    let data = SerDe.serialize(initValue)
    if let value : RawPairValue = SerDe.deserialize(data) {
        print("\(value.rawValue1)")
        print("\(value.rawValue2)")
    }
}
```

### <a name="serde_rawarraypairdeserializable">RawArrayPairDeserializable Protocol</a>

The `RawArrayPairDeserializable` `protocol` is used to define a message that contains multiple values of two different types and is defined by,

```swift
public protocol RawArrayPairDeserializable {
    associatedtype RawType1
    associatedtype RawType2
    // Characteristic UUID.
    static var uuid: String { get }
    // Size of RawType1 array.
    static var size1: Int { get }
    // Size of RawType2 array.
    static var size2: Int { get }
    // Characteristic RawType1 value.
    var rawValue1: [RawType1] { get }
    // Characteristic RawType2 value.
    var rawValue2: [RawType2] { get }
    // Create object from rawValues.
    init?(rawValue1: [RawType1], rawValue2: [RawType2])
}
```

The `SerDe` serialize and deserialize are defined by,

```swift
// Deserialize objects supporting RawPairDeserializable
public static func deserialize<T: RawArrayPairDeserializable>(_ data: Data) -> T? where T.RawType1: Deserializable,  T.RawType2: Deserializable

// Deserialize objects supporting RawPairDeserializable
public static func serialize<T: RawArrayPairDeserializable>(_ value: T) -> Data
```

Note that `RawType1` and `RawType2` are required to be `Deserializable`. `RawArrayPairDeserializable` can be implemented in a struct or class.

```swift
struct RawArrayPairValue : RawArrayPairDeserializable {
    
    let rawValue1: [UInt8]
    let rawValue2: [Int8]
    static let uuid = "F000AA13-0451-4000-B000-000000000000"
    static let size1 = 2
    static let size2 = 2
    
    
    init?(rawValue1:[UInt8], rawValue2:[Int8]) {
        if rawValue1.count == 2 && rawValue2.count == 2 {
            self.rawValue1 = rawValue1
            self.rawValue2 = rawValue2
        } else {
            return nil
        }
    }
}

if let initValue = RawArrayPairValue(rawValue1:[10, 100], rawValue2:[-10, -100]) {
    let data = SerDe.serialize(initValue)
    if let value : RawArrayPairValue = SerDe.deserialize(data) {
        print("\(value.rawValue1)")
        print("\(value.rawValue2)")
    }
}
```
