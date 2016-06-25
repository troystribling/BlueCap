# <a name="gatt">GATT Profile Definition</a>

GATT profile definitions are required to add support for a device to the [BluCap](https://itunes.apple.com/us/app/bluecap/id931219725?mt=8#) app but are not required to build a functional application using the framework. Implementing a GATT profile for a device allows the framework to automatically identify and configure Services and Characteristics and provides serialization and deserialization of Characteristic values to and from Strings. The examples in this section are also available in a [Playground project](/Playgrounds).

## Use Cases

* [ServiceConfigurable Protocol](#gatt_serviceconfigurable): Define a service configuration.
* [CharacteristicConfigurable Protocol](#gatt_characteristicconfigurable): Define a characteristic configuration.
* [StringDeserializable Protocol](#gatt_stringdeserializable): Convert characteristic values to strings.
* [ConfiguredServiceProfile](#gatt_configuredserviceprofile): Define a service profile.
* [CharacteristicProfile](#gatt_characteristicprofile): Characteristic profile base class.
* [RawCharacteristicProfile](#gatt_rawcharacteristicprofile): Define a characteristic profile for messages supporting RawDeserializable. 
* [RawArrayCharacteristicProfile](#gatt_rawarraycharacteristicprofile): Define a characteristic profile for messages supporting RawArrayDeserializable.
* [RawPairCharacteristicProfile](#gatt_rawpaircharacteristicprofile): Define a characteristic profile for messages supporting RawPairDeserializable.
* [RawArrayPairCharacteristicProfile](#gatt_rawpaircharacteristicprofile): Define a characteristic profile for messages supporting RawArrayPairDeserializable.
* [StringCharacteristicProfile](#gatt_stringcharacteristicprofile): Define a characteristic profile for String messages.
* [ProfileManager](#gatt_profilemanager): How the BlueCap app manages GATT profiles.
* [Add Profile to BlueCap App](#gatt_add_profile): Add a GATT profile to the BlueCap app.

## <a name="gatt_serviceconfigurable">ServiceConfigurable Protocol</a>

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

## <a name="gatt_characteristicconfigurable">CharacteristicConfigurable Protocol</a>

The CharacteristicConfigurable is used to specify Characteristic configuration and is defined by,

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

## <a name="gatt_stringdeserializable">StringDeserializable Protocol</a>

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

## <a name="gatt_configuredserviceprofile">ConfiguredServiceProfile</a>

A ConfiguredServiceProfile object encapsulates a service configuration and can be used to instantiate either Service or MutableService objects. 

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

The CharacteristicProfiles belonging to a ServiceProfile are added using the method,

```swift
public func addCharacteristic(characteristicProfile:CharacteristicProfile)
```
 
## <a name="gatt_characteristicprofile">CharacteristicProfile</a>

CharacteristicProfile is the base class for each of the following profile types and is instantiated as the characteristic profile if a profile is not explicitly defined for a discovered Characteristic. In this case, with no String conversions implemented in a GATT Profile definition, a Characteristic will support String conversions to a from hexadecimal Strings.

When defining a GATT profile it is sometimes convenient to specify that something be done after a Characteristic is discovered by a Central.

```swift
public func afterDiscovered(capacity:Int?) -> FutureStream<Characteristic>
```

## <a name="gatt_rawcharacteristicprofile">RawCharacteristicProfile</a>

A RawCharacteristicProfile object encapsulates configuration and String conversions for a Characteristic implementing [RawDeserializable](#serde_rawdeserializable). It can be used to instantiate both Characteristic and MutableCharacteristic objects.

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

To instantiate a profile in an application,

```swift
let profile = RawCharacteristicProfile<Enabled>()
```

## <a name="gatt_rawarraycharacteristicprofile">RawArrayCharacteristicProfile</a>

A RawArrayCharacteristicProfile object encapsulates configuration and String conversions for a characteristic implementing [RawArrayDeserializable](#serde_rawarraydeserializable). It can be used to instantiate both Characteristic and MutableCharacteristic objects.

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

To instantiate a profile in an application,

```swift
let profile = RawArrayCharacteristicProfile<ArrayData>()
```

## <a name="gatt_rawpaircharacteristicprofile">RawPairCharacteristicProfile</a>

A RawPairCharacteristicProfile object encapsulates configuration and String conversions for a characteristic implementing [RawPairDeserializable](#serde_rawpairdeserializable). It can be used to instantiate both Characteristic and MutableCharacteristic objects.

```swift
struct PairData : RawPairDeserializable, CharacteristicConfigurable, StringDeserializable {    
  // CharacteristicConfigurable
  static let uuid = "F000AA30-0451-4000-B000-000000000000"
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

A RawArrayPairCharacteristicProfile object encapsulates configuration and String conversions for a characteristic implementing [RawArrayPairDeserializable](#serde_rawarraypairdeserializable). It can be used to instantiate both Characteristic and MutableCharacteristic objects.

```swift
struct ArrayPairData : RawArrayPairDeserializable, CharacteristicConfigurable, StringDeserializable {    
  // CharacteristicConfigurable
  static let uuid = "F000AA11-0451-4000-B000-000000000000"
  static let name = "Accelerometer Data"
  static let properties = CBCharacteristicProperties.Read | CBCharacteristicProperties.Notify
  static let permissions = CBAttributePermissions.Readable | CBAttributePermissions.Writeable
static let initialValue : NSData? = Serde.serialize()
            
	// RawArrayPairDeserializable
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

To instantiate a profile in an application,

```swift
let profile = RawArrayPairCharacteristicProfile<ArrayPairData>()
```

## <a name="gatt_stringcharacteristicprofile">StringCharacteristicProfile</a>

A String Profile only requires the implementation of CharacteristicConfigurable

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

To instantiate a profile in an application,

```swift
let profile = StringCharacteristicProfile<SerialNumber>()
```

## <a name="gatt_profilemanager">ProfileManager</a>

ProfileManager is used by the BlueCap app as a repository of GATT profiles to be used to instantiate Services and Characteristics. ProfileManager can be used in an implementation but is not required.

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

## <a name="gatt_add_profile">Add Profile to BlueCap App</a>

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

