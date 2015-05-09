[![BlueCap: Swifter CoreBluetooth](https://rawgit.com/troystribling/BlueCap/6de55eaf194f101d690ba7c2d0e8b20051fd8299/Assets/banner.png)](https://itunes.apple.com/us/app/bluecap/id931219725?mt=8#)

BlueCap provides a swift wrapper around CoreBluetooth and much more.

# Features

- A [futures](https://github.com/troystribling/SimpleFutures) interface replacing protocol implementations.
- Connection events for connect, disconnect and timeout.
- Service scan timeout.
- A framework for specification of GATT profiles.
- Characteristic profile types encapsulating serialization and deserialization.
- [Example](https://github.com/troystribling/BlueCap/tree/master/Examples) applications implementing Central and Peripheral.
- A full featured extendable Central scanner and Peripheral emulator available in the [App Store](https://itunes.apple.com/us/app/bluecap/id931219725?mt=8#).
- Comprehensive test coverage

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

With BlueCap it is possible to serialize and deserialize messages exchanged with bluetooth devices, define reusable GATT profile definitions and easily implement Central and Peripheral applications. The following sections will address each of these items in some detail. [Simple example applications](https://github.com/troystribling/BlueCap/tree/master/Examples) are also available.
 
## Serialization/Deserialization

Serialization and deserialization of device messages requires protocol implementations. Then application objects can be converted to and from NSData objects using methods on Serde. This section will describe how this is done and give examples. Example implantations of each protocol can also be found in the [Ti Sensor Tag GATT profile](https://github.com/troystribling/BlueCap/blob/master/BlueCapKit/Service%20Profile%20Definitions/TISensorTagServiceProfiles.swift) available in BlueCapKit. 

### Deserializable Protocol

The Deserializable protocol is defined by,

```swift
public protocol Deserializable {
    static var size : Int {get}
    static func deserialize(data:NSData) -> Self?
    static func deserialize(data:NSData, start:Int) -> Self?
    static func deserialize(data:NSData) -> [Self]
    init?(stringValue:String)
}
```

BlueCalKit provides implementation of Deserializable for [UInt8](https://github.com/troystribling/BlueCap/blob/master/BlueCapKit/SerDe/Uint8Extensions.swift), [Int8](https://github.com/troystribling/BlueCap/blob/master/BlueCapKit/SerDe/Int8Extensions.swift), [UInt16](https://github.com/troystribling/BlueCap/blob/master/BlueCapKit/SerDe/UInt16Extensions.swift) and [Int16](https://github.com/troystribling/BlueCap/blob/master/BlueCapKit/SerDe/Int16Extensions.swift). The Serde serialize and deserialize are defined by,

```swift
public static func deserialize<T:Deserializable>(data:NSData) -> T?
public static func serialize<T:Deserializable>(value:T) -> NSData
```

for Uint 8 data we have,

```swift
let data = Serde.serialize(UInt8(31))
if let value : UInt8 = Serde.deserialize(data) {
    println("\(value)")
}
```

### RawDeserializable Protocol

The RawDeserializable protocol is defined by,

```swift
public protocol RawDeserializable {
    typealias RawType
    static var uuid   : String  {get}
    var rawValue      : RawType {get}
    init?(rawValue:RawType)
}
```

RawDeserializable is used to define a message that contains a single value. The Serde serialize and deserialize are defined by,

```swift
public static func deserialize<T:RawDeserializable where T.RawType:Deserializable>(data:NSData) -> T?
public static func serialize<T:RawDeserializable>(value:T) -> NSData
```

note that RawType is required to be Deserializable. An Enum partially supports RawDeserializable, so,

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

RawDeserializable can also be implemented in a struct or class.

```swift
public struct Value : RawDeserializable {
    
		public let rawValue    : UInt8
    public static let uuid = "F000AA13-0451-4000-B000-000000000000"

    public init?(rawValue:UInt8) {
        self.rawValue = rawValue
    }
}
```

```swift
if let firstValue = Value(rawValue:10) {
    let data = Serde.serialize(firstValue)
    if let value : Value = Serde.deserialize(data) {
        println(“\(value.rawValue)”)
    }
}
```
### RawArrayDeserializable Protocol

The RawArrayDeserializable protocol is defined by,

```swift
public protocol RawArrayDeserializable {
    typealias RawType
    static var uuid   : String    {get}
    static var size   : Int       {get}
    var rawValue      : [RawType] {get}
    init?(rawValue:[RawType])
}
```

It would be used to define a message that contains multiple values of a single type. The Serde serialize and deserialize are defined by,

```swift
public static func deserialize<T:RawArrayDeserializable where T.RawType:Deserializable>(data:NSData) -> T?
public static func serialize<T:RawArrayDeserializable>(value:T) -> NSData
```

note that RawType is required to be Deserializable. RawArrayDeserializable can also be implemented in a struct or class.

```swift
```

```swift
```

### RawPairDeserializable Protocol

The RawPairDeserializable protocol is defined by,

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

It would be used to define a message that contains two values of different types. The Serde serialize and deserialize are defined by,

```swift
public static func deserialize<T:RawPairDeserializable where T.RawType1:Deserializable,  T.RawType2:Deserializable>(data:NSData) -> T?
public static func serialize<T:RawPairDeserializable>(value:T) -> NSData
```

note that RawType1 and RawType2 are required to be Deserializable. RawPairDeserializable can also be implemented in a struct or class.

```swift
```

```swift
```

### RawArrayPairDeserializable Protocol

The RawArrayPairDeserializable protocol is defined by,

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

It would be used to define a message that contains multiple values of two different types. The Serde serialize and deserialize are defined by,

```swift
public static func deserialize<T:RawArrayPairDeserializable where T.RawType1:Deserializable,  T.RawType2:Deserializable>(data:NSData) -> T?
public static func serialize<T:RawArrayPairDeserializable>(value:T) -> NSData
```

note that RawType1 and RawType2 are required to be Deserializable. RawArrayPairDeserializable can also be implemented in a struct or class.

```swift
```

```swift
```

## GATT Profile Definition

### ServiceConfigurable Protocol

### CharacteristicConfigurable Protocol

### StringDeserializable Protocol

### ConfiguredServiceProfile

### RawCharacteristicProfile

### RawArrayCharacteristicProfile

### RawPairCharacteristicProfile

### RawArrayPairCharacteristicProfile

### StringCharacteristicProfile

### ProfileManager

### Strings

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

