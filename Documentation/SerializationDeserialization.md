## <a name="serde">Serialization/Deserialization</a>

Serialization and deserialization of device messages to and from `NSData` objects requires `protocol` implementations that structurally define the message objects. Example implementations of each `protocol` can be found in the [TiSensorTag GATT Profile](/BlueCapKit/Service%20Profile%20Definitions/TISensorTagServiceProfiles.swift). Methods used for serialization and deserialization are class methods on the `SerDe`. In the following sections an example for each `protocol` will be discussed. All of the examples shown here are available in a [Playground project](/Playgrounds).

## Use Cases

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

[NSStringEncoding](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSString_Class/#//apple_ref/c/tdef/NSStringEncoding) specified the string encoding. 

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
    static var size: Int {get}
    static func deserialize(data: NSData) -> Self?
    static func deserialize(data: NSData, start: Int) -> Self?
    static func deserialize(data: NSData) -> [Self]
    init?(stringValue: String)
}
```

**Description**
<table>
	<tr>
		<td>size</td>
		<td>Size of object in bytes</td>
	</tr>
	<tr>
		<td>deserialize(data: NSData) -> Self?</td>
		<td>Deserialize entire message to object</td>
	</tr>
	<tr>
		<td>deserialize(data: NSData, start:Int) -> Self?</td>
		<td>Deserialize message starting at offset to object</td>
	</tr>
	<tr>
		<td>deserialize(data: NSData) -> [Self]</td>
		<td>Deserialize entire message to array of objects</td>
	</tr>
	<tr>
		<td>init?(stringValue: String)</td>
		<td>Create object from string</td>
	</tr>
</table>

BlueCalKit provides implementation of Deserializable for [UInt8](BlueCapKit/SerDe/Uint8Extensions.swift), [Int8](BlueCapKit/SerDe/Int8Extensions.swift), [UInt16](BlueCapKit/SerDe/UInt16Extensions.swift), [Int16](BlueCapKit/SerDe/Int16Extensions.swift), [Int32](BlueCapKit/SerDe/Int32Extensions.swift) and [UInt32](BlueCapKit/SerDe/UInt32Extensions.swift). The`SerDe` serialize and deserialize are defined by,

```swift
// Deserialize objects supporting Deserializable
public static func deserialize<T: Deserializable>(data: NSData) -> T?

// Serialize objects supporting Deserializable
public static func serialize<T: Deserializable>(value: T) -> NSData
```

For UInt8 data,

```swift
let data = SerDe.serialize(UInt8(31))
if let value : UInt8 = SerDe.deserialize(data) {
    println("\(value)")
}
```

### <a name="serde_rawdeserializable">RawDeserializable Protocol</a>

The `RawDeserializable` `protocol` is used for messages that contain a single value and is defined by,

```swift
public protocol RawDeserializable {
    typealias RawType
    static var uuid: String  {get}
    var rawValue: RawType {get}
    init?(rawValue:RawType)
}
```

**Description**
<table>
	<tr>
		<td>uuid</td>
		<td>Characteristic UUID</td>
	</tr>
	<tr>
		<td>rawValue</td>
		<td>Characteristic RawType value</td>
	</tr>
	<tr>
		<td>init?(rawValue:RawType)</td>
		<td>Create object from rawValue</td>
	</tr>
</table>

The `SerDe` `serialize` and `deserialize` are defined by,

```swift
// Deserialize objects supporting RawDeserializable
public static func deserialize<T: RawDeserializable where T.RawType: Deserializable>(data: NSData) -> T?

// Serialize objects supporting RawDeserializable
public static func serialize<T: RawDeserializable>(value: T) -> NSData
```

Note that `RawType` is required to be `Deserializable`. An Enum partially supports RawDeserializable, so,

```swift
enum Enabled : UInt8, RawDeserializable {
	case No  = 0
	case Yes = 1
	public static let uuid = "F000AA12-0451-4000-B000-000000000000"
}
```

and,
 
```swift
let data = SerDe.serialize(Enabled.Yes)
if let value : Enabled = SerDe.deserialize(data) {
    println("\(value.rawValue)")
}
```

`RawDeserializable` can also be implemented by a `struct` or `class`.

```swift
struct Value : RawDeserializable {
	let rawValue: UInt8
	static let uuid = "F000AA13-0451-4000-B000-000000000000"
	init?(rawValue: UInt8) {
	  self.rawValue = rawValue
	}
}
```

and, 

```swift
if let initValue = Value(rawValue: 10) {
    let data = SerDe.serialize(initValue)
    if let value : Value = SerDe.deserialize(data) {
        println(“\(value.rawValue)”)
    }
}
```

### <a name="serde_rawarraydeserializable">RawArrayDeserializable Protocol</a>

The `RawArrayDeserializable` `protocol` is used for messages that contain multiple values of a single type and is defined by,

```swift
public protocol RawArrayDeserializable {
    typealias RawType
    static var uuid: String {get}
    static var size: Int {get}
    var rawValue: [RawType] {get}
    init?(rawValue: [RawType])
}
```

**Description**

<table>
	<tr>
		<td>uuid</td>
		<td>Characteristic UUID</td>
	</tr>
	<tr>
		<td>size</td>
		<td>Size of array</td>
	</tr>
	<tr>
		<td>rawValue</td>
		<td>Characteristic RawType values</td>
	</tr>
	<tr>
		<td>init?(rawValue: [RawType])</td>
		<td>Create object from rawValues</td>
	</tr>
</table>

The`SerDe` serialize and deserialize are defined by,

```swift
// Deserialize objects supporting RawArrayDeserializable
public static func deserialize<T: RawArrayDeserializable where T.RawType: Deserializable>(data: NSData) -> T?

