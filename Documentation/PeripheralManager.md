# PeripheralManager

The BlueCap PeripheralManager implementation replaces [CBPeripheralManagerDelegate](https://developer.apple.com/library/prerelease/ios/documentation/CoreBluetooth/Reference/CBPeripheralManagerDelegate_Protocol/index.html#//apple_ref/occ/intf/CBPeripheralManagerDelegate) protocol implementations with with a Scala Futures interface using [SimpleFutures](https://github.com/troystribling/SimpleFutures). Futures provide inline implementation of asynchronous callbacks and allows chaining asynchronous calls as well as error handling and recovery. This section will describe interfaces and give example implementations for all supported use cases. [Simple example applications](https://github.com/troystribling/BlueCap/tree/master/Examples) can be found in the BlueCap github repository.

## Contents

* [PowerOn/PowerOff](#peripheral_poweron_poweroff): Detect when the bluetooth transceiver is powered on and off.
* [Add Services and Characteristics](#peripheral_add_characteristics): Add services and characteristics to a Peripheral application.
* [Advertising](#peripheral_advertising): Advertise a Peripheral application.
* [Set Characteristic Value](#peripheral_set_characteristic_value): Set a characteristic value for a Peripheral application.
* [Update Characteristic Value](#peripheral_update_characteristic_value): Send characteristic value update notifications to Centrals.
* [Respond to Characteristic Write](#peripheral_respond_characteristic_write): Respond to characterize value writes from a Central.
* [iBeacon Emulation](#peripheral_ibeacon_emulation): Emulate an iBeacon with a Peripheral application.
* [State Restoration](#peripheral_state_restoration): Restore state of `PeripheralManager` using iOS state restoration.
* [Errors](#peripheral_errors): Description of all errors.
* [KVO](#peripheral_kvo): Properties supporting KVO.

### <a name="peripheral_poweron_poweroff">PowerOn/PowerOff</a>

The state of the Bluetooth transceiver on a device is communicated to `BlueCap` application by the `PeripheralManager` methods `whenPowerOn` and `whenPowerOff`, which are defined by,

```swift
public func whenPowerOn() -> Future<Void>
public func whenPowerOff() -> Future<Void>
```

Both methods return a [SimpleFutures](https://github.com/troystribling/SimpleFutures) `Future<Void>`. For an application to process events,

```swift
let manager = PeripheralManager()
let powerOnFuture = manager.whenPowerOn()
powerOnFuture.onSuccess {
}
powerOnFuture.onFailure { error in
}

let powerOffFuture = manager.whenPowerOff()
powerOffFuture.onSuccess {
}
```

When `PeripheralManager` is instantiated a message giving the current Bluetooth transceiver state is received. After instantiation messages are received if the transceiver is powered on or powered off. `whenPowerOff` cannot fail. `whenPowerOn` only fails if Bluetooth is not supported.

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

### <a name="peripheral_state_restoration">State Restoration</a>

### <a name="peripheral_errors">Errors</a>

### <a name="peripheral_kvo">KVO</a>

