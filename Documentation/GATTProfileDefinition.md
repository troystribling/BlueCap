# <a name="gatt">GATT Profile Definition</a>

GATT profile definitions are required to add support for a device to the [BluCap](https://itunes.apple.com/us/app/bluecap/id931219725?mt=8#) app but are not required to build a functional application using the framework. Implementing a GATT profile for a device allows the framework to automatically identify and configure `Services` and `Characteristics` as they are created and provides serialization and deserialization of `Characteristic` values to and from Strings. The examples in this section are also available in a [Playground project](/Playgrounds).

##  Content

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

### <a name="gatt_serviceconfigurable">ServiceConfigurable Protocol</a>

The `ServiceConfigurable` `protocol` is used to specify `Service` configuration and defined by,

```swift
public protocol ServiceConfigurable {
    // Service name.
    static var name: String { get }
    // Service UUID.
    static var uuid: String { get }
    // Used to organize services in the BlueCap app profile browser.
    static var tag: String { get }
}}
```

### <a name="gatt_characteristicconfigurable">CharacteristicConfigurable Protocol</a>

The `CharacteristicConfigurable` `protocol` is used to specify `Characteristic` configuration and defined by,

```swift
public protocol CharacteristicConfigurable {
    // Characteristic name.
    static var name: String { get }
    // Characteristic UUID.
    static var uuid: String { get }
    // Charcteristic permissions
    static var permissions: CBAttributePermissions { get }
    // Charcteristic properties
    static var properties: CBCharacteristicProperties { get }
    // Characteristic initial value.
    static var initialValue: Data? { get }
}
```

### <a name="gatt_stringdeserializable">StringDeserializable Protocol</a>

The `StringDeserializable` `protocol` is used to specify conversion of rawValues to `Strings` and is defined by,

```swift
public protocol StringDeserializable {
    // Used for enums to specify Strings for values but ignored for other types.
    static var stringValues: [String] { get }
    // The String values of the rawType.
    var stringValue: [String : String] { get }
    // Create object from stringValue.
    init?(stringValue:[String : String])
}
```

`String` values of `Characteristics` are assumed to be `Dictionaries` containing the name-value pairs.

### <a name="gatt_serviceprofile">ServiceProfile</a>

A `ServiceProfile` is used to define `Service` configuration. It can be used to instantiate either `Service` or `MutableService` objects. 

```swift
let serviceProfile = ServiceProfile(uuid: "F000AA10-0451-4000-B000-000000000000", name: "Cool Service") 
```

The `CharacteristicProfiles` belonging to a `ServiceProfile` are added using a method defined on `ServiceProfile`,

```swift
public func addCharacteristic(characteristicProfile: CharacteristicProfile)
```

### <a name="gatt_configuredserviceprofile">ConfiguredServiceProfile</a>

A `ConfiguredServiceProfile` object encapsulates a `Service` configuration and is a subclass of `ServiceProfile`. It can be used to instantiate either `Service` or `MutableService` objects. 

```swift
struct AccelerometerService : ServiceConfigurable  {
  static let uuid = "F000AA10-0451-4000-B000-000000000000"
  static let name = "TI Accelerometer"
  static let tag = "TI Sensor Tag"
}
```

```swift
let serviceProfile = ConfiguredServiceProfile<AccelerometerService>() 
```
 
### <a name="gatt_characteristicprofile">CharacteristicProfile</a>

`CharacteristicProfile` is the base class for `CharacteristicProfile` types and is instantiated as the default Characteristic profile if one was not explicitly defined for a discovered `Characteristic`. In this case, with no `String` conversions implemented in a GATT Profile definition, a `Characteristic` will support the default `String` conversions to and from `Data` using hexadecimal Strings. It can be used to instantiate either `Characteristic` or `MutableCharacteristic` objects. `CharacteristicProfile` have the following initializer,

```swift
public init(uuid: String, name: String, permissions: CBAttributePermissions = [.readable, .writeable], properties: CBCharacteristicProperties = [.read, .write, .notify], initialValue: Data? = nil)

public convenience init(uuid: String)
```
   
Default implementations are provided forth following methods,

```swift
public func propertyEnabled(_ property: CBCharacteristicProperties) -> Bool
    
public func permissionEnabled(_ permission: CBAttributePermissions) -> Bool
        
public func stringValue(_ data: Data) -> [String : String]?
    
public func data(fromString data: [String : String]) -> Data? 
```             


### <a name="gatt_rawcharacteristicprofile">RawCharacteristicProfile</a>

A `RawCharacteristicProfile` object encapsulates configuration and serialization/desserialization for a `Characteristic` implementing [RawDeserializable](/Documentation/SerializationDeserialization.md/#serde_rawdeserializable). It can be used to instantiate both `Characteristic` and `MutableCharacteristic` objects and is a subclass of `CharacteristicProfile`.

The `CharacteristicProfile` type for the [TiSensorTag Accelerometer Service](BlueCapKit/Service%20Profile%20Definitions/TISensorTagServiceProfiles.swift) Enabled `Characteristic` implementing `RawDeserializable`, `StringDeserializable`, `CharacteristicConfigurable` is given by,

```swift
public enum Enabled: UInt8, RawDeserializable, StringDeserializable, CharacteristicConfigurable {
    public typealias RawType = UInt8

    case no = 0
    case yes = 1
    
    // CharacteristicConfigurable
    public static let uuid = "F000AA12-0451-4000-B000-000000000000"
    public static let name = "Accelerometer Enabled"
    public static let properties: CBCharacteristicProperties = [.read, .write]
    public static let permissions: CBAttributePermissions = [.readable, .writeable]
    public static let initialValue: Foundation.Data? = SerDe.serialize(Enabled.no.rawValue)

    // StringDeserializable
    public static let stringValues = ["no", "yes"]
    
    public init(boolValue: Bool) {
        if boolValue {
            self = Enabled.yes
        } else {
            self = Enabled.no
        }
    }
    
    public init?(stringValue: [String: String]) {
        if let value = stringValue[Enabled.name] {
            switch value {
            case "yes":
                self = Enabled.yes
            case "no":
                self = Enabled.no
            default:
                return nil
            }
        } else {
            return nil
        }
    }
    
    public var stringValue: [String: String] {
        switch self {
        case .no:
            return [Enabled.name : "no"]
        case .yes:
            return [Enabled.name : "yes"]
        }
    }
    
    public var boolValue: Bool {
        switch self {
        case .no:
            return false
        case .yes:
            return true
        }
    }
}
```

```swift
if let value = Enabled(stringValue:[Enabled.name : "Yes"]) {
    print(value.stringValue)
}
```

### <a name="gatt_rawarraycharacteristicprofile">RawArrayCharacteristicProfile</a>

A `RawArrayCharacteristicProfile` object encapsulates configuration and serialization/deserialization for a characteristic implementing [RawArrayDeserializable](/Documentation/SerializationDeserialization.md/#serde_rawarraydeserializable). It can be used to instantiate both Characteristic and MutableCharacteristic objects. An example profile for an `[Int8]` raw value implementing `RawArrayDeserializable`, `CharacteristicConfigurable` and `StringDeserializable` is given by,

```swift
struct ArrayData : RawArrayDeserializable, CharacteristicConfigurable, StringDeserializable {
    
    // CharacteristicConfigurable
    static let uuid = "F000AA11-0451-4000-B000-000000000000"
    static let name = "Accelerometer Data"
    static let properties: CBCharacteristicProperties = [.read, .write]
    static let permissions: CBAttributePermissions = [.readable, .writeable]
    static let initialValue: NSData? = SerDe.serialize(ArrayData(rawValue:[1, 2])!)
    
    // RawArrayDeserializable
    let rawValue : [Int8]
    static let size = 2
    
    init?(rawValue: [Int8]) {
        if rawValue.count == 2 {
            self.rawValue = rawValue
        } else {
            return nil
        }
    }
    
    // StringDeserializable
    static let stringValues = [String]()
    
    var stringValue : [String : String] {
        return ["value1" : "\(self.rawValue[0])",
            "value2" : "\(self.rawValue[1])"]
    }
    
    init?(stringValue:[String:String]) {
        if  let stringValue1 = stringValue["value1"],
            let stringValue2 = stringValue["value2"],
            let value1 = Int8(stringValue1),
            let value2 = Int8(stringValue2) {
                self.rawValue = [value1, value2]
        } else {
            return nil
        }
    }
}

if let value = ArrayData(rawValue: [1, 100]) {
    print(value.rawValue)
}

if let value = ArrayData(stringValue:["value1" : "1", "value2" : "100"]) {
    print(value.stringValue)
}
```

To instantiate a profile in an application,

```swift
let profile = RawArrayPairCharacteristicProfile<PairData>()
```

### <a name="gatt_rawpaircharacteristicprofile">RawPairCharacteristicProfile</a>

A RawPairCharacteristicProfile object encapsulates configuration and serialization/deserialization for a characteristic implementing [RawPairDeserializable](/Documentation/SerializationDeserialization.md/#serde_rawpairdeserializable). It can be used to instantiate both `Characteristic` and `MutableCharacteristic` objects. An example profile for `UInt8` and `Int8` raw values implementing `RawPairDeserializable`, `CharacteristicConfigurable` and `StringDeserializable` is given by,

```swift
struct PairData : RawPairDeserializable, CharacteristicConfigurable, StringDeserializable {
    
    // CharacteristicConfigurable
    static let uuid = "F000AA30-0451-4000-B000-000000000000"
    static let name = "Magnetometer Data"
    static let properties: CBCharacteristicProperties = [.read, .notify]
    static let permissions: CBAttributePermissions = [.readable, .writeable]
    static let initialValue: Data? = SerDe.serialize(PairData(rawValue1: 10, rawValue2: -10)!)
    
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
        if let stringValue1 = stringValue["value1"],
           let stringValue2 = stringValue["value2"],
           let value1 = UInt8(stringValue1),
           let value2 = Int8(stringValue2) {
                self.rawValue1 = value1
                self.rawValue2 = value2
        } else {
            return nil
        }
    }
}

if let value = PairData(stringValue: ["value1" : "1", "value2" : "-2"]) {
    print(value.stringValue)
}
```

To instantiate a profile in an application,

```swift
let profile = RawArrayPairCharacteristicProfile<PairData>()
```

### <a name="gatt_rawarraypaircharacteristicprofile">RawArrayPairCharacteristicProfile</a>

A `RawArrayPairCharacteristicProfile` object encapsulates configuration and serialization/deserialization for a characteristic implementing [RawArrayPairDeserializable](/Documentation/SerializationDeserialization.md/#serde_rawarraypairdeserializable). It can be used to instantiate both `Characteristic` and `MutableCharacteristic` objects. An example profile for `[UInt8]` and `[Int8]` raw values implementing `RawArrayPairDeserializable`, `CharacteristicConfigurable` and `StringDeserializable` is given by,

```swift
struct ArrayPairData : RawArrayPairDeserializable, CharacteristicConfigurable, StringDeserializable {
    
    // CharacteristicConfigurable
    static let uuid = "F000AA11-0451-4000-B000-000000000000"
    static let name = "Accelerometer Data"
    static let properties: CBCharacteristicProperties = [.read, .notify]
    static let permissions: CBAttributePermissions = [.readable, .writeable]
    static let initialValue: Data? = SerDe.serialize(ArrayPairData(rawValue1: [1,2], rawValue2: [-1, -2])!)
    
    // RawArrayDeserializable
    let rawValue1 : [UInt8]
    let rawValue2 : [Int8]
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
            "value12":"\(self.rawValue1[1])",
            "value21":"\(self.rawValue2[0])",
            "value22":"\(self.rawValue2[1])"]}
    
    init?(stringValue:[String:String]) {
        if  let stringValue11 = stringValue["value11"],
            let stringValue12 = stringValue["value12"],
            let value11 = UInt8(stringValue11),
            let value12 = UInt8(stringValue12),
            let stringValue21 = stringValue["value21"],
            let stringValue22 = stringValue["value22"],
            let value21 = Int8(stringValue21),
            let value22 = Int8(stringValue22) {
                self.rawValue1 = [value11, value12]
                self.rawValue2 = [value21, value22]
        } else {
            return nil
        }
    }
}

if let value = ArrayPairData(stringValue:["value11" : "1", "value12" : "2", "value21" : "-1", "value22" : "-2"]) {
    print(value.stringValue)
}
```

To instantiate a profile in an application,

```swift
let profile = RawArrayPairCharacteristicProfile<ArrayPairData>()
```

### <a name="gatt_stringcharacteristicprofile">StringCharacteristicProfile</a>

A `StringCharacteristicProfile` only requires the implementation of CharacteristicConfigurable

```swift
struct SerialNumber : CharacteristicConfigurable {
    // CharacteristicConfigurable
    static let uuid = "2a25"
    static let name = "Device Serial Number"
    static let permissions: CBAttributePermissions = [.readable, .writeable]
    static let properties: CBCharacteristicProperties = [.read]
    static let initialValue = SerDe.serialize("AAA11")
}
```

To instantiate a profile in an application,

```swift
let profile = StringCharacteristicProfile<SerialNumber>()
```

### <a name="gatt_profilemanager">ProfileManager</a>

`ProfileManager` is used by the `BlueCap` app as a repository of GATT profiles to be used to instantiate `Services` and `Characteristics`. `ProfileManager` can be used in any application but is not required.

A `ServiceProfile` is added to `ProfileManager` using a method defined on `ProfileManager`,

```swift
public func addService(serviceProfile: ServiceProfile) -> ServiceProfile 
```

To add `ServiceProfiles` and `CharacteristicProfiles` to `ProfileManager`,

```swift
let profileManager = ProfileManager()

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

### <a name="gatt_add_profile">Add Profile to BlueCap App</a>

To add a GATT Profile to the [BluCap](https://itunes.apple.com/us/app/bluecap/id931219725?mt=8#) app you need to add a file to the project containing all `ServiceProfiles` and `CharacteristicProfiles` with public access level. See [GnosusProfiles](/BlueCapKit/Service%20Profile%20Definitions/GnosusProfiles.swift) in the BlueCap Project for an example. 
Add the profile to BlueCap in [AppDelegate.swift](/Examples/BlueCap/BlueCap/AppDelegate.swift#L61-64).
