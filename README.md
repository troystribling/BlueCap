[![Build Status](https://travis-ci.org/troystribling/BlueCap.svg?branch=remove_prefix)](https://travis-ci.org/troystribling/BlueCap)
[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/BlueCapKit.svg)](https://img.shields.io/cocoapods/v/BlueCapKit.svg)
[![Platform](https://img.shields.io/cocoapods/p/BlueCapKit.svg?style=flat)](http://cocoadocs.org/docsets/BlueCapKit)
[![License](https://img.shields.io/cocoapods/l/BlueCapKit.svg?style=flat)](http://cocoadocs.org/docsets/BlueCapKit)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

[![BlueCap: Swifter CoreBluetooth](https://rawgit.com/troystribling/BlueCap/6de55eaf194f101d690ba7c2d0e8b20051fd8299/Assets/banner.png)](https://itunes.apple.com/us/app/bluecap/id931219725?mt=8#)

BlueCap provides a swift wrapper around CoreBluetooth and much more.

# Features

- A [futures](https://github.com/troystribling/SimpleFutures) interface replacing protocol implementations.
- Connection events for connect, disconnect and timeout.
- Service scan timeout.
- Characteristic read/write timeout.
- A DSL for specification of GATT profiles.
- Characteristic profile types encapsulating serialization and deserialization.
- [Example](https://github.com/troystribling/BlueCap/tree/master/Examples) applications implementing Central and Peripheral.
- A full featured extendable Central scanner and Peripheral emulator available in the [App Store](https://itunes.apple.com/us/app/bluecap/id931219725?mt=8#).
- Thread safe.
- Comprehensive test coverage.

# Requirements

- iOS 8.0+
- Xcode 7.3+

# Installation

## CocoaPods

[CocoaPods](https://cocoapods.org) is an Xcode dependency manager. It is installed with the following command,

```bash
$ gem install cocoapods
```

> Requires CocoaPods 1.0+

Add `BluCapKit` to your to your projects `Podfile`,

```ruby
platform :ios, '8.0'
use_frameworks!

target 'Your Target Name' do
  pod 'BlueCapKit', '~> 0.2'
end
```

To enable `DBUG` output add the `post_install` hook,

```ruby
post_install do |installer|
    installer.pods_project.targets.each do |target|
        if target.name == 'BlueCapKit'
            target.build_configurations.each do |config|
                if config.name == 'Debug'
                    config.build_settings['OTHER_SWIFT_FLAGS'] = '-DDEBUG'
                    else
                    config.build_settings['OTHER_SWIFT_FLAGS'] = ''
                end
            end
        end
    end
end
```

To install run the command,

```bash
$ pod install
```

## Carthage

[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager for Xcode projects.
It can be installed using [Homebrew](http://brew.sh/),

```bash
$ brew update
$ brew install carthage
```

To add `BlueCapKit` to your `Cartfile`

```ogdl
github "troystribling/BlueCap" ~> 0.2
```

To download and build `BlueCapKit.framework` run the command,

```bash
carthage update
```

then add `BlueCapKit.framework` to your project.

If desired use the `--no-build` option,

```bash
carthage update --no-build
```

This will only download the `BlueCapKit` project. Then follow the steps in [Manual](#manual) to add it to a project.

## <a name="manual">Manual</a>

1. Place the BlueCap somewhere in your project directory. You can either copy it or add it as a git submodule.
2. Open the BlueCap project folder and drag BlueCapKit.xcodeproj into the project navigator of your applications Xcode project.
3. Under your Projects *Info* tab set the *iOS Deployment Target* to 8.0 and verify that the BlueCapKit.xcodeproj *iOS Deployment Target* is also 8.0.
4. Under the *General* tab for your project target add the top BlueCapKit.framework as an *Embedded Binary*.
5. Under the *Build Phases* tab add BlueCapKit.framework as a *Target Dependency* and under *Link Binary With Libraries* add CoreLocation.framework and CoreBluetooth.framework.

# Getting Started

With BlueCap it is possible to easily implement Central and Peripheral applications, serialize and deserialize messages exchanged with bluetooth devices and define reusable GATT profile definitions. The BlueCap asynchronous interface uses [futures](https://github.com/troystribling/SimpleFutures) instead of the usual block interface or the protocol-delegate pattern. Futures can be chained with the result of the previous passed as input to the next. This simplifies application implementation because the persistence of state between asynchronous calls is eliminated and code will not be distributed over multiple files, which is the case for protocol-delegate, or be deeply nested, which is the case for block interfaces. In this section a brief overview of how an application is constructed will be given.  [Following sections](#usage) will describe all use cases supported in some detail. [Example applications](https://github.com/troystribling/BlueCap/tree/master/Examples) are also available.
 
## Central Implementation

A simple Central implementation that scans for Peripherals advertising a [TI SensorTag Accelerometer Service](https://github.com/troystribling/BlueCap/blob/master/BlueCapKit/Service%20Profile%20Definitions/TISensorTagServiceProfiles.swift#L17-217) and connects on peripheral discovery will be described. 

All applications begin by calling `CentralManager#whenPowerOn` which returns a `Future<Void>` completed when the `CBCentralManager` state is set to `CBCentralManagerState.PoweredOn`.

```swift
let manager = CentralManager()
let powerOnFuture = manager.whenPowerOn()
```

To start scanning for peripherals advertising the [TI SensorTag Accelerometer Service](https://github.com/troystribling/BlueCap/blob/master/BlueCapKit/Service%20Profile%20Definitions/TISensorTagServiceProfiles.swift#L17-217) `powerOnFuture` will chained to `CentralManager#startScanningForServiceUUIDs` using the `Future#flatmap` combinator.

```swift
let manager = CentralManager()
let serviceUUID = CBUUID(string:TISensorTag.AccelerometerService.uuid)!

let scanningFuture = manager.whenPowerOn().flatmap {
	manager.startScanningForServiceUUIDs([serviceUUID])
}
```

`CentralManager#startScanningForServiceUUIDs` returns `FutureStream<Peripheral>`. `scanningFuture` will be completed once for each peripheral discovered.

To connect a discovered peripheral use `FutureStream#flatmap` to call `Peripheral#connect()` which returns  `FutureStream<(peripheral: Peripheral, connectionEvent: ConnectionEvent)>`.

```swift
let manager = CentralManager()
let serviceUUID = CBUUID(string:TISensorTag.AccelerometerService.uuid)!

let connectionFuture = manager.whenPowerOn().flatmap {
	manager.startScanningForServiceUUIDs([serviceUUID])
}.flatmap {peripheral -> FutureStream<(Peripheral, ConnectionEvent)> in
	peripheral.connect()
}

connectionFuture.onSuccess{ (peripheral, connectionEvent) in
    switch connectionEvent {
    case .Connect:
	    break
    case .Timeout:
	    peripheral.reconnect()
    case .Disconnect:
	    peripheral.reconnect()
    case .ForceDisconnect:
	    break
    case .GiveUp:
	    peripheral.terminate()
	 }
}
```

Here on `.Timeout` and `.Disconnect` try to reconnect and on `.Giveup` terminate connection

See the [Central Example](https://github.com/troystribling/BlueCap/tree/remove_prefix/Examples/Central) application for a more detailed implementation that additionally discovers the peripheral and subscribed to accelerometer update notifications.

## Peripheral Implementation

A simple Peripheral application that emulates a [TI SensorTag Accelerometer Service](https://github.com/troystribling/BlueCap/blob/master/BlueCapKit/Service%20Profile%20Definitions/TISensorTagServiceProfiles.swift#L17-217) with all characteristics and services will be described. It will advertise the service and respond to characteristic write request.

First the Characteristics and Service are created,

```swift
// create service and characteristics using profile definitions
let accelerometerService = MutableService(profile:ConfiguredServiceProfile<TISensorTag.AccelerometerService>())
let accelerometerDataCharacteristic = MutableCharacteristic(profile:RawArrayCharacteristicProfile<TISensorTag.AccelerometerService.Data>())
let accelerometerEnabledCharacteristic = MutableCharacteristic(profile:RawCharacteristicProfile<TISensorTag.AccelerometerService.Enabled>())
let accelerometerUpdatePeriodCharacteristic = MutableCharacteristic(profile:RawCharacteristicProfile<TISensorTag.AccelerometerService.UpdatePeriod>())

// add characteristics to service
accelerometerService.characteristics = [accelerometerDataCharacteristic, accelerometerEnabledCharacteristic, accelerometerUpdatePeriodCharacteristic]
```


Next respond to write events on the Enabled characteristic,

```swift
let accelerometerEnabledFuture = self.accelerometerEnabledCharacteristic.startRespondingToWriteRequests(capacity:2)
accelerometerEnabledFuture.onSuccess {request in  
	if request.value.length == 1 {
		accelerometerEnabledCharacteristic.value = request.value
		accelerometerEnabledCharacteristic.respondToRequest(request, withResult:CBATTError.Success)
	} else {
		accelerometerEnabledCharacteristic.respondToRequest(request, withResult:CBATTError.InvalidAttributeValueLength)
	}
}
```

and respond to write events on the Update Period characteristic,

```swift
let accelerometerUpdatePeriodFuture = accelerometerUpdatePeriodCharacteristic.startRespondingToWriteRequests()
accelerometerUpdatePeriodFuture.onSuccess {request in
	if request.value.length > 0 &&  request.value.length <= 8 {
		accelerometerUpdatePeriodCharacteristic.value = request.value
		accelerometerUpdatePeriodCharacteristic.respondToRequest(request, withResult:CBATTError.Success)
	} else {
		accelerometerUpdatePeriodCharacteristic.respondToRequest(request, withResult:CBATTError.InvalidAttributeValueLength)
	}
}
```

Next power on the Peripheral Manager, add services and start advertising.

```swift
let manager = PeripheralManager()

let startAdvertiseFuture = manager.powerOn().flatmap {_ -> Future<Void> in
	manager.removeAllServices()
}.flatmap {_ in
	manager.addService(accelerometerService)
}.flatmap {_ in
  manager.startAdvertising(TISensorTag.AccelerometerService.name, uuids:[uuid])
}
```

## Examples

# <a name="usage">Usage</a>

BlueCap supports many features that simplify writing Bluetooth LE applications. This section will describe all features in detail and provide code examples.

1. [CentralManager](#central): The BlueCap CentralManager implementation replaces [CBCentralManagerDelegate](https://developer.apple.com/library/prerelease/ios/documentation/CoreBluetooth/Reference/CBCentralManagerDelegate_Protocol/index.html#//apple_ref/occ/intf/CBCentralManagerDelegate) and [CBPeripheralDelegate](https://developer.apple.com/library/prerelease/ios/documentation/CoreBluetooth/Reference/CBPeripheralDelegate_Protocol/index.html#//apple_ref/occ/intf/CBPeripheralDelegate) protocol implementations with a Scala Futures interface using [SimpleFutures](https://github.com/troystribling/SimpleFutures). 
  * [PowerOn/PowerOff](#central_poweron_poweroff): Detect when the bluetooth transceiver is powered on and off.
  * [Service Scanning](#central_service_scanning): Scan for services.
  * [Service Scanning with Timeout](#central_service_scan_timeout): Scan for services with timeout.
  * [Peripheral Advertisements](#central_peripheral_advertisements): Access Advertisements of discovered Peripherals.
  * [Peripheral Connection](#central_peripheral_connection): Connect to discovered Peripherals.
  * [Service and Characteristic Discovery](#central_characteristic_discovery): Discover Services and Characteristics of connected Peripherals.
  * [Characteristic Write](#central_characteristic_write): Write a characteristic value to a connected Peripheral.
  * [Characteristic Read](#central_characteristic_read): Read a characteristic value from a connected Peripheral.
  * [Characteristic Update Notifications](#central_characteristic_update): Subscribe to characteristic value updates on a connected Peripheral.

2. [PeripheralManager](#peripheral): The BlueCap PeripheralManager implementation replaces [CBPeripheralManagerDelegate](https://developer.apple.com/library/prerelease/ios/documentation/CoreBluetooth/Reference/CBPeripheralManagerDelegate_Protocol/index.html#//apple_ref/occ/intf/CBPeripheralManagerDelegate) protocol implementations with a Scala Futures interface using [SimpleFutures](https://github.com/troystribling/SimpleFutures).
  * [PowerOn/PowerOff](#peripheral_poweron_poweroff): Detect when the bluetooth transceiver is powered on and off.
  * [Add Services and Characteristics](#peripheral_add_characteristics): Add services and characteristics to a Peripheral application.
  * [Advertising](#peripheral_advertising): Advertise a Peripheral application.
  * [Set Characteristic Value](#peripheral_set_characteristic_value): Set a characteristic value for a Peripheral application.
  * [Update Characteristic Value](#peripheral_update_characteristic_value): Send characteristic value update notifications to Centrals.
  * [Respond to Characteristic Write](#peripheral_respond_characteristic_write): Respond to characterize value writes from a Central.
  * [iBeacon Emulation](#peripheral_ibeacon_emulation): Emulate an iBeacon with a Peripheral application.

3. [Serialization/Deserialization](#serde): Serialization and deserialization of device messages.
 * [String](#serde_strings): String serialization and deserialization.
 * [Deserializable Protocol](#serde_deserializable): Deserialize numeric types.
 * [RawDeserializable Protocol](#serde_rawdeserializable): Deserialize messages with a single value of a single Deserializable type.
 * [RawArrayDeserializable Protocol](#serde_rawarraydeserializable): Deserialize messages with multiple values of single Deserializable type.
 * [RawPairDeserializable Protocol](#serde_rawpairdeserializable): Deserialize messages with two values of two different Deserializable types.
 * [RawArrayPairDeserializable Protocol](#serde_rawarraypairdeserializable): Deserialize messages with multiple values of two different Deserializable types.

4. [GATT Profile Definition](#gatt): Define reusable GATT profiles and add profiles to the BlueCap app.
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

## <a name="peripheral">PeripheralManager</a>

The BlueCap PeripheralManager implementation replaces [CBPeripheralManagerDelegate](https://developer.apple.com/library/prerelease/ios/documentation/CoreBluetooth/Reference/CBPeripheralManagerDelegate_Protocol/index.html#//apple_ref/occ/intf/CBPeripheralManagerDelegate) protocol implementations with with a Scala Futures interface using [SimpleFutures](https://github.com/troystribling/SimpleFutures). Futures provide inline implementation of asynchronous callbacks and allows chaining asynchronous calls as well as error handling and recovery. This section will describe interfaces and give example implementations for all supported use cases. [Simple example applications](https://github.com/troystribling/BlueCap/tree/master/Examples) can be found in the BlueCap github repository.

### <a name="peripheral_poweron_poweroff">PowerOn/PowerOff</a>

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

When PeripheralManager is instantiated a message giving the current bluetooth transceiver state is received and while the PeripheralManager is instantiated messages are received if the transceiver is powered or powered off.

### <a name="peripheral_add_characteristics">Add Services and Characteristics</a>

Services and characteristics are added to a peripheral application before advertising. The BlueCap PeripheralManager methods used for managing services are,

```swift
// add a single service
public func addService(service:MutableService) -> Future<Void>

// add multiple services
public func addServices(services:[MutableService]) -> Future<Void>

// remove a service
public func removeService(service:MutableService) -> Future<Void>

// remove all services
public func removeAllServices() -> Future<Void>
``` 

All methods return a [SimpleFutures](https://github.com/troystribling/SimpleFutures) *Future&lt;Void&gt;*. The methods can only be used before PeripheralManager begins advertising.

The BlueCap MutableService methods are,

```swift
// add characteristics
public var characteristics : [MutableCharacteristic] {get set}

// create characteristics from profiles
public func characteristicsFromProfiles(profiles:[CharacteristicProfile])
```

A Peripheral application will add Services and Characteristics using,

```swift
// service UUId and characteristic value definition
let serviceUUID = CBUUID(string:"F000AA10-0451-4000-B000-000000000000")
enum Enabled : UInt8, RawDeserializable {
    case No  = 0
    case Yes = 1
    public static let uuid = "F000AA12-0451-4000-B000-000000000000"
}

// create service and characteristic
let service = MutableService(uuid:serviceUUID)
let characteristic = MutableCharacteristic(uuid:Enabled.uuid,                                            properties:CBCharacteristicProperties.Read|CBCharacteristicProperties.Write,                                                 permissions:CBAttributePermissions.Readable|CBAttributePermissions.Writeable,                                                value:Serde.serialize(Enabled.No)))

// add characteristics to service 
service.characteristics = [characteristic]

// add service to peripheral
let manager = PeripheralManager.sharedInstance
let addServiceFuture = manager.powerOn().flatmap {_ -> Future<Void> in
	manager.removeAllServices()
}.flatmap {_ -> Future<Void> in
	manager.addService(service)
}

addServiceFuture.onSuccess {
	…
}
addServiceFuture.onFailure {error in
	…
}
```

First BlueCap MutableServices and MutableCharacteristics are created and [CBCharacteristicProperties](https://developer.apple.com/library/prerelease/ios/documentation/CoreBluetooth/Reference/CBCharacteristic_Class/index.html#//apple_ref/c/tdef/CBCharacteristicProperties) and [CBAttributePermissions](https://developer.apple.com/library/prerelease/ios/documentation/CoreBluetooth/Reference/CBMutableCharacteristic_Class/index.html#//apple_ref/c/tdef/CBAttributePermissions) are specified. The Characteristic is then added to the Service. Then the PeripheralManager *powerOn() -> Future&lt;Void&gt;* is flatmapped to *removeAllServices() -> Future&lt;Void&gt;* which is then flatmapped to *addServices(services:[MutableService]) -> Future&lt;Void&gt;*. This sequence ensures that the Peripheral is powered and with no services before the new services are added.

If Service and Characteristic GATT profile definitions are available creating Services and Characteristics is a little simpler,

```swift
let  service = MutableService(profile:ConfiguredServiceProfile<TISensorTag.AccelerometerService>())
let characteristic = MutableCharacteristic(profile:RawCharacteristicProfile<TISensorTag.AccelerometerService.Enabled>())
```

Here the BlueCap the [TiSensorTag GATT profile](https://github.com/troystribling/BlueCap/blob/master/BlueCapKit/Service%20Profile%20Definitions/TISensorTagServiceProfiles.swift) was used.

### <a name="peripheral_advertising">Advertising</a>

After services and characteristics have been added the peripheral is ready to begin advertising using the methods,

```swift
// start advertising with name and services
public func startAdvertising(name:String, uuids:[CBUUID]?) -> Future<Void>

// start advertising with name and no services
public func startAdvertising(name:String) -> Future<Void> 

// stop advertising
public func stopAdvertising() -> Future<Void>
```

All methods return a [SimpleFutures](https://github.com/troystribling/SimpleFutures) *Future&lt;Void&gt;*. For a Peripheral application to advertise,

```swift
// use service and characteristic defined in previous section
let manager = PeripheralManager.sharedInstance
let startAdvertiseFuture = manager.powerOn().flatmap {_ -> Future<Void> in
	manager.removeAllServices()
}.flatmap {_ -> Future<Void> in
	manager.addService(service)
}.flatmap {_ -> Future<Void> in
	manager.startAdvertising("My Service", uuids:[serviceUUID])
}
            
startAdvertiseFuture.onSuccess {
	…
}
startAdvertiseFuture.onFailure {error in
	…
}
```

Here the addServiceFuture of the previous section is flatmapped to *startAdvertising(name:String, uuids:[CBUUID]?) -> Future&lt;Void&gt;* ensuring that services and characteristics are available before advertising begins.

### <a name="peripheral_set_characteristic_value">Set Characteristic Value</a>

A BlueCap Characteristic value can be set any time after creation of the Characteristic. The BlueCap MutableCharacteristic methods used are,

```swift
var value : NSData? {get set}
```

It is not necessary for the PeripheralManager to be powered on or advertising to set a characteristic value. 

A peripheral application can set a characteristic value using,

```swift
// Enabled and characteristic defined above
characteristic.value = Serde.serialize(Enabled.Yes)
```

### <a name="peripheral_update_characteristic_value">Updating Characteristic Value</a>

If a Characteristic value supports the property CBCharacteristicProperties.Notify a Central can subscribe to value updates. In addition to setting the new value an update notification must be sent. The BlueCap MutableCharacteristic methods used are,

```swift
// update with NSData
func updateValueWithData(value:NSData) -> Bool

// update with String Dictionary
public func updateValueWithString(value:Dictionary<String, String>) -> Bool

// update with object supporting Deserializable
public func updateValue<T:Deserializable>(value:T) -> Bool

// update with object supporting RawDeserializable
public func updateValue<T:RawDeserializable>(value:T) -> Bool

// update with object supporting RawArrayDeserializable
public func updateValue<T:RawArrayDeserializable>(value:T) -> Bool

// update with object supporting RawPairDeserializable
public func updateValue<T:RawPairDeserializable>(value:T) -> Bool

// update with object supporting RawArrayPairDeserializable
public func updateValue<T:RawArrayPairDeserializable>(value:T) -> Bool
```

All methods return a Bool which is true if the update succeeds and false if either there are no subscribers, CBCharacteristicProperties.Notify is not supported or the length of the update queue is exceeded. In addition to sending an update notification to a subscribing Central the Characteristic value is set. A BlueCap Characteristic value can be updated any time after creation of the characteristic. It is not necessary for the PeripheralManager to be powered on or advertising. Though in this case the update will fail and return false.

Peripheral applications would send notification updates using,

```swift
// Enabled and characteristic defined above
characteristic.updateValue(Enabled.No)
```

### <a name="peripheral_respond_characteristic_write">Respond to Characteristic Write</a>

If a Characteristic value supports the property CBCharacteristicProperties.Write a Central can change the Characteristic value. The BlueCap MutableCharacteristic methods used are,

```swift
// start processing write requests with stream capacity
public func startRespondingToWriteRequests(capacity:Int? = nil) -> FutureStream<CBATTRequest>

// respond to received write request
func respondToRequest(request:CBATTRequest, withResult result:CBATTError)

// stop processing write requests
public func stopProcessingWriteRequests()
```

[CBATTRequest](https://developer.apple.com/library/prerelease/ios/documentation/CoreBluetooth/Reference/CBATTRequest_class/index.html) encapsulates Central write requests, [CBATTError](https://developer.apple.com/library/prerelease/ios/documentation/CoreBluetooth/Reference/CoreBluetooth_Constants/index.html#//apple_ref/c/tdef/CBATTError) encapsulates response the code and a [SimpleFutures](https://github.com/troystribling/SimpleFutures) FutureStream&lt;CBATTRequest&gt; is used to respond to write requests.

Peripheral applications would start responding to Central writes using,

```swift
let writeFuture = characteristic.startRespondingToWriteRequests(capacity:10)
writeFuture.onSuccess {request in
	if request.value.length == 1 {
		characteristic.value = request.value
		characteristic.respondToRequest(request, withResult:CBATTError.Success)
	} else {  
		characteristic.respondToRequest(request, withResult:CBATTError.InvalidAttributeValueLength)
	}
}
```

Peripheral applications would stop responding to write requests using,

```swift
characteristic.stopProcessingWriteRequests()
```

### <a name="peripheral_ibeacon_emulation">iBeacon Emulation</a>

iBeacon emulation does not require Services and Characteristics. Only advertising is required. The BlueCap PeripheralManager methods used are, 

```swift
// start advertising beceacon region
public func startAdvertising(region:BeaconRegion) -> Future<Void>

// stop advertising
public func stopAdvertising() -> Future<Void>
```

All methods return a [SimpleFutures](https://github.com/troystribling/SimpleFutures) Future&lt;Void&gt;. Creation of a [FutureLocation](https://github.com/troystribling/FutureLocation) BeaconRegion is also required,

```swift
public convenience init(proximityUUID:NSUUID, identifier:String, major:UInt16, minor:UInt16)
```

<table>
	<tr>
		<td>proximityUUID</td>
		<td>The proximity ID of the beacon targeted</td>
	</tr>
	<tr>
		<td>identifier</td>
		<td>A unique identifier for region used by application</td>
	</tr>
	<tr>
		<td>major</td>
		<td>The major value used to identify one or more beacons</td>
	</tr>
	<tr>
		<td>minor</td>
		<td>The minor value used to identify a specific beacon</td>
	</tr>
</table>

For an iBeacon application to advertise,

```swift
// use service and characteristic defined in previous section
let regionUUID = CBUUID(string:"DE6E8DAD-8D99-4E20-8C4B-D9CC2F9A7E83")!
let startAdvertiseFuture = manager.powerOn().flatmap {_ -> Future<Void> in
	let beaconRegion = BeaconRegion(proximityUUID:regionUUID, identifier:"My iBeacon", major:100, minor:1, capacity:10)
	manager.startAdvertising(beaconRegion)
}
            
startAdvertiseFuture.onSuccess {
	…
}
startAdvertiseFuture.onFailure {error in
	…
}
```

Here the powerOn() -> Future&lt;Void&gt; flatmapped to startAdvertising(region:BeaconRegion) -> Future&lt;Void&gt; ensuring that the bluetooth transceiver is powered on before advertising begins.

## <a name="serde">Serialization/Deserialization</a>

Serialization and deserialization of device messages requires protocol implementations. Then application objects can be converted to and from NSData objects using methods on Serde. Example implantations of each protocol can be found in the [TiSensorTag GATT profile](https://github.com/troystribling/BlueCap/blob/master/BlueCapKit/Service%20Profile%20Definitions/TISensorTagServiceProfiles.swift) available in BlueCapKit and the following examples are implemented in a BlueCap [Playground](https://github.com/troystribling/BlueCap/tree/master/BlueCap/SerDe.playground). 

### <a name="serde_strings">Strings</a>

For Strings Serde serialize and deserialize are defined by,

```swift
// Deserialize Strings
public static func deserialize(data:NSData, encoding:NSStringEncoding = NSUTF8StringEncoding) -> String?

// Serialize Strings
public static func serialize(value:String, encoding:NSStringEncoding = NSUTF8StringEncoding) -> NSData?
```

[NSStringEncoding](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSString_Class/#//apple_ref/doc/constant_group/String_Encodings) supports many encodings. 

to use in an application,
```swift
if let data = Serde.serialize("Test") {
    if let value = Serde.deserialize(data) {
        println(value)
    }
}
```

### <a name="serde_deserializable">Deserializable Protocol</a>

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
// Deserialize objects supporting Deserializable
public static func deserialize<T:Deserializable>(data:NSData) -> T?

// Serialize objects supporting Deserializable
public static func serialize<T:Deserializable>(value:T) -> NSData
```

For UInt8 data,

```swift
let data = Serde.serialize(UInt8(31))
if let value : UInt8 = Serde.deserialize(data) {
    println("\(value)")
}
```

### <a name="serde_rawdeserializable">RawDeserializable Protocol</a>

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
// Deserialize objects supporting RawDeserializable
public static func deserialize<T:RawDeserializable where T.RawType:Deserializable>(data:NSData) -> T?

// Serialize objects supporting RawDeserializable
public static func serialize<T:RawDeserializable>(value:T) -> NSData
```

Note that RawType is required to be Deserializable to be deserialized. An Enum partially supports RawDeserializable, so,

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
if let value : Enabled = Serde.deserialize(data) {
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
### <a name="serde_rawarraydeserializable">RawArrayDeserializable Protocol</a>

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
// Deserialize objects supporting RawArrayDeserializable
public static func deserialize<T:RawArrayDeserializable where T.RawType:Deserializable>(data:NSData) -> T?

// Serialize objects supporting RawArrayDeserializable
public static func serialize<T:RawArrayDeserializable>(value:T) -> NSData
```

Note that RawType is required to be Deserializable to be deserialized. RawArrayDeserializable can be implemented in a struct or class.

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

### <a name="serde_rawpairdeserializable">RawPairDeserializable Protocol</a>

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
// Deserialize objects supporting RawPairDeserializable
public static func deserialize<T:RawPairDeserializable where T.RawType1:Deserializable, T.RawType2:Deserializable>(data:NSData) -> T?

// Serialize objects supporting RawPairDeserializable
public static func serialize<T:RawPairDeserializable>(value:T) -> NSData
```

Note that RawType1 and RawType2 are required to be Deserializable to be deserialized. RawPairDeserializable can be implemented in a struct or class.

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

### <a name="serde_rawarraypairdeserializable">RawArrayPairDeserializable Protocol</a>

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
// Deserialize objects supporting RawPairDeserializable
public static func deserialize<T:RawArrayPairDeserializable where T.RawType1:Deserializable,  T.RawType2:Deserializable>(data:NSData) -> T?

// Deserialize objects supporting RawPairDeserializable
public static func serialize<T:RawArrayPairDeserializable>(value:T) -> NSData
```

Note that RawType1 and RawType2 are required to be Deserializable to be deserialized. RawArrayPairDeserializable can be implemented in a struct or class.

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

GATT profile definitions are required to add support for a device to the BlueCap app but are not required to build a functional application using the framework. Implementing a GATT profile for a device allows the framework to automatically identify and configure Services and Characteristics and provides serialization and deserialization of Characteristic values to and from Strings. The examples in this section are also available in a BlueCap [Playground](https://github.com/troystribling/BlueCap/tree/master/BlueCap/Profile.playground)

### <a name="gatt_serviceconfigurable">ServiceConfigurable Protocol</a>

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

### <a name="gatt_characteristicconfigurable">CharacteristicConfigurable Protocol</a>

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

### <a name="gatt_stringdeserializable">StringDeserializable Protocol</a>

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

### <a name="gatt_configuredserviceprofile">ConfiguredServiceProfile</a>

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
 
### <a name="gatt_characteristicprofile">CharacteristicProfile</a>

CharacteristicProfile is the base class for each of the following profile types and is instantiated as the characteristic profile if a profile is not explicitly defined for a discovered Characteristic. In this case, with no String conversions implemented in a GATT Profile definition, a Characteristic will support String conversions to a from hexadecimal Strings.

When defining a GATT profile it is sometimes convenient to specify that something be done after a Characteristic is discovered by a Central.

```swift
public func afterDiscovered(capacity:Int?) -> FutureStream<Characteristic>
``` 

### <a name="gatt_rawcharacteristicprofile">RawCharacteristicProfile</a>

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

### <a name="gatt_rawarraycharacteristicprofile">RawArrayCharacteristicProfile</a>

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

### <a name="gatt_rawpaircharacteristicprofile">RawPairCharacteristicProfile</a>

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

### <a name="gatt_rawarraypaircharacteristicprofile">RawArrayPairCharacteristicProfile</a>

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

### <a name="gatt_stringcharacteristicprofile">StringCharacteristicProfile</a>

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

### <a name="gatt_profilemanager">ProfileManager</a>

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

### <a name="gatt_add_profile">Add Profile to BlueCap App</a>

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

