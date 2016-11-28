# PeripheralManager

The BlueCap PeripheralManager implementation replaces [CBPeripheralManagerDelegate](https://developer.apple.com/library/prerelease/ios/documentation/CoreBluetooth/Reference/CBPeripheralManagerDelegate_Protocol/index.html#//apple_ref/occ/intf/CBPeripheralManagerDelegate) protocol implementations with with a Scala Futures interface using [SimpleFutures](https://github.com/troystribling/SimpleFutures). Futures provide an interface for performing nonblocking asynchronous requests and serialization of multiple requests. This section will give example implementations for supported use cases.

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

### <a name="peripheral_poweron_poweroff">PowerOn/PowerOff</a>

`ManagerState` is a direct mapping to [`CBManagerState`](https://developer.apple.com/reference/corebluetooth/cbmanagerstate) namely,

```swift
public enum ManagerState: CustomStringConvertible {
    case unauthorized
    case unknown
    case unsupported
    case resetting
    case poweredOff
    case poweredOn
}
```

The state of `CBPeripheralManager` is communicated to an application by the `PeripheralManager` method,

```swift
public func whenStateChanges() -> FutureStream<ManagerState>
```

To process events,

```swift
let manager = PeripheralManager(options: [CBPeripheralManagerOptionRestoreIdentifierKey : "us.gnos.BlueCap.peripheral-manager-documentation" as NSString])

let stateChangeFuture = manager.whenStateChanges()

stateChangeFuture.onSuccess { state in
    switch state {
        case .poweredOn:
            break
        case .poweredOff, .unauthorized:
            break
        case .resetting:
            break
        case .unknown:
            break
        case .unsupported:
            break
    }
}
```

### <a name="peripheral_add_characteristics">Add Services and Characteristics</a>

`Services` and `Characteristics` are added to a `PeripheralManager` application before advertising. 

`PeripheralManager` provides the following methods used for managing `Services` are,

```swift
// add a single service
public func add(_ service: MutableService) -> Future<Void>

// remove a service
public func remove(_ service: MutableService)

// remove all services
public func removeAllServices()
```

`MutableService` provides the methods for adding `Characteristics`,

```swift
// add characteristics
public var characteristics = [MutableCharacteristic] {get set}

// create characteristics from profiles
public func characteristicsFromProfiles()
```

A `PeripheralManager` application adds Services and Characteristics using,

```swift
enum AppError: Error {
    case invalidState
    case resetting
    case poweredOff
    case unsupported
}

let manager = PeripheralManager(options: [CBPeripheralManagerOptionRestoreIdentifierKey : "us.gnos.BlueCap.peripheral-manager-documentation" as NSString])

let service = MutableService(UUID: TISensorTag.AccelerometerService.UUID)

let characteristic = MutableCharacteristic(profile: RawArrayCharacteristicProfile<TISensorTag.AccelerometerService.Data>())

// Add Characteristic to Service
service.characteristics = [characteristic]
 
let addServiceFuture = manager.whenStateChanges().flatMap { state -> Future<Void> in
    switch state {
    case .poweredOn:
        self.manager.removeAllServices()
        return self.manager.add(self.accelerometerService)
    case .poweredOff:
        throw AppError.poweredOff
    case .unauthorized, .unknown:
        throw AppError.invalidState
    case .unsupported:
        throw AppError.unsupported
    case .resetting:
        throw AppError.resetting
    }
}

startAdvertiseFuture.onFailure { error in
    switch error {
    case AppError.poweredOff:
        manager.reset()
    case AppError.resetting:
        manager.reset()
    case AppError.unsupported:
        break
    default:
        manager.reset()
    }
}
```

First `MutableServices` and `MutableCharacteristics` are created  using the [`TISensorTag.AccelerometerService`](/BlueCapKit/Service%20Profile%20Definitions/TISensorTagServiceProfiles.swift#L16-216) profile. The `Characteristic` is then added to the `Service` and when `.powerOn` is received existing services are removed and the new 'Service` added.

Also, An error was added to handle `PeripheralManager` state transitions other than `.powerOn` and `PeripheralManager#reset` is used to recreate `CBPripheralManager`.

### <a name="peripheral_advertising">Advertising</a>

After services and characteristics have been added the peripheral is ready to begin advertising using the methods,

```swift
// start advertising with name and services
public func startAdvertising(_ name: String, uuids: [CBUUID]? = nil) -> Future<Void>

// stop advertising
public func stopAdvertising()
```

A `PeripheralManager` application can start advertising after `Services` and `Characteristics` are added,

```swift
Let startAdvertisingFuture = addServiceFuture.flatMap { _ -> Future<Void> in
smanager.startAdvertising(TISensorTag.AccelerometerService.name, uuids:[uuid])
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

```swift
public func whenStateRestored() -> Future<(services: [MutableService], advertisements: PeripheralAdvertisements)>
```

### <a name="peripheral_errors">Errors</a>

```swift
public enum PeripheralManagerError : Swift.Error {
    case isAdvertising
    case isNotAdvertising
    case addServiceFailed
    case restoreFailed
    case unconfigured
}
```

