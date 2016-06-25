# <a name="gatt">GATT Profile Definition</a>

GATT profile definitions are required to add support for a device to the [BluCap](https://itunes.apple.com/us/app/bluecap/id931219725?mt=8#) app but are not required to build a functional application using the framework. Implementing a GATT profile for a device allows the framework to automatically identify and configure `Services` and `Characteristics` as the are created and provides serialization and deserialization of `Characteristic` values to and from Strings. The examples in this section are also available in a [Playground project](/Playgrounds).

## Use Cases

* [ServiceConfigurable Protocol](#gatt_serviceconfigurable): Define a `ServiceProfile` configuration.
* [CharacteristicConfigurable Protocol](#gatt_characteristicconfigurable): Define a `CharacteristicProfile` configuration.
* [StringDeserializable Protocol](#gatt_stringdeserializable): Convert `Characteristic` values to `Strings`.
* [ServiceProfile](#gatt_serviceprofile): Define an unconfigured `ServiceProfile`.
* [ConfiguredServiceProfile](#gatt_configuredserviceprofile): Define a `ServiceProfile` with configuration.
* [CharacteristicProfile](#gatt_characteristicprofile): `CharacteristicProfile` base class.
* [RawCharacteristicProfile](#gatt_rawcharacteristicprofile): Define a `CharacteristicProfile` for messages supporting [`RawDeserializable`](/Documentation/SerializationDeserialization.md/#serde_rawdeserializable).
* [RawArrayCharacteristicProfile](#gatt_rawarraycharacteristicprofile): Define a `CharacteristicProfile `for messages supporting [`RawArrayDeserializable`](/Documentation/SerializationDeserialization.md/#serde_rawarraydeserializable).
* [RawPairCharacteristicProfile](#gatt_rawpaircharacteristicprofile): Define a `CharacteristicProfile` for messages supporting [`RawPairDeserializable`](/Documentation/SerializationDeserialization.md/#serde_rawpairdeserializable).
* [RawArrayPairCharacteristicProfile](#gatt_rawpaircharacteristicprofile): Define a `CharacteristicProfile` for messages supporting [`RawArrayPairDeserializable`](/Documentation/SerializationDeserialization.md/#serde_rawarraypairdeserializable).
* [StringCharacteristicProfile](#gatt_stringcharacteristicprofile): Define a `CharacteristicProfile` for `String` messages.
* [ProfileManager](#gatt_profilemanager): Manage access to profiles in a application.
* [Add Profile to BlueCap App](#gatt_add_profile): How t add a GATT profile to the BlueCap app.

## <a name="gatt_serviceconfigurable">ServiceConfigurable Protocol</a>

The `ServiceConfigurable` `protocol` is used to specify `Service` configuration and defined by,

```swift
public protocol ServiceConfigurable {
    static var name: String {get}
    static var UUID: String {get}
    static var tag: String {get}
}
```

**Description**

<table>
	<tr>
		<td>name</td>
		<td>Service name</td>
	</tr>
  <tr>
		<td>UUID</td>
		<td>Service UUID</td>
  </tr>
  <tr>
		<td>tag</td>
		<td>Used to organize services in the BlueCap app profile browser</td>
  </tr>
</table>

## <a name="gatt_characteristicconfigurable">CharacteristicConfigurable Protocol</a>

The `CharacteristicConfigurable` `protocol` is used to specify `Characteristic` configuration and defined by,

```swift
public protocol CharacteristicConfigurable {
    static var name: String {get}
    static var UUID: String {get}
    static var permissions: CBAttributePermissions {get}
    static var properties: CBCharacteristicProperties {get}
    static var initialValue: NSData? {get}
}
```

**Description**

<table>
	<tr>
		<td>name</td>
		<td>Characteristic name</td>
	</tr>
  <tr>
		<td>UUID</td>
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

## <a name="gatt_stringdeserializable">StringDeserializable Protocol</a>

The `StringDeserializable` `protocol` is used to specify conversion of rawValues to `Strings` and is defined by,

```swift
public protocol StringDeserializable {
    static var stringValues: [String] {get}
    var stringValue: [String:String] {get}
    init?(stringValue: [String:String])
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
		<td>init?(stringValue: [String:String])</td>
		<td>Create object from stringValue</td>
  </tr>
</table>

## <a name="gatt_serviceprofile">ServiceProfile</a>

A `ServiceProfile` is used to define `Service` configuration. It can be used to instantiate either `Service` or `MutableService` objects. 

```swift
let serviceProfile = ServiceProfile(UUID: "F000AA10-0451-4000-B000-000000000000", name: "Cool Service", rage) 
```

The `CharacteristicProfiles` belonging to a `ServiceProfile` are added using a method defined on `ServiceProfile`,

```swift
public func addCharacteristic(characteristicProfile: CharacteristicProfile)
```

## <a name="gatt_configuredserviceprofile">ConfiguredServiceProfile</a>

A `ConfiguredServiceProfile` object encapsulates a `Service` configuration and is a subclass of `ServiceProfile`. It can be used to instantiate either `Service` or `MutableService` objects. 

```swift
struct AccelerometerService : ServiceConfigurable  {
  static let UUID = "F000AA10-0451-4000-B000-000000000000"
  static let name = "TI Accelerometer"
  static let tag = "TI Sensor Tag"
}
```

```swift
let serviceProfile = ConfiguredServiceProfile<AccelerometerService>() 
```
 
## <a name="gatt_characteristicprofile">CharacteristicProfile</a>

`CharacteristicProfile` is the base class for `CharacteristicProfile` types and is instantiated as the default Characteristic profile if one has not explicitly defined for a discovered `Characteristic`. In this case, with no `String` conversions implemented in a GATT Profile definition, a `Characteristic` will support the default `String` conversions to and from `NSData` using hexadecimal Strings. It can be used to instantiate either `Characteristic` or `MutableCharacteristic` objects.

When defining a GATT profile it is sometimes convenient to specify that something be done after a `Characteristic` is discovered by a `Central`. This can be accomplished using the `CharacteristicProfile` method,

```swift
public func afterDiscovered(capacity: Int?) -> FutureStream<Characteristic>
```

## <a name="gatt_rawcharacteristicprofile">RawCharacteristicProfile</a>

A `RawCharacteristicProfile` object encapsulates configuration and serialization/desserialization for a `Characteristic` implementing [RawDeserializable](/Documentation/SerializationDeserialization.md/#serde_rawdeserializable). It can be used to instantiate both `Characteristic` and `MutableCharacteristic` objects and is a subclass of `CharacteristicProfile`

The `CharacteristicProfile` type for the [TiSensorTag Accelerometer Service](BlueCapKit/Service%20Profile%20Definitions/TISensorTagServiceProfiles.swift) Enabled `Characteristic` implementing `RawDeserializable`, `StringDeserializable`, `CharacteristicConfigurable` is given by,

```swift
enum Enabled : UInt8, RawDeserializable, StringDeserializable, CharacteristicConfigurable {
  case No     = 0
  case Yes    = 1

  // CharacteristicConfigurable
  static let UUID = "F000AA12-0451-4000-B000-000000000000"
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

To instantiate a profile in an application,

```swift
let profile = RawCharacteristicProfile<Enabled>()
```

## <a name="gatt_rawarraycharacteristicprofile">RawArrayCharacteristicProfile</a>

A RawArrayCharacteristicProfile object encapsulates configuration and serialization/deserialization for a characteristic implementing [RawArrayDeserializable](/Documentation/SerializationDeserialization.md/#serde_rawarraydeserializable). It can be used to instantiate both Characteristic and MutableCharacteristic objects. An example profile for an `[Int8]` raw value implementing `RawArrayDeserializable`, `CharacteristicConfigurable` and `StringDeserializable` is given by,

```swift
struct ArrayData : RawArrayDeserializable, CharacteristicConfigurable, StringDeserializable {
  // CharacteristicConfigurable
  static let UUID = "F000AA11-0451-4000-B000-000000000000"
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

To instantiate a profile in an application,

```swift
let profile = RawArrayCharacteristicProfile<ArrayData>()
```

## <a name="gatt_rawpaircharacteristicprofile">RawPairCharacteristicProfile</a>

A RawPairCharacteristicProfile object encapsulates configuration and serialization/deserialization for a characteristic implementing [RawPairDeserializable](/Documentation/SerializationDeserialization.md/#serde_rawpairdeserializable). It can be used to instantiate both `Characteristic` and `MutableCharacteristic` objects. An example profile for `UInt8` and `Int8` raw values implementing `RawPairDeserializable`, `CharacteristicConfigurable` and `StringDeserializable` is given by,

```swift
struct PairData : RawPairDeserializable, CharacteristicConfigurable, StringDeserializable {    
  // CharacteristicConfigurable
  static let UUID = "F000AA30-0451-4000-B000-000000000000"
  static let name = "Magnetometer Data"
  static let properties = CBCharacteristicProperties.Read | CBCharacteristicProperties.Notify
  static let permissions = CBAttributePermissions.Readable | CBAttributePermissions.Writeable
  static let initialValue : NSData? = Serde.serialize(PairData(rawValue1:10, rawValue2:-10)!)
    
  // RawPairDeserializable
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

To instantiate a profile in an application,

```swift
let profile = RawPairCharacteristicProfile<PairData>()
```

## <a name="gatt_rawarraypaircharacteristicprofile">RawArrayPairCharacteristicProfile</a>

A `RawArrayPairCharacteristicProfile` object encapsulates configuration and serialization/deserialization for a characteristic implementing [RawArrayPairDeserializable](/Documentation/SerializationDeserialization.md/#serde_rawarraypairdeserializable). It can be used to instantiate both `Characteristic` and `MutableCharacteristic` objects. An example profile for `[UInt8]` and `[Int8]` raw values implementing `RawArrayPairDeserializable`, `CharacteristicConfigurable` and `StringDeserializable` is given by,

```swift
struct ArrayPairData : RawArrayPairDeserializable, CharacteristicConfigurable, StringDeserializable {    
  // CharacteristicConfigurable
  static let UUID = "F000AA11-0451-4000-B000-000000000000"
  static let name = "Accelerometer Data"
  static let properties = CBCharacteristicProperties.Read | CBCharacteristicProperties.Notify
  static let permissions = CBAttributePermissions.Readable | CBAttributePermissions.Writeable
static let initialValue : NSData? = Serde.serialize()
            
	// RawArrayPairDeserializable
	let rawValue1 : [UInt8]
	let rawValue2 : [Int8]
	static let UUID = "F000AA13-0451-4000-B000-000000000000"
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

To instantiate a profile in an application,

```swift
let profile = RawArrayPairCharacteristicProfile<ArrayPairData>()
```

## <a name="gatt_stringcharacteristicprofile">StringCharacteristicProfile</a>

A `StringCharacteristicProfile` only requires the implementation of CharacteristicConfigurable

```swift
struct SerialNumber : CharacteristicConfigurable {
  // CharacteristicConfigurable
  static let UUID = "2a25"
  static let name = "Device Serial Number"
  static let permissions  = CBAttributePermissions.Readable | CBAttributePermissions.Writeable
  static let properties   = CBCharacteristicProperties.Read
  static let initialValue = Serde.serialize("AAA11")          
}
```

To instantiate a profile in an application,

```swift
let profile = StringCharacteristicProfile<SerialNumber>()
```

## <a name="gatt_profilemanager">ProfileManager</a>

`ProfileManager` is used by the `BlueCap` app as a repository of GATT profiles to be used to instantiate `Services` and `Characteristics`. `ProfileManager` can be used in any application but is not required the framework.

A `ServiceProfile` is added to `ProfileManager` using a method defined on `ProfileManager`,

```swift
public func addService(serviceProfile: ServiceProfile) -> ServiceProfile 
```

To add `ServiceProfiles` and `CharacteristicProfiles` to `ProfileManager`,

```swift
let profileManager = ProfileManager.sharedInstance

// create service profile
let serviceProfile = ConfiguredServiceProfile<AccelerometerService>()

// create characteristic profiles
let enabledProfile = RawCharacteristicProfile<Enabled>()
let rawArrayProfile = RawArrayCharacteristicProfile<ArrayData>()

// add characteristic profiles to service profile
serviceProfile.addCharacteristic(enabledProfile)
serviceProfile.addCharacteristic(rawArrayProfile)

// add service profile too profile manager
profileManager.addService(serviceProfile)
```

## <a name="gatt_add_profile">Add Profile to BlueCap App</a>

To add a GATT Profile to the [BluCap](https://itunes.apple.com/us/app/bluecap/id931219725?mt=8#) app you need to add a file to the project containing all `ServiceProfiles` and `CharacteristicProfiles`  with public access level. See [GnosusProfiles](/BlueCapKit/Service%20Profile%20Definitions/GnosusProfiles.swift) in the BlueCap Project for an example. A very example is to consider a Service with a single Characteristic.


```swift
public struct MyServices {
    
    // Service
    public struct NumberService : ServiceConfigurable  {
        public static let UUID  = "F000AA10-0451-4000-B000-000000000000"
        public static let name  = "NumberService"
        public static let tag   = "My Services"
    }
    
    // Characteristic
    public struct Number : RawDeserializable, StringDeserializable, CharacteristicConfigurable {
        
        public let rawValue : Int16
        
        public init?(rawValue:Int16) {
            self.rawValue = rawValue
        }
        
        public static let UUID = "F000AA12-0451-4000-B000-000000000000"
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

in the BlueCap [AppDelegate.swift](/Examples/BlueCap/BlueCap/AppDelegate.swift#L57-60) and rebuild the app.
