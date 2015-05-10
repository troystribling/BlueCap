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

1. Place the <code>BlueCap</code> somewhere in your project directory. You can either copy it or add it as a git submodule.
2. Open the <code>BluCap</code> project folder and drag <code>BlueCapKit.xcodeproj</code> into the project navigator of your applications Xcode project.
3. Under your Projects Info tab set the iOS Deployment Target to 8.0 and that the <code>BlueCapKit.xcodeproj iOS Deployment Target<code> is also 8.0.
4. Under the General tab for your project target add the top <code>BlueCapKit.framework</code> as an Embedded Binary.
5. Under the <code>Build Phases</code> tab add <code>BlueCapKit.framework</code> as a <code>Target Dependency</code> and under <code>Link Binary With Libraries</code> add <code>CoreLocation.framework</code> and <code>CoreBluetooth.framework</code>.
6. To enable debug log output select your project target and the <code>Build Settings</code> tab. Under <code>Other Swift Flags</code> and Debug add <code>-D DEBUG</code>.

# Usage

With <code>BlueCap</code> it is possible to serialize and deserialize messages exchanged with bluetooth devices, define reusable GATT profile definitions and easily implement Central and Peripheral applications. The following sections will address each of these items in some detail. [Example applications](https://github.com/troystribling/BlueCap/tree/master/Examples) are also available.
 
## Serialization/Deserialization

Serialization and deserialization of device messages requires protocol implementations. Then application objects can be converted to and from NSData objects using methods on <code>Serde</code>. This section will describe how this is done. Example implantations of each protocol can be found in the [Ti Sensor Tag GATT profile](https://github.com/troystribling/BlueCap/blob/master/BlueCapKit/Service%20Profile%20Definitions/TISensorTagServiceProfiles.swift) available in BlueCapKit and the following examples are implemented in a BlueCap [Playground](https://github.com/troystribling/BlueCap/tree/master/BlueCap/BlueCap.playground). 

### <code>Strings</code>

For <code>Strings</code> The <code>Serde serialize</code> and <code>deserialize</code> are defined by,

```swift
public static func deserialize(data:NSData, encoding:NSStringEncoding = NSUTF8StringEncoding) -> String?
public static func serialize(value:String, encoding:NSStringEncoding = NSUTF8StringEncoding) -> NSData?
```

 **Parameters**

<table>
	<tr>
		<td><code>data</code></td>
		<td>NSData object containing serialized message</td>
	</tr>
	<tr>
		<td><code>value</code></td>
		<td>Deserialized message</td>
	</tr>
  <tr>
		<td><code>encoding</code></td>
		<td>String encoding.Default is UTF-8.</td>
	</tr>
</table>

and,
```swift
if let data = Serde.serialize("Test") {
    if let value = Serde.deserialize(data) {
        println(value)
    }
}
```

### <code>Deserializable</code> Protocol

The <code>Deserializable</code> protocol is defined by,

```swift
public protocol Deserializable {
    static var size : Int {get}
    static func deserialize(data:NSData) -> Self?
    static func deserialize(data:NSData, start:Int) -> Self?
    static func deserialize(data:NSData) -> [Self]
    init?(stringValue:String)
}
```

**Description**
<table>
	<tr>
		<td><code>size</code></td>
		<td>Size of object in bytes</td>
	</tr>
	<tr>
		<td><code>deserialize(data:NSData) -> Self?</code></td>
		<td>Deserialize entire message to object</td>
	</tr>
	<tr>
		<td><code>deserialize(data:NSData, start:Int) -> Self?</code></td>
		<td>Deserialize message starting at offset to object</td>
	</tr>
	<tr>
		<td><code>deserialize(data:NSData) -> [Self]</code></td>
		<td>Deserialize entire message to array of objects</td>
	</tr>
	<tr>
		<td><code>init?(stringValue:String)</code></td>
		<td>Create object from string</td>
	</tr>
</table>

<code>BlueCalKit</code> provides implementation of <code>Deserializable</code> for [<code>UInt8<pcode>](https://github.com/troystribling/BlueCap/blob/master/BlueCapKit/SerDe/Uint8Extensions.swift), [<code>Int8</code>](https://github.com/troystribling/BlueCap/blob/master/BlueCapKit/SerDe/Int8Extensions.swift), [<code>UInt16</code>](https://github.com/troystribling/BlueCap/blob/master/BlueCapKit/SerDe/UInt16Extensions.swift) and [<code>Int16</code>](https://github.com/troystribling/BlueCap/blob/master/BlueCapKit/SerDe/Int16Extensions.swift). The <code>Serde serialize</code> and <code>deserialize</code> are defined by,

```swift
public static func deserialize<T:Deserializable>(data:NSData) -> T?
public static func serialize<T:Deserializable>(value:T) -> NSData
```

**Parameters**

<table>
	<tr>
		<td><code>data</code></td>
		<td>NSData object containing serialized message</td>
	</tr>
	<tr>
		<td><code>value</code></td>
		<td>Deserialized message</td>
	</tr>
</table>

For <code>UInt8</code> data,

```swift
let data = Serde.serialize(UInt8(31))
if let value : UInt8 = Serde.deserialize(data) {
    println("\(value)")
}
```

### <code>RawDeserializable</code> Protocol

The <code>RawDeserializable</code> protocol is defined by,

```swift
public protocol RawDeserializable {
    typealias RawType
    static var uuid   : String  {get}
    var rawValue      : RawType {get}
    init?(rawValue:RawType)
}
```

**Description**
<table>
	<tr>
		<td><code>uuid</code></td>
		<td>Characteristic UUID</td>
	</tr>
	<tr>
		<td><code>rawValue</code></td>
		<td>Characteristic RawType value</td>
	</tr>
	<tr>
		<td><code>init?(rawValue:RawType)</code></td>
		<td>Create object from rawValue</td>
	</tr>
</table>

<code>RawDeserializable</code> is used to define a message that contains a single value. The <code>Serde serialize</code> and <code>deserialize</code> are defined by,

```swift
public static func deserialize<T:RawDeserializable where T.RawType:Deserializable>(data:NSData) -> T?
public static func serialize<T:RawDeserializable>(value:T) -> NSData
```

**Parameters**

<table>
	<tr>
		<td><code>data</code></td>
		<td>NSData object containing serialized message</td>
	</tr>
	<tr>
		<td><code>value</code></td>
		<td>Deserialized message</td>
	</tr>
</table>

note that <code>RawType</code> is required to be <code>Deserializable</code>. An Enum partially supports <code>RawDeserializable</code>, so,

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

<code>RawDeserializable</code> can also be implemented in a struct or class.

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
### <code>RawArrayDeserializable</code> Protocol

The <code>RawArrayDeserializable</code> protocol is defined by,

```swift
public protocol RawArrayDeserializable {
    typealias RawType
    static var uuid   : String    {get}
    static var size   : Int       {get}
    var rawValue      : [RawType] {get}
    init?(rawValue:[RawType])
}
```

**Description**

<table>
	<tr>
		<td><code>uuid</code></td>
		<td>Characteristic UUID</td>
	</tr>
	<tr>
		<td><code>size</code></td>
		<td>Size of array</td>
	</tr>
	<tr>
		<td><code>rawValue</code></td>
		<td>Characteristic RawType values</td>
	</tr>
	<tr>
		<td><code>init?(rawValue:[RawType])</code></td>
		<td>Create object from rawValues</td>
	</tr>
</table>

<code>RawArrayDeserializable</code> is used to define a message that contains multiple values of a single type. The <code>Serde serialize</code> and <code>deserialize</code> are defined by,

```swift
public static func deserialize<T:RawArrayDeserializable where T.RawType:Deserializable>(data:NSData) -> T?
public static func serialize<T:RawArrayDeserializable>(value:T) -> NSData
```

**Parameters**

<table>
	<tr>
		<td><code>data</code></td>
		<td>NSData object containing serialized message</td>
	</tr>
	<tr>
		<td><code>value</code></td>
		<td>Deserialized message</td>
	</tr>
</table>

note that <code>RawType</code> is required to be <code>Deserializable</code>. <code>RawArrayDeserializable</code> can be implemented in a struct or class.

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

### <code>RawPairDeserializable</code> Protocol

The <code>RawPairDeserializable</code> protocol is defined by,

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

**Description**

<table>
	<tr>
		<td><code>uuid</code></td>
		<td>Characteristic UUID</td>
	</tr>
	<tr>
		<td><code>rawValue1</code></td>
		<td>Characteristic RawType1 value</td>
	</tr>
	<tr>
		<td><code>rawValue2</code></td>
		<td>Characteristic RawType2 value</td>
	</tr>
	<tr>
		<td><code>init?(rawValue1:RawType1, rawValue2:RawType2)</code></td>
		<td>Create object from rawValues</td>
	</tr>
</table>

<code>RawPairDeserializable</code> is used to define a message that contains two values of different types. The <code>Serde serialize</code> and <code>deserialize</code> are defined by,

```swift
public static func deserialize<T:RawPairDeserializable where T.RawType1:Deserializable,  T.RawType2:Deserializable>(data:NSData) -> T?
public static func serialize<T:RawPairDeserializable>(value:T) -> NSData
```

**Parameters**

<table>
	<tr>
		<td><code>data</code></td>
		<td>NSData object containing serialized message</td>
	</tr>
	<tr>
		<td><code>value</code></td>
		<td>Deserialized message</td>
	</tr>
</table>

note that <code>RawType1</code> and <code>RawType2</code> are required to be <code>Deserializable</code>. <code>RawPairDeserializable</code> can be implemented in a struct or class.

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

### <code>RawArrayPairDeserializable</code> Protocol

The <code>RawArrayPairDeserializable</code> protocol is defined by,

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

**Description**

<table>
	<tr>
		<td><code>uuid</code></td>
		<td>Characteristic UUID</td>
	</tr>
  <tr>
		<td><code>size1</code></td>
		<td>Size of RawType1 array</td>
  </tr>
  <tr>
		<td><code>size2</code></td>
		<td>Size of RawType2 array</td>
  </tr>
	<tr>
		<td><code>rawValue1</code></td>
		<td>Characteristic RawType1 value</td>
	</tr>
	<tr>
		<td><code>rawValue2</code></td>
		<td>Characteristic RawType2 value</td>
	</tr>
	<tr>
		<td><code>init?(rawValue1:[RawType1], rawValue2:[RawType2])</code></td>
		<td>Create object from rawValues</td>
	</tr>
</table>

<code>RawArrayPairDeserializable</code> is used to define a message that contains multiple values of two different types. The <code>Serde serialize</code> and <code>deserialize</code> are defined by,

```swift
public static func deserialize<T:RawArrayPairDeserializable where T.RawType1:Deserializable,  T.RawType2:Deserializable>(data:NSData) -> T?
public static func serialize<T:RawArrayPairDeserializable>(value:T) -> NSData
```

**Parameters**

<table>
	<tr>
		<td><code>data</code></td>
		<td>NSData object containing serialized message</td>
	</tr>
	<tr>
		<td><code>value</code></td>
		<td>Deserialized message</td>
	</tr>
</table>

note that <code>RawType1</code> and <code>RawType2</code> are required to be <code>Deserializable</code>. <code>RawArrayPairDeserializable</code> can be implemented in a struct or class.

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

### <code>ServiceConfigurable</code> Protocol

The <code>ServiceConfigurable</code> protocol defined by,

```swift
public protocol ServiceConfigurable {
    static var name  : String {get}
    static var uuid  : String {get}
    static var tag   : String {get}
}
```

and is used to specify service configuration.

### <code>CharacteristicConfigurable</code> Protocol

```swift
public protocol CharacteristicConfigurable {
    static var name          : String {get}
    static var uuid          : String {get}
    static var permissions   : CBAttributePermissions {get}
    static var properties    : CBCharacteristicProperties {get}
    static var initialValue  : NSData? {get}
}
```

### <code>StringDeserializable</code> Protocol

```swift
public protocol StringDeserializable {
    static var stringValues : [String] {get}
    var stringValue         : [String:String] {get}
    init?(stringValue:[String:String])
}
```

### <code>ConfiguredServiceProfile</code>

```swift
```

```swift
```

### <code>RawCharacteristicProfile</code>

```swift
```

```swift
```

### <code>RawArrayCharacteristicProfile</code>

```swift
```

```swift
```

### <code>RawPairCharacteristicProfile</code>

```swift
```

```swift
```

### <code>RawArrayPairCharacteristicProfile</code>

```swift
```

```swift
```

### <code>StringCharacteristicProfile</code>

### <code>ProfileManager</code>

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

