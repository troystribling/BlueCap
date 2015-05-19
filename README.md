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
6. To enable debug log output select your project target and the Build Settings tab. Under Other Swift Flags and Debug add -D DEBUG.

# Getting Started

With BlueCap it is possible to easily implement Central and Peripheral applications, serialize and deserialize messages exchanged with bluetooth devices and define reusable GATT profile definitions. The following sections will address each of these items in some detail. [Example applications](https://github.com/troystribling/BlueCap/tree/master/Examples) are also available.
 
## BLE Model

Communication in BLE uses the Client-Server model. The Client is  called a Central and the server a Peripheral. The Peripheral presents structured data to the Central organized into Services that have Characteristics. This called is a Generic Attribute Table (GATT) Profile. Characteristics contain the data values as well as attributes describing permissions and properties. At a high level Central and Peripheral use cases are,

<table>
  <tr>
    <th>Central</th>
    <th>Peripheral</th>
  </tr>
	<tr>
		<td>Scans for Services</td>
		<td>Advertises Services</td>
	</tr>
	<tr>
		<td>Discovers Services and Characteristics</td>
		<td>Supports GATT Profile</td>
	</tr>
	<tr>
		<td>Data Read/Write/Notifications</td>
		<td>Data Read/Write/Notifications</td>
	</tr>
</table>

## Usage

1. [Serialization/Deserialization](#serde)
2. [GATT Profile Definition](#gatt)
3. [CentralManager](#central)
4. [PeripheralManager](#peripheral)

## <a name="serde">Serialization/Deserialization</a>

Serialization and deserialization of device messages requires protocol implementations. Then application objects can be converted to and from NSData objects using methods on Serde. This section will describe how this is done. Example implantations of each protocol can be found in the [Ti Sensor Tag GATT profile](https://github.com/troystribling/BlueCap/blob/master/BlueCapKit/Service%20Profile%20Definitions/TISensorTagServiceProfiles.swift) available in BlueCapKit and the following examples are implemented in a BlueCap [Playground](https://github.com/troystribling/BlueCap/tree/master/BlueCap/SerDe.playground). 

### Strings

For Strings Serde serialize and deserialize are defined by,

```swift
public static func deserialize(data:NSData, encoding:NSStringEncoding = NSUTF8StringEncoding) -> String?
public static func serialize(value:String, encoding:NSStringEncoding = NSUTF8StringEncoding) -> NSData?
```

[NSStringEncoding](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSString_Class/#//apple_ref/doc/constant_group/String_Encodings) supports many encodings. 

to use,
```swift
if let data = Serde.serialize("Test") {
    if let value = Serde.deserialize(data) {
        println(value)
    }
}
```

### Deserializable Protocol

The Deserializable protocol is used to define deserialization of  numeric objects and is defined by,

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
		<td>size</td>
		<td>Size of object in bytes</td>
	</tr>
	<tr>
		<td>deserialize(data:NSData) -> Self?</td>
		<td>Deserialize entire message to object</td>
	</tr>
	<tr>
		<td>deserialize(data:NSData, start:Int) -> Self?</td>
		<td>Deserialize message starting at offset to object</td>
	</tr>
	<tr>
		<td>deserialize(data:NSData) -> [Self]</td>
		<td>Deserialize entire message to array of objects</td>
	</tr>
	<tr>
		<td>init?(stringValue:String)</td>
		<td>Create object from string</td>
	</tr>
</table>

BlueCalKit provides implementation of Deserializable for [UInt8<pcode>](https://github.com/troystribling/BlueCap/blob/master/BlueCapKit/SerDe/Uint8Extensions.swift), [Int8](https://github.com/troystribling/BlueCap/blob/master/BlueCapKit/SerDe/Int8Extensions.swift), [UInt16](https://github.com/troystribling/BlueCap/blob/master/BlueCapKit/SerDe/UInt16Extensions.swift) and [Int16](https://github.com/troystribling/BlueCap/blob/master/BlueCapKit/SerDe/Int16Extensions.swift). The Serde serialize and deserialize are defined by,

```swift
public static func deserialize<T:Deserializable>(data:NSData) -> T?
public static func serialize<T:Deserializable>(value:T) -> NSData
```

For UInt8 data,

```swift
let data = Serde.serialize(UInt8(31))
if let value : UInt8 = Serde.deserialize(data) {
    println("\(value)")
}
```

### <a name="rawdeserializable">RawDeserializable Protocol</a>

The RawDeserializable protocol is used to define a message that contains a single value and is defined by,

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

The Serde serialize and deserialize are defined by,

```swift
public static func deserialize<T:RawDeserializable where T.RawType:Deserializable>(data:NSData) -> T?
public static func serialize<T:RawDeserializable>(value:T) -> NSData
```

Note that RawType is required to be Deserializable. An Enum partially supports RawDeserializable, so,

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
### RawArrayDeserializable Protocol

The RawArrayDeserializable protocol is used to define a message that contains multiple values of a single type and is defined by,

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
		<td>init?(rawValue:[RawType])</td>
		<td>Create object from rawValues</td>
	</tr>
</table>

The Serde serialize and deserialize are defined by,

```swift
public static func deserialize<T:RawArrayDeserializable where T.RawType:Deserializable>(data:NSData) -> T?
public static func serialize<T:RawArrayDeserializable>(value:T) -> NSData
```

Note that RawType is required to be Deserializable. RawArrayDeserializable can be implemented in a struct or class.

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

### RawPairDeserializable Protocol

The RawPairDeserializable is used to define a message that contains two values of different types and is defined by,

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
		<td>init?(rawValue1:RawType1, rawValue2:RawType2)</td>
		<td>Create object from rawValues</td>
	</tr>
</table>

The Serde serialize and deserialize are defined by,

```swift
public static func deserialize<T:RawPairDeserializable where T.RawType1:Deserializable,  T.RawType2:Deserializable>(data:NSData) -> T?
public static func serialize<T:RawPairDeserializable>(value:T) -> NSData
```

Note that RawType1 and RawType2 are required to be Deserializable. RawPairDeserializable can be implemented in a struct or class.

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

### RawArrayPairDeserializable Protocol

The RawArrayPairDeserializable is used to define a message that contains multiple values of two different types and is defined by,

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
		<td>init?(rawValue1:[RawType1], rawValue2:[RawType2])</td>
		<td>Create object from rawValues</td>
	</tr>
</table>

The Serde serialize and deserialize are defined by,

```swift
public static func deserialize<T:RawArrayPairDeserializable where T.RawType1:Deserializable,  T.RawType2:Deserializable>(data:NSData) -> T?
public static func serialize<T:RawArrayPairDeserializable>(value:T) -> NSData
```

Note that RawType1 and RawType2 are required to be Deserializable. RawArrayPairDeserializable can be implemented in a struct or class.

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

## <a name="gatt">GATT Profile Definition</a>

GATT profile definitions are required to add support for a device to the BlueCap app but are not required build a functional application using the framework. Implementing a GATT profile for a device allows the framework to automatically identify and configure services and characteristics and provides serialization and deserialization of characteristic values to and from strings. The examples in this section are also available in a BlueCap [Playground](https://github.com/troystribling/BlueCap/tree/master/BlueCap/Profile.playground)

### ServiceConfigurable Protocol

The ServiceConfigurable protocol is used to specify Service configuration and is defined by,

```swift
public protocol ServiceConfigurable {
    static var name  : String {get}
    static var uuid  : String {get}
    static var tag   : String {get}
}
```

**Description**

<table>
	<tr>
		<td>name</td>
		<td>Service name</td>
	</tr>
  <tr>
		<td>uuid</td>
		<td>Service UUID</td>
  </tr>
  <tr>
		<td>tag</td>
		<td>Used to organize services in the BlueCap app profile browser</td>
  </tr>
</table>

### CharacteristicConfigurable Protocol

The CharacteristicConfigurable is used to specify Characteristic configuration and protocol is defined by,

```swift
public protocol CharacteristicConfigurable {
    static var name          : String {get}
    static var uuid          : String {get}
    static var permissions   : CBAttributePermissions {get}
    static var properties    : CBCharacteristicProperties {get}
    static var initialValue  : NSData? {get}
}
```

**Description**

<table>
	<tr>
		<td>name</td>
		<td>Characteristic name</td>
	</tr>
  <tr>
		<td>uuid</td>
		<td>Characteristic UUID</td>
  </tr>
  <tr>
		<td>permissions</td>
		<td><a href="https://developer.apple.com/library/mac/documentation/CoreBluetooth/Reference/CBMutableCharacteristic_Class/index.html#//apple_ref/swift/struct/CBAttributePermissions">CBAttributePermissions</a></td>
  </tr>
  <tr>
		<td>properties</td>
		<td><a href="https://developer.apple.com/library/ios/documentation/CoreBluetooth/Reference/CBCharacteristic_Class/#//apple_ref/swift/struct/CBCharacteristicProperties">CBCharacteristicProperties</a></td>
  </tr>
  <tr>
		<td>initialValue</td>
		<td>Characteristic initial value</td>
  </tr>
</table>

### StringDeserializable Protocol

The StringDeserializable protocol is used to specify conversion of rawValues to Strings and is defined by,

```swift
public protocol StringDeserializable {
    static var stringValues : [String] {get}
    var stringValue         : [String:String] {get}
    init?(stringValue:[String:String])
}
```

**Description**

<table>
	<tr>
		<td>stringValues</td>
		<td>Used for enums to specify Strings for values but ignored for other types</td>
	</tr>
  <tr>
		<td>stringValue</td>
		<td>The String values of the rawType</td>
  </tr>
  <tr>
		<td>init?(stringValue:[String:String])</td>
		<td>Create object from stringValue</td>
  </tr>
</table>

### ConfiguredServiceProfile

A ConfiguredServiceProfile object encapsulates a service configuration that cab be used to instantiate either Service of MutableService object. 

```swift
struct AccelerometerService : ServiceConfigurable  {
  static let uuid  = "F000AA10-0451-4000-B000-000000000000"
  static let name  = "TI Accelerometer"
  static let tag   = "TI Sensor Tag"
}
```

```swift
let serviceProfile = ConfiguredServiceProfile<AccelerometerService>() 
```

The CharacteristicProfiless belonging to a ServiceProfile are added using the method,

```swift
public func addCharacteristic(characteristicProfile:CharacteristicProfile)
```
 
### CharacteristicProfile

CharacteristicProfile is the base class for each of the following profile types and is instantiated as the characteristic profile if a profile is not explicitly defined for a discovered characteristic. In this case with no String conversions implemented in a GATT Profile definition a characteristic will support String conversions to a from hexadecimal Strings.

When defining GATT profile it is sometimes convenient to specify that something be done to the Peripheral after a characteristic is discovered by the Central.

```swift
public func afterDiscovered(capacity:Int?) -> FutureStream<Characteristic>
``` 

### RawCharacteristicProfile

A RawCharacteristicProfile object encapsulates configuration and String conversions for a characteristic implementing RawDeserializable. It can be used to instantiate both Characteristics and Mutable Characteristics.

```swift
enum Enabled : UInt8, RawDeserializable, StringDeserializable, CharacteristicConfigurable {
  case No     = 0
  case Yes    = 1

  // CharacteristicConfigurable
  static let uuid = "F000AA12-0451-4000-B000-000000000000"
  static let name = "Accelerometer Enabled"
  static let properties = CBCharacteristicProperties.Read | CBCharacteristicProperties.Write
  static let permissions = CBAttributePermissions.Readable | CBAttributePermissions.Writeable
  static let initialValue : NSData? = Serde.serialize(Enabled.No.rawValue)
    
  // StringDeserializable
  static let stringValues = ["No", "Yes"]
    
  init?(stringValue:[String:String]) {
    if let value = stringValue[Enabled.name] {
      switch value {
      case "Yes":
        self = Enabled.Yes
      case "No":
        self = Enabled.No
      default:
        return nil
      }
    } else {
      return nil
    }
  }
    
  var stringValue : [String:String] {
    switch self {
      case .No:
        return [Enabled.name:"No"]
      case .Yes:
        return [Enabled.name:"Yes"]
    }
  }
}
```

To instantiate a profile,

```swift
let profile = RawCharacteristicProfile<Enabled>()
```

### RawArrayCharacteristicProfile

A RawArrayCharacteristicProfile object encapsulates configuration and String conversions for a characteristic implementing RawArrayDeserializable. It can be used to instantiate both Characteristics and Mutable Characteristics.

```swift
struct ArrayData : RawArrayDeserializable, CharacteristicConfigurable, StringDeserializable {
  // CharacteristicConfigurable
  static let uuid = "F000AA11-0451-4000-B000-000000000000"
  static let name = "Accelerometer Data"
  static let properties = CBCharacteristicProperties.Read | CBCharacteristicProperties.Notify
  static let permissions = CBAttributePermissions.Readable | CBAttributePermissions.Writeable
  static let initialValue : NSData? = Serde.serialize(ArrayData(rawValue:[1,2])!)
    
  // RawArrayDeserializable
  let rawValue : [Int8]
  static let size = 2
    
  init?(rawValue:[Int8]) {
    if rawValue.count == 2 {
      self.rawValue = rawValue
    } else {
      return nil
    }
  }
    
  // StringDeserializable
  static let stringValues = [String]()
    
  var stringValue : Dictionary<String,String> {
    return ["value1":"\(self.rawValue[0])",
            "value2":"\(self.rawValue[1])"]
  }
    
  init?(stringValue:[String:String]) {
    if  let stringValue1 = stringValue["value1"],
            stringValue2 = stringValue["value2"],
            value1 = Int8(stringValue:stringValue1),
            value2 = Int8(stringValue:stringValue2) {
      self.rawValue = [value1, value2]
    } else {
      return nil
    }
  }
}
```

To instantiate a profile,

```swift
let profile = RawArrayCharacteristicProfile<ArrayData>()
```

### RawPairCharacteristicProfile

A RawPairCharacteristicProfile object encapsulates configuration and String conversions for a characteristic implementing RawPairDeserializable. It can be used to instantiate both Characteristics and Mutable Characteristics.

```swift
struct PairData : RawPairDeserializable, CharacteristicConfigurable, StringDeserializable {    
  // CharacteristicConfigurable
  static let uuid = "F000AA30-0451-4000-B000-000000000000"
  static let name = "Magnetometer Data"
  static let properties = CBCharacteristicProperties.Read | CBCharacteristicProperties.Notify
  static let permissions = CBAttributePermissions.Readable | CBAttributePermissions.Writeable
  static let initialValue : NSData? = Serde.serialize(PairData(rawValue1:10, rawValue2:-10)!)
    
  // RawArrayDeserializable
  let rawValue1 : UInt8
  let rawValue2 : Int8
    
  init?(rawValue1:UInt8, rawValue2:Int8) {
    self.rawValue1 = rawValue1
    self.rawValue2 = rawValue2
  }
    
  // StringDeserializable
  static let stringValues = [String]()
    
  var stringValue : Dictionary<String,String> {
    return ["value1":"\(self.rawValue1)",
            "value2":"\(self.rawValue2)"]}
    
  init?(stringValue:[String:String]) {
    if  let stringValue1 = stringValue["value1"],
            stringValue2 = stringValue["value2"],
            value1 = UInt8(stringValue:stringValue1),
            value2 = Int8(stringValue:stringValue2) {
      self.rawValue1 = value1
      self.rawValue2 = value2
    } else {
      return nil
    }
  }            
}
```

To instantiate a profile,

```swift
let profile = RawPairCharacteristicProfile<PairData>()
```

### RawArrayPairCharacteristicProfile

A RawArrayPairCharacteristicProfile object encapsulates configuration and String conversions for a characteristic implementing RawArrayPairDeserializable. It can be used to instantiate both Characteristics and Mutable Characteristics.

```swift
struct ArrayPairData : RawArrayPairDeserializable, CharacteristicConfigurable, StringDeserializable {    
  // CharacteristicConfigurable
  static let uuid = "F000AA11-0451-4000-B000-000000000000"
  static let name = "Accelerometer Data"
  static let properties = CBCharacteristicProperties.Read | CBCharacteristicProperties.Notify
  static let permissions = CBAttributePermissions.Readable | CBAttributePermissions.Writeable
static let initialValue : NSData? = Serde.serialize()
            
	// RawArrayDeserializable
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
            
	// StringDeserializable
	static let stringValues = [String]()
            
	var stringValue : Dictionary<String,String> {
	  return ["value11":"\(self.rawValue1[0])",
            "value12":"\(self.rawValue1[1])"],
            "value21":"\(self.rawValue2[0])",
            "value22":"\(self.rawValue2[1])"]}

  init?(stringValue:[String:String]) {
	  if  let stringValue11 = stringValue["value11"], 
				 	  stringValue12 = stringValue["value12"]
            value11 = Int8(stringValue:stringValue11),
					  value12 = Int8(stringValue:stringValue12),
					  stringValue21 = stringValue["value21"], 
					  stringValue22 = stringValue["value22"]
            value21 = Int8(stringValue:stringValue21),
					  value22 = Int8(stringValue:stringValue22) {
        self.rawValue1 = [value11, value12]
        self.rawValue2 = [value21, value22]
    } else {
        return nil
    }
  }            
}
```

To instantiate a profile,

```swift
let profile = RawArrayPairCharacteristicProfile<ArrayPairData>()
```

### StringCharacteristicProfile

A String Profile only requires the implementation of characteristic

```swift
struct SerialNumber : CharacteristicConfigurable {
  // CharacteristicConfigurable
  static let uuid = "2a25"
  static let name = "Device Serial Number"
  static let permissions  = CBAttributePermissions.Readable | CBAttributePermissions.Writeable
  static let properties   = CBCharacteristicProperties.Read
  static let initialValue = Serde.serialize("AAA11")          
}
```

To instantiate a profile,

```swift
let profile = StringCharacteristicProfile<SerialNumber>()
```

### ProfileManager

ProfileManager is used by the BlueCap app as a repository of GATT profiles to be used to instantiate Services and Characteristics. ProfileManager can be used in an implementation but is not required by the framework.

To add ServiceProfiles and CharacteristicProfiles to ProfileManager,

```swift
let profileManager = ProfileManager.sharedInstance

let serviceProfile = ConfiguredServiceProfile<AccelerometerService>()

let enabledProfile = RawCharacteristicProfile<Enabled>()
let rawArrayProfile = RawArrayCharacteristicProfile<ArrayData>()

serviceProfile.addCharacteristic(enabledProfile)
serviceProfile.addCharacteristic(rawArrayProfile)

profileManager.addService(serviceProfile)
```

### Add Profile to BlueCap App

To add a GATT Profile to the BlueCap app you need to add a file to the project containing all Service and Characteristic profile definitions with public access level. See [GnosusProfiles](https://github.com/troystribling/BlueCap/blob/master/BlueCapKit/Service%20Profile%20Definitions/GnosusProfiles.swift) in the BlueCap Project fro an example. A very simple but illustrative example is to consider a Service with a single Characteristic.

```swift
public struct MyServices {
    
    // Service
    public struct NumberService : ServiceConfigurable  {
        public static let uuid  = "F000AA10-0451-4000-B000-000000000000"
        public static let name  = "NumberService"
        public static let tag   = "My Services"
    }
    
    // Characteristic
    public struct Number : RawDeserializable, StringDeserializable, CharacteristicConfigurable {
        
        public let rawValue : Int16
        
        public init?(rawValue:Int16) {
            self.rawValue = rawValue
        }
        
        public static let uuid = "F000AA12-0451-4000-B000-000000000000"
        public static let name = "Number"
        public static let properties = CBCharacteristicProperties.Read | CBCharacteristicProperties.Write
        public static let permissions = CBAttributePermissions.Readable | CBAttributePermissions.Writeable
        public static let initialValue : NSData? = Serde.serialize(Int16(22))
        
        public static let stringValues = [String]()
        
        public init?(stringValue:[String:String]) {
            if let svalue = stringValue[Number.name], value = Int16(stringValue:svalue) {
                self.rawValue = value
            } else {
                return nil
            }
        }
        
        public var stringValue : [String:String] {
            return [Number.name:"\(self.rawValue)"]
        }
    }
    
    // add to ProfileManager
    public static func create() {
        let profileManager = ProfileManager.sharedInstance
        let service = ConfiguredServiceProfile<NumberService>()
        let characteristic = RawCharacteristicProfile<Number>()
        service.addCharacteristic(characteristic)
        profileManager.addService(service)
    }
    
}
```

Next place,

```swift
MyServices.create()
```

in the BlueCap [AppDelegate.swift](https://github.com/troystribling/BlueCap/blob/master/BlueCap/AppDelegate.swift#L37-40) and rebuild the app.

## <a name="central">CentralManager</a>

The BlueCap CentralManager implementation replaces [CBCentralManagerDelegate](https://developer.apple.com/library/prerelease/ios/documentation/CoreBluetooth/Reference/CBCentralManagerDelegate_Protocol/index.html#//apple_ref/occ/intf/CBCentralManagerDelegate) and [CBPeripheralDelegate](https://developer.apple.com/library/prerelease/ios/documentation/CoreBluetooth/Reference/CBPeripheralDelegate_Protocol/index.html#//apple_ref/occ/intf/CBPeripheralDelegate) protocol implementations with with a Scala futures interface using [SimpleFutures](https://github.com/troystribling/SimpleFutures). Futures provide inline implementation of asynchronous callbacks and allow chaining asynchronous calls as well as error handling and recovery. Also, provided are callbacks for connections events and connection and service scan timeouts. This section will describe interfaces and give example implementations for all supported use cases. [Simple Example](https://github.com/troystribling/BlueCap/tree/master/Examples) applications can be found in the BlueCap project.

### PowerOn/PowerOff

The state of the Bluetooth transceiver on a device is communicated to BlueCap CentralManager by the powerOn and powerOff futures,

```swift
public func powerOn() -> Future<Void>
public func powerOff() -> Future<Void>
```
Both methods return a [SimpleFutures](https://github.com/troystribling/SimpleFutures) Future<Void> yielding Void. For an application to process events,

```swift
let manager = CentralManager.sharedInstance
let powerOnFuture = manager.powerOn()
powerOnFuture.onSuccess {
  …
}
let powerOffFuture = manager.powerOff()
powerOffFuture.onSuccess {
	…
}
``` 

When CentralManager is instantiated a message giving the current Bluetooth transceiver state is received and while the CentralManager is instantiated messages are received if the transceiver is powered or powered off.

### <a name="peripheraldiscovered">Service Scanning</a>

CentralManager scans for advertising peripherals are initiated by calling the CentralManager methods,

```swift
// Scan promiscuously for all advertising peripherals
public func startScanning(capacity:Int? = nil) -> FutureStream<Peripheral>

// Scan for peripherals advertising services with UUIDs
public func startScanningForServiceUUIDs(uuids:[CBUUID]!, capacity:Int? = nil) -> FutureStream<Peripheral>
``` 

Both methods return a [SimpleFutures](https://github.com/troystribling/SimpleFutures) FutureStream&lt;Peripheral&gt; yielding the discovered peripheral and take the FutureStream capacity as input.

For an application to scan for peripherals advertising services with uuids after powerOn,

```swift
let manager = CentralManager.sharedInstance
let serviceUUID = CBUUID(string:"F000AA10-0451-4000-B000-000000000000")!

let peripheraDiscoveredFuture = manager.powerOn().flatmap {_ -> FutureStream<Peripheral> in
	manager.startScanningForServiceUUIDs([serviceUUID], capacity:10)
}
peripheraDiscoveredFuture.onSuccess {peripheral in
	…
}
```

Here the powerOn future has been flatmapped to startScanning(capacity:Int?) -> FutureStream<Peripheral> to ensure that the service scan starts after the bluetooth transceiver is powered on.

To stop a peripheral scan use the CentralManager method,

```swift
public func stopScanning()
```

and in an application,

```swift
let manager = CentralManager.sharedInstance
manager.stopScanning()
```

### Service Scanning with timeout

CentralManager can scan for advertising peripherals with a timeout. TimedScannerator methods are used to start a scan instead ob the CentralManager methods. The declarations include a timeout parameter but are otherwise the same,

```swift
// Scan promiscuously for all advertising peripherals
public func startScanning(timeoutSeconds:Double, capacity:Int? = nil) -> FutureStream<Peripheral>

// Scan for peripherals advertising services with UUIDs
public func startScanningForServiceUUIDs(timeoutSeconds:Double, uuids:[CBUUID]!, capacity:Int? = nil) -> FutureStream<Peripheral>
``` 

Both methods return a [SimpleFutures](https://github.com/troystribling/SimpleFutures) FutureStream&lt;Peripheral&gt; yielding the discovered peripheral and take the FutureStream capacity as input.

For an application to scan for peripherals advertising services  with uuids and a specified timeout after powerOn,

```swift
let manager = CentralManager.sharedInstance
let serviceUUID = CBUUID(string:"F000AA10-0451-4000-B000-000000000000")!

let peripheraDiscoveredFuture = manager.powerOn().flatmap {_ -> FutureStream<Peripheral> in
	TimedScannerator.sharedinstance.startScanningForServiceUUIDs(10.0, uuids:[serviceUUID], capacity:10)
}
peripheraDiscoveredFuture.onSuccess {peripheral in
	…
}
peripheraDiscoveredFuture.onFailure {error in
	…
}
```

Here the powerOn future has been flatmapped to startScanning(capacity:Int?) -> FutureStream<Peripheral> to ensure that the service scan starts after the bluetooth transceiver is powered on. On timeout peripheraDiscoveredFuture will complete with error BCError.peripheralDiscoveryTimeout.

To stop a peripheral scan use the TimedScannerator method,

```swift
public func stopScanning()
```

and in an application,

```swift
TimedScannerator.sharedInstance.stopScanning()
```

### <a name="peripheralconnect">Peripheral Connection</a>

After discovering a peripheral a connection must be established to begin messaging. Connecting and maintaining a connection to a bluetooth device can be difficult since signals are weak and devices may have relative motion. BlueCap provides connection events to enable applications to easily handle anything that can happen. ConnectionEvent is an enum with values,

<table>
  <tr>
    <th>Event</th>
    <th>Description</th>
  </tr>
	<tr>
		<td>Connect</td>
		<td>Connected to peripheral</td>
	</tr>
	<tr>
		<td>Timeout</td>
		<td>Connection attempt timeout</td>
	</tr>
	<tr>
		<td>Disconnect</td>
		<td>Peripheral disconnected</td>
	</tr>
	<tr>
		<td>ForceDisconnect</td>
		<td>Peripheral disconnected by application</td>
	</tr>
	<tr>
		<td>Failed</td>
		<td>Connection failed without error</td>
	</tr>
	<tr>
		<td>GiveUp</td>
		<td>Give-up trying to connect.</td>
	</tr>
</table>

To connect to a peripheral use The BlueCap Peripheral method,

```swift
public func connect(capacity:Int? = nil, timeoutRetries:UInt? = nil, disconnectRetries:UInt? = nil, connectionTimeout:Double = 10.0) -> FutureStream<(Peripheral, ConnectionEvent)>
```

**Discussion**

BlueCap Peripheral connect returns a [SimpleFutures](https://github.com/troystribling/SimpleFutures) FutureStream&lt;(Peripheral, ConnectionEvent)&gt; yielding a tuple containing the connected peripheral and the ConnectionEvent.

<table>
	<tr>
		<td>capacity</td>
		<td>FutureStream capacity</td>
	</tr>
	<tr>
		<td>timeoutRetries</td>
		<td>Number of connection retries on timeout. Equals 0 if nil.</td>
	</tr>
	<tr>
		<td>disconnectRetries</td>
		<td>Number of connection retries on disconnect. Equals 0 if nil.</td>
	</tr>
	<tr>
		<td>connectionTimeout</td>
		<td>Connection timeout in seconds. Default is 10s.</td>
	</tr>
</table>

Other BlueCap Peripheral connection management methods are,

```swift
// Reconnect peripheral if disconnected
public func reconnect()

// Disconnect peripheral
public func disconnect()

// Terminate peripheral
public func terminate()
```

An application can connect a BlueCap Peripheral using,

```swift
let manager = CentralManager.sharedInstance
let serviceUUID = CBUUID(string:"F000AA10-0451-4000-B000-000000000000")!

let peripheralConnectFuture = manager.powerOn().flatmap {_ -> FutureStream<Peripheral> in
	manager.startScanningForServiceUUIDs([serviceUUID], capacity:10)
}.flatmap{peripheral -> FutureStream<(Peripheral, ConnectionEvent)> in
	return peripheral.connect(capacity:10, timeoutRetries:5, disconnectRetries:5, connectionTimeout:10.0)
}
peripheralConnectFuture.onSuccess {(peripheral, connectionEvent) in
	switch connectionEvent {
  case .Connect:
	  …
  case .Timeout:
    peripheral.reconnect()
		…
  case .Disconnect:
    peripheral.reconnect()
		…
  case .ForceDisconnect:
	  …
  case .Failed:
	  …
  case .GiveUp:
	  peripheral.terminate()
		…
  }
}
peripheralConnectFuture.onFailure {error in
	…
}
```

Here the [peripheraDiscoveredFuture](#peripheraldiscovered) from the previous section is flatmapped to connect(capacity:Int? = nil, timeoutRetries:UInt, disconnectRetries:UInt?, connectionTimeout:Double) -> FutureStream<(Peripheral, ConnectionEvent)> to ensure that connections are made after peripherals are discovered. When ConnectionEvents of .Timeout and .Disconnect are received an attempt is made to reconnect the peripheral. The connection is configured for a maximum of 5 timeout retries and 5 disconnect retries. If either of these thresholds is exceeded a .GiveUp event is received and the peripheral connection is terminated ending all reconnection attempts.

### <a name="characteristicdiscovery">Service and Characteristic Discovery</a>

After a peripheral is connected its services and characteristics must be discovered before characteristic values can be read or written to or update notifications can be received.

There are several BlueCap Peripheral methods that can be used to discover services and characteristics. To discover both BlueCap Services and Characteristics use,

```swift
// Discover services and characteristics for services with UUIDs
public func discoverPeripheralServices(services:[CBUUID]!) -> Future<Peripheral>

// Discover all services and characteristics
public func discoverAllPeripheralServices() -> Future<Peripheral>
```

Both methods return a [SimpleFutures](https://github.com/troystribling/SimpleFutures) Future&lt;Peripheral&gt; yielding the connected peripheral.

An application can discover a BlueCap Peripheral using,

```swift
// errors
public enum ApplicationErrorCode : Int {
    case PeripheralNotConnected = 1
}

public struct ApplicationError {
    public static let domain = "Application"
    public static let peripheralNotConnected = NSError(domain:domain, code:ApplicationErrorCode.PeripheralNotConnected.rawValue, userInfo:[NSLocalizedDescriptionKey:"Peripheral not connected"])
}
…
// peripheralConnectFuture and serviceUUID are defined in previous section
…
let characteristicsDiscoveredFuture = peripheralConnectFuture.flatmap {(peripheral, connectionEvent) -> Future<Peripheral> in
	if peripheral.state == .Connected {
	  return peripheral.discoverPeripheralServices([serviceUUID])
	} else {
	  let promise = Promise<Peripheral>()
    promise.failure(ApplicationError.peripheralNotConnected)
    return promise.future
  }
}
characteristicsDiscoveredFuture.onSuccess {peripheral in
	…
}
characteristicsDiscoveredFuture.onFailure {error in
	…
}
```

Here the [peripheralConnectFuture](#peripheralconnect) from the previous section is flatmapped to discoverPeripheralServices(services:[CBUUID]!) -> Future<Peripheral> to ensures that the peripheral is connected before service and characteristic discovery starts. Also, the peripheral is discovered only if it is connected and an error is returned if the peripheral is not connected.

### Characteristic Write

After a peripherals characteristics are discovered writing characteristic values is possible. Several BlueCap Characteristic methods are available,

```swift
// Write an NSData object to characteristic value
public func writeData(value:NSData, timeout:Double = 10.0) -> Future<Characteristic>

// Write a characteristic String Dictionary value
public func writeString(stringValue:[String:String], timeout:Double = 10.0) -> Future<Characteristic>

// Write a Deserializable characteristic value
public func write<T:Deserializable>(value:T, timeout:Double = 10.0) -> Future<Characteristic>

// Write a RawDeserializable characteristic value
public func write<T:RawDeserializable>(value:T, timeout:Double = 10.0) -> Future<Characteristic>

// Write a RawArrayDeserializable characteristic value
public func write<T:RawArrayDeserializable>(value:T, timeout:Double = 10.0) -> Future<Characteristic>

// Write a RawPairDeserializable characteristic value
public func write<T:RawPairDeserializable>(value:T, timeout:Double = 10.0) -> Future<Characteristic>

// Write a RawArrayPairDeserializable characteristic value
public func write<T:RawArrayPairDeserializable>(value:T, timeout:Double = 10.0) -> Future<Characteristic>
```

Using the [RawDeserializable enum](#rawdeserializable) an application can write a BlueCap Characteristic as follows,

```swift
// errors
public enum ApplicationErrorCode : Int {
    case CharacteristicNotFound = 1
}

public struct ApplicationError {
    public static let domain = "Application"
    public static let characteristicNotFound = NSError(domain:domain, code:ApplicationErrorCode.CharacteristicNotFound.rawValue, userInfo:[NSLocalizedDescriptionKey:"Characteristic Not Found"])
}

// RawDeserializable enum
enum Enabled : UInt8, RawDeserializable {
    case No  = 0
    case Yes = 1
    public static let uuid = "F000AA12-0451-4000-B000-000000000000"
}
let enabledUUID = CBUUID(string:Enabled.uuid)!
…
// characteristicsDiscoveredFuture and serviceUUID 
// are defined in a previous section
…
let writeCharacteristicFuture = characteristicsDiscoveredFuture.flatmap {peripheral -> Future<Characteristic> in
	if let service = peripheral.service(serviceUUID), characteristic = service.characteristic(enabledUUID) {
		return characteristic.write(Enabled.Yes, timeout:20.0)
	} else {
		let promise = Promise<Characteristic>()
		promise.failure(ApplicationError.characteristicNotFound)
		return promise.future
	}
}
writeCharacteristicFuture.onSuccess {characteristic in
	…
}
writeCharacteristicFuture.onFailure {error in
	…
}
```

Here the [characteristicsDiscoveredFuture](#characteristicdiscovery) previously defined is flatmapped to func write<T:RawDeserializable>(value:T, timeout:Double) -> Future<Characteristic> to ensure that characteristic has been discovered before writing. An error is returned if the characteristic is not found. 

### Characteristic Read

After a peripherals characteristics are discovered reading characteristic values is possible. Several BlueCap Characteristic methods are available,

```swift
// Read a characteristic from a peripheral service
public func read(timeout:Double = 10.0) -> Future<Characteristic>

// Return the characteristic value as and NSData object
public var dataValue : NSData!

// Return the characteristic value as a String Dictionary.
public var stringValue :[String:String]?

// Return a Deserializable characteristic value
public func value<T:Deserializable>() -> T?

// Return a RawDeserializable characteristic value
public func value<T:RawDeserializable where T.RawType:Deserializable>() -> T?

// Return a RawArrayDeserializable characteristic value
public func value<T:RawArrayDeserializable where T.RawType:Deserializable>() -> T?

// Return a RawPairDeserializable characteristic value
public func value<T:RawPairDeserializable where T.RawType1:Deserializable, T.RawType2:Deserializable>() -> T?
```

Using the [RawDeserializable enum](#rawdeserializable) an application can read a BlueCap Characteristic as follows,

```swift
// errors
public enum ApplicationErrorCode : Int {
    case CharacteristicNotFound = 1
}

public struct ApplicationError {
    public static let domain = "Application"
    public static let characteristicNotFound = NSError(domain:domain, code:ApplicationErrorCode.CharacteristicNotFound.rawValue, userInfo:[NSLocalizedDescriptionKey:"Characteristic Not Found"])
}

// RawDeserializable enum
enum Enabled : UInt8, RawDeserializable {
    case No  = 0
    case Yes = 1
    public static let uuid = "F000AA12-0451-4000-B000-000000000000"
}
let enabledUUID = CBUUID(string:Enabled.uuid)!
…
// characteristicsDiscoveredFuture and serviceUUID 
// are defined in a previous section
…
let readCharacteristicFuture = characteristicsDiscoveredFuture.flatmap {peripheral -> Future<Characteristic> in
	if let service = peripheral.service(serviceUUID), characteristic = service.characteristic(enabledUUID) {
		return characteristic.read(timeout:20.0)
	} else {
		let promise = Promise<Characteristic>()
		promise.failure(ApplicationError.characteristicNotFound)
		return promise.future
	}
}
writeCharacteristicFuture.onSuccess {characteristic in
	if let value : Enabled = characteristic.value {
		…
	}
}
writeCharacteristicFuture.onFailure {error in
	…
}
```

Here the [characteristicsDiscoveredFuture](#characteristicdiscovery) previously defined is flatmapped to read(timeout:Double) -> Future<Characteristic> to ensure that characteristic has been discovered before reading. An error is returned if the characteristic is not found. 

### Characteristic Update Notifications

After a peripherals characteristics are discovered subscribing to characteristic value update notifications is possible. Several BlueCap Characteristic methods are available,

```swift
// subscribe to characteristic update
public func startNotifying() -> Future<Characteristic>

// receive characteristic value updates
public func recieveNotificationUpdates(capacity:Int? = nil) -> FutureStream<Characteristic>

// unsubscribe from characteristic updates
public func stopNotifying() -> Future<Characteristic>

// stop receiving characteristic value updates
public func stopNotificationUpdates()
```

Using the [RawDeserializable enum](#rawdeserializable) an application can receive notifications from a BlueCap Characteristic as follows,

```swift
// errors
public enum ApplicationErrorCode : Int {
    case CharacteristicNotFound = 1
}

public struct ApplicationError {
    public static let domain = "Application"
    public static let characteristicNotFound = NSError(domain:domain, code:ApplicationErrorCode.CharacteristicNotFound.rawValue, userInfo:[NSLocalizedDescriptionKey:"Characteristic Not Found"])
}

// RawDeserializable enum
enum Enabled : UInt8, RawDeserializable {
    case No  = 0
    case Yes = 1
    public static let uuid = "F000AA12-0451-4000-B000-000000000000"
}
let enabledUUID = CBUUID(string:Enabled.uuid)!
…
// characteristicsDiscoveredFuture and serviceUUID 
// are defined in a previous section
…
let subscribeCharacteristicFuture = characteristicsDiscoveredFuture.flatmap {peripheral -> Future<Characteristic> in
	if let service = peripheral.service(serviceUUID), characteristic = service.characteristic(enabledUUID) {
		return characteristic.startNotifying()
	} else {
		let promise = Promise<Characteristic>()
		promise.failure(ApplicationError.characteristicNotFound)
		return promise.future
	}
}
subscribeCharacteristicFuture.onSuccess {characteristic in
	…
}
subscribeCharacteristicFuture.onFailure {error in
	…
}

let updateCharacteristicFuture = subscribeCharacteristicFuture.flatmap{characteristic -> FutureStream<Characteristic> in
	return characteristic.recieveNotificationUpdates(capacity:10)
}
updateCharacteristicFuture.onSuccess {characteristic in
	if let value : Enabled = characteristic.value {
		…
	}
}
updateCharacteristicFuture.onFailure {error in 
}
```

Here the [characteristicsDiscoveredFuture](#characteristicdiscovery) previously defined is flatmapped to startNotifying() -> Future<Characteristic> to ensure that characteristic has been discovered before subscribing to updates.  An error is returned if the characteristic is not found. Then updateCharacteristicFuture is flatmapped again to recieveNotificationUpdates(capacity:Int?) -> FutureStream<Characteristic> to ensure that the subsections is completed before receiving updates.

For an application to unsubscribe to characteristic value updates and stop receiving updates,

```swift
// serviceUUID and enabledUUID are define in the example above
if let service = peripheral.service(serviceUUID), characteristic = service.characteristic(enabledUUID) {
	// stop receiving updates
	characteristic.stopNotificationUpdates()

	// unsubscribe to notifications
	characteristic.stopNotifying()
}
```

## <a name="peripheral">PeripheralManager</a>

The BlueCap PeripheralManager implementation replaces [CBPeripheralManagerDelegate](https://developer.apple.com/library/prerelease/ios/documentation/CoreBluetooth/Reference/CBPeripheralManagerDelegate_Protocol/index.html#//apple_ref/occ/intf/CBPeripheralManagerDelegate) protocol implementations with with a Scala futures interface using [SimpleFutures](https://github.com/troystribling/SimpleFutures). Futures provide inline implementation of asynchronous callbacks and allows chaining asynchronous calls as well as error handling and recovery. This section will describe interfaces and give example implementations for all supported use cases. [Simple Example](https://github.com/troystribling/BlueCap/tree/master/Examples) applications can be found in the BlueCap github repository.

### PowerOn/PowerOff

The state of the Bluetooth transceiver on a device is communicated to BlueCap PeripheralManager by the powerOn and powerOff futures,

```swift
public func powerOn() -> Future<Void>
public func powerOff() -> Future<Void>
```
Both methods return a [SimpleFutures](https://github.com/troystribling/SimpleFutures) Future<Void> yielding Void. For an application to process events,

```swift
let manager = PeripheralManager.sharedInstance
let powerOnFuture = manager.powerOn()
powerOnFuture.onSuccess {
  …
}
let powerOffFuture = manager.powerOff()
powerOffFuture.onSuccess {
	…
}
``` 

When PeripheralManager is instantiated a message giving the current Bluetooth transceiver state is received and while the PeripheralManager is instantiated messages are received if the transceiver is powered or powered off.

### Add Services and Characteristics

### Advertising



### Read Characteristic

### Set Characteristic Value

### Updating Characteristic Value

### iBeacon Emulation

