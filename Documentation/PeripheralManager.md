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

`MutableService` provides the methods for adding `MutableCharacteristics`,

```swift
// add characteristics
public var characteristics = [MutableCharacteristic] {get set}

// create characteristics from profiles
public func characteristicsFromProfiles()
```

A `PeripheralManager` application adds `MutableServices` and `MutableCharacteristics` using,

```swift
enum AppError: Error {
    case invalidState
    case resetting
    case poweredOff
    case unsupported
    case unlikely
}

let manager = PeripheralManager(options: [CBPeripheralManagerOptionRestoreIdentifierKey : "us.gnos.BlueCap.peripheral-manager-documentation" as NSString])

let service = MutableService(uuid: TISensorTag.AccelerometerService.uuid)

let characteristic = MutableCharacteristic(profile: RawArrayCharacteristicProfile<TISensorTag.AccelerometerService.Data>())

// Add Characteristic to Service
service.characteristics = [characteristic]
 
let addServiceFuture = manager.whenStateChanges().flatMap { state -> Future<Void> in
    guard let manager = manager else {
        throw AppError.unlikely
    }    
    switch state {
    case .poweredOn:
        manager.removeAllServices()
        return manager.add(self.accelerometerService)
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
    guard let manager = manager else {
        return
    }    
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

After `Services` and `Characteristics` have been added the `PeripheralManager` is ready to begin advertising. `PeripheralManager` provides the following methods to manage advertisement,

```swift
// start advertising with name and services
public func startAdvertising(_ name: String, uuids: [CBUUID]? = nil) -> Future<Void>

// stop advertising
public func stopAdvertising(timeout: TimeInterval = 10.0) -> Future<Void>
```

A `PeripheralManager` application can start advertising after `MutableServices` and `MutableCharacteristics` are added,

```swift
let serviceUUID = CBUUID(string: TISensorTag.AccelerometerService.uuid)

let startAdvertisingFuture = addServiceFuture.flatMap { _ -> Future<Void> in 
	  guard let manager = manager else {
        throw AppError.unlikely
    }    
	manager.startAdvertising(TISensorTag.AccelerometerService.name, uuids: [serviceUUID])
}
```

Here the `addServiceFuture` is completed after `Services` are added and `PeripheralManager` is advertising that it supports the `TISensorTag.AccelerometerService`.

### <a name="peripheral_set_characteristic_value">Get and Set Characteristic Value</a>

A `MutableCharacteristic` value can be set any time after its supporting `MutableService` has been successfully added to `PeripheralManager`. The `value` is defined by,

```swift
var value : NSData? {get set}
```

A `PeripheralManager` application can set a `MutableCharacteristic` value using,

```swift
characteristic.value = Serde.serialize(Enabled.yes)

guard let value: Enabled = characteristic.value {
    return
}
```

### <a name="peripheral_update_characteristic_value">Updating Characteristic Value</a>

If a `MutableCharacteristic` supports either `CBCharacteristicProperties` of  `CBCharacteristicProperties.notify`,  `CBCharacteristicProperties.indicate`, `CBCharacteristicProperties.notifyEncryptionRequired`, or `CBCharacteristicProperties.indicateEncryptionRequired` and a `MutableService` supporting the `MutableCharacteristic` have been successfully added to `PeripheralManager` a `Central` can subscribe to value updates. In addition to setting the new value an update notification must be sent. `MutableCharacteristic` provides the following methods to support notification updates,

```swift
// update with Data
public func update(withData value: Data) throws

// update with String
public func update(withString value: [String:String]) throws