// Serialize objects supporting RawArrayDeserializable
public static func serialize<T: RawArrayDeserializable>(value: T) -> NSData
```

Note that `RawType` is required to be `Deserializable`. `RawArrayDeserializable` can be implemented in a `struct` or `class`.

```swift
struct RawArrayValue : RawArrayDeserializable {    
    let rawValue : [UInt8]
    static let uuid = "F000AA13-0451-4000-B000-000000000000"
    static let size = 2
    
    init?(rawValue: [UInt8]) {
        if rawValue.count == 2 {
            self.rawValue = rawValue
        } else {
            return nil
        }
    }
}
```

and,
 
```swift
if let initValue = RawArrayValue(rawValue: [4,10]) {
    let data = SerDe.serialize(initValue)
    if let value : RawArrayValue = SerDe.deserialize(data) {
        println("\(value.rawValue)")
    }
}
```

### <a name="serde_rawpairdeserializable">RawPairDeserializable Protocol</a>

The `RawPairDeserializable` `protocol` is used for messages that contain two values of different types and is defined by,

```swift
public protocol RawPairDeserializable {
    typealias RawType1
    typealias RawType2
    static var uuid: String {get}
    var rawValue1: RawType1 {get}
    var rawValue2: RawType2 {get}
    init?(rawValue1: RawType1, rawValue2: RawType2)
}
```

**Description**

<table>
	<tr>
		<td>uuid</td>
		<td>Characteristic UUID</td>
	</tr>
	<tr>
		<td>rawValue1</td>
		<td>Characteristic RawType1 value</td>
	</tr>
	<tr>
		<td>rawValue2</td>
		<td>Characteristic RawType2 value</td>
	</tr>
	<tr>
		<td>init?(rawValue1: RawType1, rawValue2: RawType2)</td>
		<td>Create object from rawValues</td>
	</tr>
</table>

The `SerDe` `serialize` and `deserialize` are defined by,

```swift
// Deserialize objects supporting RawPairDeserializable
public static func deserialize<T: RawPairDeserializable where T.RawType1: Deserializable, T.RawType2: Deserializable>(data: NSData) -> T?

// Serialize objects supporting RawPairDeserializable
public static func serialize<T: RawPairDeserializable>(value: T) -> NSData
```

Note that `RawType1` and `RawType2` are required to be `Deserializable` to be deserialized. 1RawPairDeserializable` can be implemented in a struct or class.

```swift
struct RawPairValue : RawPairDeserializable {
    let rawValue1: UInt8
    let rawValue2: Int8
    static let uuid = "F000AA13-0451-4000-B000-000000000000"
    
    init?(rawValue1: UInt8, rawValue2: Int8) {
        self.rawValue1 = rawValue1
        self.rawValue2 = rawValue2
    }
}
```

and,
 
```swift
if let initValue = RawPairValue(rawValue1: 10, rawValue2: -10) {
    let data = SerDe.serialize(initValue)
    if let value : RawPairValue = SerDe.deserialize(data) {
        println("\(value.rawValue1)")
        println("\(value.rawValue2)")
    }
}
```

### <a name="serde_rawarraypairdeserializable">RawArrayPairDeserializable Protocol</a>

The `RawArrayPairDeserializable` `protocol` is used to define a message that contains multiple values of two different types and is defined by,

```swift
public protocol RawArrayPairDeserializable {
    typealias RawType1
    typealias RawType2
    static var uuid: String {get}
    static var size1: Int {get}
    static var size2: Int {get}
    var rawValue1: [RawType1] {get}
    var rawValue2: [RawType2] {get}
    init?(rawValue1:[RawType1], rawValue2:[RawType2])
}
```

**Description**

<table>
	<tr>
		<td>uuid</td>
		<td>Characteristic UUID</td>
	</tr>
  <tr>
		<td>size1</td>
		<td>Size of RawType1 array</td>
  </tr>
  <tr>
		<td>size2</td>
		<td>Size of RawType2 array</td>
  </tr>
	<tr>
		<td>rawValue1</td>
		<td>Characteristic RawType1 value</td>
	</tr>
	<tr>
		<td>rawValue2</td>
		<td>Characteristic RawType2 value</td>
	</tr>
	<tr>
		<td>init?(rawValue1: [RawType1], rawValue2: [RawType2])</td>
		<td>Create object from rawValues</td>
	</tr>
</table>

The `SerDe` serialize and deserialize are defined by,

```swift
// Deserialize objects supporting RawPairDeserializable
public static func deserialize<T: RawArrayPairDeserializable where T.RawType1: Deserializable,  T.RawType2: Deserializable>(data:NSData) -> T?

// Deserialize objects supporting RawPairDeserializable
public static func serialize<T: RawArrayPairDeserializable>(value:T) -> NSData
```

Note that `RawType1` and `RawType2` are required to be `Deserializable` to be deserialized. `RawArrayPairDeserializable` can be implemented in a struct or class.

```swift
struct RawArrayPairValue : RawArrayPairDeserializable {
    let rawValue1: [UInt8]
    let rawValue2: [Int8]
    static let uuid = "F000AA13-0451-4000-B000-000000000000"
    static let size1 = 2
    static let size2 = 2
    
    init?(rawValue1: [UInt8], rawValue2: [Int8]) {
        if rawValue1.count == 2 && rawValue2.count == 2 {
            self.rawValue1 = rawValue1
            self.rawValue2 = rawValue2
        } else {
            return nil
        }
    }
}
```

and,
 
```swift
if let initValue = RawArrayPairValue(rawValue1:[10, 100], rawValue2:[-10, -100]) {
    let data = SerDe.serialize(initValue)
    if let value : RawArrayPairValue = SerDe.deserialize(data) {
        println("\(value.rawValue1)")
        println("\(value.rawValue2)")
    }
}
```
