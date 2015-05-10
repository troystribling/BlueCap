[![BlueCap: Swifter CoreBluetooth](https://rawgit.com/troystribling/BlueCap/6de55eaf194f101d690ba7c2d0e8b20051fd8299/Assets/banner.png)](https://itunes.apple.com/us/app/bluecap/id931219725?mt=8#)

BlueCap provides a swift wrapper around CoreBluetooth and much more.

# Features

- A [futures](https://github.com/troystribling/SimpleFutures) interface replacing protocol implementations.
- Connection events for connect, disconnect and timeout.
- Service scan timeout.
- Characteristic read/write timeout.
- A framework for specification of GATT profiles.
- Characteristic profile types encapsulating serialization and deserialization.
- [Example](https://github.com/troystribling/BlueCap/tree/master/Examples) applications implementing Central and Peripheral.
- A full featured extendable Central scanner and Peripheral emulator available in the [App Store](https://itunes.apple.com/us/app/bluecap/id931219725?mt=8#).
- Comprehensive test coverage.

# Requirements

- iOS 8.0+
- Xcode 6.3+

# Installation

1. Place the BlueCap somewhere in your project directory. You can either copy it or add it as a git submodule.
2. Open the BluCap project folder and drag BlueCapKit.xcodeproj into the project navigator of your applications Xcode project.
3. Under your Projects Info tab set the iOS Deployment Target to 8.0 and that the BlueCapKit.xcodeproj iOS Deployment Target is also 8.0.
4. Under the General tab for your project target add the top BlueCapKit.framework as an Embedded Binary.
5. Under the Build Phases tab add BlueCapKit.framework as a Target Dependency and under Link Binary With Libraries add CoreLocation.framework and CoreBluetooth.framework.
6. To enable debug log output select your project target and the Build Settings tab. Under Other Swift Flags under Debug add -D DEBUG.

# Usage

With BlueCap it is possible to serialize and deserialize messages exchanged with bluetooth devices, define reusable GATT profile definitions and easily implement Central and Peripheral applications. The following sections will address each of these items in some detail. [Example applications](https://github.com/troystribling/BlueCap/tree/master/Examples) are also available.
 
## Serialization/Deserialization

Serialization and deserialization of device messages requires protocol implementations. Then application objects can be converted to and from NSData objects using methods on `Serde`. This section will describe how this is done. Example implantations of each protocol can be found in the [Ti Sensor Tag GATT profile](https://github.com/troystribling/BlueCap/blob/master/BlueCapKit/Service%20Profile%20Definitions/TISensorTagServiceProfiles.swift) available in BlueCapKit and the following examples are implemented in a BlueCap [Playground](https://github.com/troystribling/BlueCap/tree/master/BlueCap/BlueCap.playground). 

### `Strings`

For `Strings` The `Serde` `serialize` and `deserialize `are defined by,

```swift
public static func deserialize(data:NSData, encoding:NSStringEncoding = NSUTF8StringEncoding) -> String?
```

**Parameters**

|Header |Column 1 | Column 2 | Column 3  | 
|:— |:—— |:——:| ——:|
|1. Row| is | is | is  |
|2. Row| left | nicely | right  |
|3. Row| aligned | centered | aligned  | 

```swift
public static func serialize(value:String, encoding:NSStringEncoding = NSUTF8StringEncoding) -> NSData?
```

and,
```swift
if let data = Serde.serialize("Test") {
    if let value = Serde.deserialize(data) {
        println(value)
    }
}
```

### `Deserializable` Protocol

The `Deserializable` protocol is defined by,

```swift
public protocol Deserializable {
    static var size : Int {get}
    static func deserialize(data:NSData) -> Self?
    static func deserialize(data:NSData, start:Int) -> Self?
    static func deserialize(data:NSData) -> [Self]
    init?(stringValue:String)
}
```

BlueCalKit provides implementation of `Deserializable` for [`UInt8`](https://github.com/troystribling/BlueCap/blob/master/BlueCapKit/SerDe/Uint8Extensions.swift), [`Int8`](https://github.com/troystribling/BlueCap/blob/master/BlueCapKit/SerDe/Int8Extensions.swift), [`UInt16`](https://github.com/troystribling/BlueCap/blob/master/BlueCapKit/SerDe/UInt16Extensions.swift) and [`Int16`](https://github.com/troystribling/BlueCap/blob/master/BlueCapKit/SerDe/Int16Extensions.swift). The `Serde` `serialize` and `deserialize `are defined by,

```swift
public static func deserialize<T:Deserializable>(data:NSData) -> T?
public static func serialize<T:Deserializable>(value:T) -> NSData
```

for `UInt8` data,

```swift
let data = Serde.serialize(UInt8(31))
if let value : UInt8 = Serde.deserialize(data) {
    println("\(value)")
}
```

### `RawDeserializable` Protocol

The `RawDeserializable` protocol is defined by,

```swift
public protocol RawDeserializable {
    typealias RawType
    static var uuid   : String  {get}
    var rawValue      : RawType {get}
    init?(rawValue:RawType)
}
```

`RawDeserializable` is used to define a message that contains a single value. The `Serde` `serialize` and `deserialize` are defined by,

```swift
public static func deserialize<T:RawDeserializable where T.RawType:Deserializable>(data:NSData) -> T?
public static func serialize<T:RawDeserializable>(value:T) -> NSData
```

note that `RawType` is required to be `Deserializable`. An Enum partially supports `RawDeserializable`, so,

```swift
enum Enabled : UInt8, RawDeserializable {
	case No  = 0
	case Yes = 1
	public static let uuid = "F000AA12-0451-4000-B000-000000000000"
}
```
and, 
```swift
let data = Serde.serialize(Enabled.Yes)
if let value : Enabled Serde.deserialize(data) {
    println("\(value.rawValue)")
}
```

`RawDeserializable` can also be implemented in a struct or class.

```swift
struct Value : RawDeserializable {
		let rawValue : UInt8
	  static let uuid = "F000AA13-0451-4000-B000-000000000000"

    init?(rawValue:UInt8) {
        self.rawValue = rawValue
    }
}
```
and, 
```swift
if let initValue = Value(rawValue:10) {
    let data = Serde.serialize(initValue)
    if let value : Value = Serde.deserialize(data) {
        println(“\(value.rawValue)”)
    }
}
```
### `RawArrayDeserializable` Protocol

The `RawArrayDeserializable` protocol is defined by,

```swift
public protocol RawArrayDeserializable {
    typealias RawType
    static var uuid   : String    {get}
    static var size   : Int       {get}
    var rawValue      : [RawType] {get}
    init?(rawValue:[RawType])
}
```

`RawArrayDeserializable` is used to define a message that contains multiple values of a single type. The `Serde` `serialize` and `deserialize` are defined by,

```swift
public static func deserialize<T:RawArrayDeserializable where T.RawType:Deserializable>(data:NSData) -> T?
public static func serialize<T:RawArrayDeserializable>(value:T) -> NSData
```

note that `RawType` is required to be `Deserializable`. `RawArrayDeserializable` can be implemented in a struct or class.

```swift
struct RawArrayValue : RawArrayDeserializable {    
    let rawValue : [UInt8]
    static let uuid = "F000AA13-0451-4000-B000-000000000000"
    static let size = 2
    
    init?(rawValue:[UInt8]) {
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
if let initValue = RawArrayValue(rawValue:[4,10]) {
    let data = Serde.serialize(initValue)
    if let value : RawArrayValue = Serde.deserialize(data) {
        println("\(value.rawValue)")
    }
}
```

### `RawPairDeserializable` Protocol

The `RawPairDeserializable` protocol is defined by,

```swift
public protocol RawPairDeserializable {
    typealias RawType1
    typealias RawType2
    static var uuid : String   {get}
    var rawValue1   : RawType1 {get}
    var rawValue2   : RawType2 {get}
    init?(rawValue1:RawType1, rawValue2:RawType2)
}
```

`RawPairDeserializable` is used to define a message that contains two values of different types. The `Serde` `serialize` and `deserialize` are defined by,

```swift
public static func deserialize<T:RawPairDeserializable where T.RawType1:Deserializable,  T.RawType2:Deserializable>(data:NSData) -> T?
public static func serialize<T:RawPairDeserializable>(value:T) -> NSData
```

note that `RawType1` and `RawType2` are required to be `Deserializable`. `RawPairDeserializable` can be implemented in a struct or class.

```swift
struct RawPairValue : RawPairDeserializable {
    let rawValue1 : UInt8
    let rawValue2 : Int8
    static let uuid = "F000AA13-0451-4000-B000-000000000000"
    
    init?(rawValue1:UInt8, rawValue2:Int8) {
        self.rawValue1 = rawValue1
        self.rawValue2 = rawValue2
    }
}
```
and, 
```swift
if let initValue = RawPairValue(rawValue1:10, rawValue2:-10) {
    let data = Serde.serialize(initValue)
    if let value : RawPairValue = Serde.deserialize(data) {
        println("\(value.rawValue1)")
        println("\(value.rawValue2)")
    }
}
```

### `RawArrayPairDeserializable` Protocol

The `RawArrayPairDeserializable` protocol is defined by,

```swift
public protocol RawArrayPairDeserializable {
    typealias RawType1
    typealias RawType2
    static var uuid   : String     {get}
    static var size1  : Int        {get}
    static var size2  : Int        {get}
    var rawValue1     : [RawType1] {get}
    var rawValue2     : [RawType2] {get}
    init?(rawValue1:[RawType1], rawValue2:[RawType2])
}
```

`RawArrayPairDeserializable` is used to define a message that contains multiple values of two different types. The `Serde` `serialize` and `deserialize` are defined by,

```swift
public static func deserialize<T:RawArrayPairDeserializable where T.RawType1:Deserializable,  T.RawType2:Deserializable>(data:NSData) -> T?
public static func serialize<T:RawArrayPairDeserializable>(value:T) -> NSData
```

note that `RawType1` and `RawType2` are required to be `Deserializable`. `RawArrayPairDeserializable` can be implemented in a struct or class.

```swift
struct RawArrayPairValue : RawArrayPairDeserializable {
    let rawValue1 : [UInt8]
    let rawValue2 : [Int8]
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
```
and, 
```swift
if let initValue = RawArrayPairValue(rawValue1:[10, 100], rawValue2:[-10, -100]) {
    let data = Serde.serialize(initValue)
    if let value : RawArrayPairValue = Serde.deserialize(data) {
        println("\(value.rawValue1)")
        println("\(value.rawValue2)")
    }
}
```

## GATT Profile Definition

GATT profile definitions are required to add support for a device to the BlueCap app but are not required build a functional application using the framework. Implementing a GATT profile for a device allows the framework to automatically identify and configure services and characteristics and provides serialization and deserialization of characteristic values to and from strings.

### `ServiceConfigurable` Protocol

The `ServiceConfigurable` protocol defined by,

```swift
public protocol ServiceConfigurable {
    static var name  : String {get}
    static var uuid  : String {get}
    static var tag   : String {get}
}
```

and is used to specify service configuration.

### `CharacteristicConfigurable` Protocol

```swift
public protocol CharacteristicConfigurable {
    static var name          : String {get}
    static var uuid          : String {get}
    static var permissions   : CBAttributePermissions {get}
    static var properties    : CBCharacteristicProperties {get}
    static var initialValue  : NSData? {get}
}
```

### `StringDeserializable` Protocol

```swift
public protocol StringDeserializable {
    static var stringValues : [String] {get}
    var stringValue         : [String:String] {get}
    init?(stringValue:[String:String])
}
```

### `ConfiguredServiceProfile`

```swift
```

```swift
```

### `RawCharacteristicProfile`

```swift
```

```swift
```

### `RawArrayCharacteristicProfile`

```swift
```

```swift
```

### `RawPairCharacteristicProfile`

```swift
```

```swift
```

### `RawArrayPairCharacteristicProfile`

```swift
```

```swift
```

### `StringCharacteristicProfile`

### `ProfileManager`

### Add Profile to BlueCap App

## Central

### PowerOn/PowerOff

### Service Scanning

### Peripheral Connection

### Service and Characteristic Discovery

### Characteristic Read/Write

### Characteristic Update Notifications

## Peripheral

### PowerOn/PowerOff

### Advertising

### Read Characteristic

### Set Characteristic Value

### Updating Characteristic Value

### iBeacon Emulation