// update with object supporting Deserializable
public func update<T: Deserializable>(_ value: T) throws {

// update with object supporting RawDeserializable
public func update<T: RawDeserializable>(_ value: T) throws

// update with object supporting RawArrayDeserializable
public func update<T: RawArrayDeserializable>(_ value: T) throws

// update with object supporting RawPairDeserializable
public func update<T: RawPairDeserializable>(_ value: T) throws

// update with object supporting RawArrayPairDeserializable
public func update<T: RawArrayPairDeserializable>(_ value: T) throws
```

All methods `throw` if the `MutableCharacteristic` either has not been added to `PeripheralManager` or supports none of the notify `CBCharacteristicProperties`. Additionally `update(withString:)` will `throw` if the `String` value cannot be serialized. If the value is updated and there are no subscribers or the system CoreBluetooth update fails the update will be queued and sent when a `Central` subscribes or the system indicates that updates can continue. In addition to sending an update notification to a subscribing `Central` `update` sets the `MutabaleCharacteristic` value.

Peripheral applications would send notification updates using,

```swift
let updateStatus = try characteristic.updateValue(Enabled.no)
```

### <a name="peripheral_respond_characteristic_write">Respond to Characteristic Write</a>

If a `MutableCharacteristic` supports  `CBCharacteristicProperties.write` a `Central` can change the `MutableCharacteristic` value. `MutableCharacteristic` supports the following methods supporting write requests,

```swift
// start processing write requests with specified stream capacity
public func startRespondingToWriteRequests(capacity: Int = Int.max) -> FutureStream<(request: CBATTRequestInjectable, central: CBCentralInjectable)>

// respond to received write request
public func respondToRequest(_ request: CBATTRequestInjectable, withResult result: CBATTError.Code)

// stop processing write requests
public func stopRespondingToWriteRequests()
```

[CBATTRequest](https://developer.apple.com/library/prerelease/ios/documentation/CoreBluetooth/Reference/CBATTRequest_class/index.html) encapsulates Central write requests, [CBATTError](https://developer.apple.com/library/prerelease/ios/documentation/CoreBluetooth/Reference/CoreBluetooth_Constants/index.html#//apple_ref/c/tdef/CBATTError) encapsulates the response error code and a [SimpleFutures](https://github.com/troystribling/SimpleFutures).

`PeripheralManager` applications would start responding to `Central` writes requests using,

```swift
let writeResponseFuture = characteristic.startRespondingToWriteRequests(capacity: 10)

writeResponseFuture.onSuccess { [weak characteristic] (request, _) in
    guard let characteristic = characteristic else {
        throw AppError.unlikely
    }    
    guard request.value.length == 1 else {
        characteristic.respondToRequest(request, withResult:CBATTError.InvalidAttributeValueLength)
        Return
    }
    characteristic.value = request.value
    characteristic.respondToRequest(request, withResult:CBATTError.Success)
}
```

Here the length of the `Characteristic` value is expected to be 1 byte.

`PeripheralManager` applications will stop responding to write requests using,

```swift
characteristic.stopProcessingWriteRequests()
```

### <a name="peripheral_ibeacon_emulation">iBeacon Emulation</a>

`iBeacon` emulation does not require `MutableServices` or `MutableCharcteristics` to be added to `PeripheralManager`. Only advertising is required. `PeripheralManager` provides the following methods supporting `iBeacon` advertisement, 

```swift
// start advertising beceacon region
public func startAdvertising(_ region: BeaconRegion) -> Future<Void>

// stop advertising
public func stopAdvertising(timeout: TimeInterval = 10.0) -> Future<Void>
```

Creation of a [FutureLocation](https://github.com/troystribling/FutureLocation) `BeaconRegion` is also required,

```swift
public convenience init(proximityUUID: UUID, identifier: String, major: UInt16, minor: UInt16, capacity: Int = Int.max)
```

The `BeaconRegion` `init` parameters are,

<table>
	<tr>
		<td>proximityUUID</td>
		<td>The proximityUUID of the beacon targeted.</td>
	</tr>
	<tr>
		<td>identifier</td>
		<td>A unique identifier for region used by application.</td>
	</tr>
	<tr>
		<td>major</td>
		<td>The major value can be used to distinguish between different beacons with the same proximityUUID.</td>
	</tr>
	<tr>
		<td>minor</td>
		<td>The minor value can be used to distinguish between different beacons with the same proximityUUID and major value.</td>
	</tr>
</table>

A `PeripheralManager` application would use the flooring to advertise and iBeacon,

```swift
enum AppError: Error {
    case invalidState
    case resetting
    case poweredOff
    case unsupported
}

let manager = PeripheralManager(options: [CBPeripheralManagerOptionRestoreIdentifierKey : "us.gnos.BlueCap.peripheral-manager-documentation" as NSString])

let uuid = UUID(uuidString: "B9407F30-F5F8-466E-AFF9-25556B57FE6D")!

BeaconRegion(proximityUUID: uuid, identifier: "iBeacon", major: 1, minor: 1)

let startAdvertiseFuture = manager.whenStateChanges().flatMap { state -> Future<Void> in
    guard let manager = manager else {
        throw AppError.unlikely
    }    
   switch state {
    case .poweredOn:
        return manager.startAdvertising(beaconRegion)
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
    _ = manager.stopAdvertising()
}
```

See the [Beacon Example](/Examples/Beacon) for details.

### <a name="peripheral_state_restoration">State Restoration</a>

CoreBluetooth provides [state restoration](https://developer.apple.com/library/content/documentation/NetworkingInternetWeb/Conceptual/CoreBluetooth_concepts/CoreBluetoothBackgroundProcessingForIOSApps/PerformingTasksWhileYourAppIsInTheBackground.html) for apps that have declared `bluetooth-peripheral` background execution permission. Apps with this permission can be restarted with a previous state if evicted from memory while in the background. 

`PeripheralManager` provides the following method to process the restored application state,

```swift
public func whenStateRestored() -> Future<PeripheralAdvertisements>
```

### <a name="peripheral_errors">Errors</a>

```swift
public enum PeripheralManagerError: Swift.Error {
    // Thrown by startAdvertising if the PeripheralManager is already advertising
    case isAdvertising
	  // Thrown is state restoration fails    
    case restoreFailed
    // Thrown if the stop advertising timeout is exceeded
    case stopAdvertisingTimeout
}

public enum MutableServiceError: Swift.Error {
		// MutableService has no CBMutableService.
    case unconfigured
}
 
public enum MutableCharacteristicError : Swift.Error {
    // Thrown by startRespondingToWriteRequests and update if Mutablecharcteristic has not been added to a PeripheralManager
    case unconfigured
    // Thrown by update(withString:) if String Characteristic value cannot be serialized
    case notSerializable
    // Thrown by update if Characteristic notifiy or indicate property is not enabled
    case notifyNotSupported
}
```

