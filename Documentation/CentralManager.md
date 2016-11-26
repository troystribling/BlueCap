# <a name="central">CentralManager</a>

The `BlueCap` `CentralManager` implementation replaces [`CBCentralManagerDelegate`](https://developer.apple.com/library/prerelease/ios/documentation/CoreBluetooth/Reference/CBCentralManagerDelegate_Protocol/index.html#//apple_ref/occ/intf/CBCentralManagerDelegate) and [`CBPeripheralDelegate`](https://developer.apple.com/library/prerelease/ios/documentation/CoreBluetooth/Reference/CBPeripheralDelegate_Protocol/index.html#//apple_ref/occ/intf/CBPeripheralDelegate) protocol implementations with with a Scala Futures interface using [`SimpleFutures`](https://github.com/troystribling/SimpleFutures). Futures provide an interface for performing nonblocking asynchronous requests and serialization of multiple requests. This section will give example implementations for supported use cases.

## Contents

* [State Change](#central_state_change): Detect when the `CBCentralManager` changes state.
* [Service Scanning](#central_service_scanning): Scan for services.
* [Peripheral Advertisements](#central_peripheral_advertisements): Access Advertisements of discovered Peripherals.
* [Peripheral Connection](#central_peripheral_connection): Connect to discovered Peripherals.
* [Service and Characteristic Discovery](#central_characteristic_discovery): Discover Services and Characteristics of connected Peripherals.
* [Characteristic Write](#central_characteristic_write): Write a characteristic value to a connected Peripheral.
* [Characteristic Read](#central_characteristic_read): Read a characteristic value from a connected Peripheral.
* [Characteristic Update Notifications](#central_characteristic_update): Subscribe to characteristic value updates on a connected Peripheral.
* [Retrieve Peripherals](#central_retrieve_peripherals): Retrieve `Peripheral` objects cached by `CoreBluetooth`.
* [Peripheral RSSI](#central_rssi): Retrieve and poll for RSSI.
* [State Restoration](#central_state_restoration): Restore state of `CentralManager` using iOS state restoration.
* [Errors](#central_errors): Description of all errors.
* [Statistics](#central_errors): Peripheral connection statistics.
 
### <a name="central_state_change">PowerOn/PowerOff</a>

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

The state of `CBCentralManager` is communicated to an application by the `CentralManager` method,

```swift
public func whenStateChanges() -> FutureStream<ManagerState>
```

To process events,

```swift
let Manager = CentralManager(options [CBCentralManagerOptionRestoreIdentifierKey : "us.gnos.BlueCap.documentation-manager" as NSString])

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

stateChangeFuture.onFailure { error in
}
```

### <a name="central_service_scanning">Service Scanning</a>

Scans for advertising peripherals are initiated by calling the `CentralManager` methods,

```swift
// Scan promiscuously for all advertising peripherals
public func startScanning(capacity: Int = Int.max, duration: TimeInterval = TimeInterval.infinity, options: [String : Any]? = nil) -> FutureStream<Peripheral>

// Scan for peripherals advertising services with UUIDs
 public func startScanning(forServiceUUIDs UUIDs: [CBUUID]?, capacity: Int = Int.max, duration: TimeInterval = TimeInterval.infinity, options: [String : Any]? = nil) -> FutureStream<Peripheral>
```

Both methods return a [SimpleFutures](https://github.com/troystribling/SimpleFutures) `FutureStream<Peripheral>` yielding the discovered `Peripheral`.

The input parameters for both methods are,

<table>
  <tr>
    <td>UUIDs</td>
    <td>Scanned service UUIDs.</td>
  </tr>
	<tr>
		<td>capacity</td>
		<td>FutureStream capacity. The default value is infinite.</td>
	</tr>
	<tr>
		<td>duration</td>
		<td>Duration of scan. An error is thrown an scanning stops if nothing is discovered.</td>
	</tr>
	<tr>
		<td>options</td>
		<td> See CBCentralManager scanning <a href="https://developer.apple.com/library/ios/documentation/CoreBluetooth/Reference/CBCentralManager_Class/#//apple_ref/doc/constant_group/Peripheral_Scanning_Options">options</a>.</td>
	</tr>
</table>

An application starts scanning for `Peripherals` advertising `Services` with `UUIDs` after power on with the following,

```swift
public enum AppError : Error {
    case invalidState
    case resetting
    case poweredOff
    case unknown
}

let Manager = CentralManager(options [CBCentralManagerOptionRestoreIdentifierKey : "us.gnos.BlueCap.documentation-manager" as NSString])

let serviceUUID = CBUUID(string: TISensorTag.AccelerometerService.UUID)

let scanFuture = manager.whenStateChanges().flatMap { [unowned self] state -> FutureStream<Peripheral> in
    switch state {
    case .poweredOn:
        return self.manager.startScanning(forServiceUUIDs: [serviceUUID], capacity: 10)
    case .poweredOff:
        throw AppError.poweredOff
    case .unauthorized, .unsupported:
        throw AppError.invalidState
    case .resetting:
        throw AppError.resetting
    case .unknown:
        throw AppError.unknown
    }
}

scanFuture { error in
    guard let appError = error as? AppError else {
        return
    }
}
```

To stop a peripheral scan use the `CentralManager` method,

```swift
public func stopScanning()
```

### <a name="central_peripheral_advertisements">Peripheral Advertisements</a>

`Peripheral` advertisements are encapsulated by the  `PeripheralAdvertisements` `struct` defined by,

```swift
public struct PeripheralAdvertisements {
    // Local peripheral name with key CBAdvertisementDataLocalNameKey
    public var localName: String? 

    // Manufacture data with key CBAdvertisementDataManufacturerDataKey    
    public var manufactuereData: Data? 

    // Tx power with with key CBAdvertisementDataTxPowerLevelKey
    public var txPower: NSNumber? 

    // Is connectable with key CBAdvertisementDataIsConnectable
    public var isConnectable: NSNumber? 
    
    // Advertised service UUIDs with key CBAdvertisementDataServiceUUIDsKey
    public var serviceUUIDs: [CBUUID]? 

    // Advertised service data with key CBAdvertisementDataServiceDataKey
    public var serviceData: [CBUUID : Data]? 

    // Advertised overflow services with key CBAdvertisementDataOverflowServiceUUIDsKey
    public var overflowServiceUUIDs: [CBUUID]? 

    // Advertised solicited services with key CBAdvertisementDataSolicitedServiceUUIDsKey
    public var solicitedServiceUUIDs: [CBUUID]?
}
```

The `PeripheralAdvertisements` `struct` is accessible through the property `Peripheral#advertisements`.

```swift
public let advertisements: PeripheralAdvertisements
```


### <a name="central_peripheral_connection">Peripheral Connection</a>

After discovering a `Peripheral` a connection must be established to run discovery and begin messaging. Connecting and maintaining a connection to a Bluetooth device can be difficult since signals are weak and devices may have relative motion. `BlueCap` provides connection events enabling applications to easily handle anything that can happen. `ConnectionEvent` is defined by,

```swift
public enum ConnectionEvent {
    case connect
    case timeout
    case disconnect
    case forceDisconnect
    case giveUp
}
```

<table>
  <tr>
    <th>Event</th>
    <th>Description</th>
  </tr>
	<tr>
		<td>connect</td>
		<td>Connected to peripheral.</td>
	</tr>
	<tr>
		<td>timeout</td>
		<td>Connection attempt timeout.</td>
	</tr>
	<tr>
		<td>disconnect</td>
		<td>Peripheral disconnected.</td>
	</tr>
	<tr>
		<td>forceDisconnect</td>
		<td>Peripheral disconnected by application.</td>
	</tr>
	<tr>
		<td>giveUp</td>
		<td>Give up trying to connect.</td>
	</tr>
</table>

To connect to a `Peripheral` use The `Peripheral` method,

```swift
public func connect(timeoutRetries: UInt = UInt.max, disconnectRetries: UInt = UInt.max, connectionTimeout: TimeInterval = TimeInterval.infinity, capacity: Int = Int.max) -> FutureStream<(peripheral: Peripheral, connectionEvent: ConnectionEvent)>
```

The method returns a [SimpleFutures](https://github.com/troystribling/SimpleFutures) `FutureStream(peripheral: Peripheral, connectionEvent: ConnectionEvent)>` yielding a tuple containing the connected `Peripheral` and the `ConnectionEvent`. 

The input parameters are,

<table>
	<tr>
		<td>timeoutRetries</td>
		<td>Maximum number of connection retries after timeout. The default value is infinite.</td>
	</tr>
	<tr>
		<td>disconnectRetries</td>
		<td>Maximum number of connection retries on disconnect. The default value is infinite.</td>
	</tr>
	<tr>
		<td>connectionTimeout</td>
		<td>Connection timeout in seconds. The default is infinite.</td>
	</tr>
	<tr>
		<td>capacity</td>
		<td>FutureStream capacity. The default value is infinite.</td>
	</tr>
</table>

Other `Peripheral` connection management methods are,

```swift
// Reconnect with specified delay
public func reconnect(withDelay delay: Double = 0.0)

// Force disconnect from peripheral
public func disconnect()

// Disconnect from peripheral and remove it from application 
// cache
public func terminate()
```

The `Peripheral#reconnect` method is used to establish a connection to a previously connected `Peripheral`. The method takes a single parameter `reconnectDelay` used to specify a delay, in seconds, before trying to reconnect. The default value is `0.0` seconds. I called before `Peripheral#connect` a connection with default parameters will be attempted.

`Peripheral#disconnect` preforms and immediate disconnection from the connected `Peripheral` and will generate the `ConnectionEvent` `ForceDisconnect`. If the `Peripheral` is disconnected the `Peripheral#connect` `FutureStream#onFailure` will complete with `PeripheralError.disconnected`.

`Peripheral#terminate` performs a `Peripheral#disconnect` and also removes the `Peripheral` from the application cache.

After a `Peripheral` is discovered an application connects using,

```swift
let connectionFuture = scanFuture.flatMap { peripheral -> FutureStream<(peripheral: Peripheral, connectionEvent: ConnectionEvent)> in
    manager.stopScanning()
    return peripheral.connect(timeoutRetries:5, disconnectRetries:5, connectionTimeout: 10.0)
}

connectionFuture.onSuccess { (peripheral, connectionEvent) in
    switch connectionEvent {
    case .connect:
        break
    case .timeout:
        peripheral.reconnect()
    case .disconnect:
        peripheral.reconnect()
    case .forceDisconnect:
        break
    case .giveUp:
        peripheral.terminate()
    }
}

connectionFuture.onFailure { error in
}
```

Here the `scanFuture` is completed after `Peripheral` discovery and `flatMap` combines it with the connection `FutureStream`. This ensures that connections are made after `Peripherals` are discovered. When `ConnectionEvents` of `.timeout` and `.disconnect` are received an attempt is made to `reconnect` the `Peripheral`. The connection is configured for a maximum of 5 timeout retries and 5 disconnect retries. If either of these thresholds is exceeded a `.giveUp` event is received and the `Peripheral` connection is terminated ending all reconnection attempts.

### <a name="central_characteristic_discovery">Service and Characteristic Discovery</a>

After a `Peripheral` is connected its `Services` and `Characteristics` must be discovered before `Characteristic` values can be read or written to or update notifications can be received.

The `Peripheral` methods used to discover `Services` are,

```swift
// Discover all services supported by peripheral
public func discoverAllServices(timeout: TimeInterval = TimeInterval.infinity) -> Future<Peripheral>

// Discover services with specified UUIDs
public func discoverServices(_ services: [CBUUID]?, timeout: TimeInterval = TimeInterval.infinity) -> Future<Peripheral>
```

Both methods return a [SimpleFutures](https://github.com/troystribling/SimpleFutures) `Future<Peripheral>` yielding the connected `Peripheral`.

The `Service` methods used to discover `Characteristics` are,

```swift
// Discover all characteristics supported by service
public func discoverAllCharacteristics(timeout: TimeInterval = TimeInterval.infinity) -> Future<Service>

// Discover characteristics with specified UUIDs
public func discoverCharacteristics(_ characteristics: [CBUUID], timeout: TimeInterval = TimeInterval.infinity) -> Future<Service>
```

Both methods return a [SimpleFutures](https://github.com/troystribling/SimpleFutures) `Future<Service>` yielding the supporting `Service`.

After a `Peripheral` is connected `Services` and `Characteristics` are discovered using,

```swift
public enum AppError : Error {
    case charactertisticNotFound
    case serviceNotFound
    case disconnected
    case connectionFailed
}

let discoveryFuture = connectionFuture.flatMap { [unowned self] (peripheral, connectionEvent) -> Future<Peripheral> in
    switch connectionEvent {
    case .connect:
        peripheral.discoverServices([serviceUUID])
    case .timeout:
        throw AppError.disconnected
    case .disconnect:
        throw AppError.disconnected
    case .forceDisconnect:
        throw AppError.connectionFailed
    case .giveUp:
        throw AppError.connectionFailed
}.flatMap { peripheral -> Future<Service> in
    guard let service = peripheral.service(serviceUUID) else {
        throw AppError.serviceNotFound
    }
    return service.discoverCharacteristics([dataUUID, enabledUUID, updatePeriodUUID])
}
```

Here the [`peripheralConnectFuture`](#central_peripheral_connection) is flatmapped to `discoverPeripheralServices(services: [CBUUID]!) -> Future<Peripheral>` to ensure that the `Peripheral` is connected before `Service` and `Characteristic` discovery starts.

### <a name="central_characteristic_write">Characteristic Write</a>

After `Peripheral` `Characteristics` are discovered writing `Characteristic` values is possible. `Characteristic` methods available for writing, where each supports a value of a different type,

```swift
// Write an NSData object to characteristic value
public func writeData(value: NSData, timeout: Double = Double.infinity, type: CBCharacteristicWriteType = .WithResponse) -> Future<Characteristic>

// Write a characteristic String Dictionary value
public func writeString(stringValue: [String: String], timeout: Double = Double.infinity, type: CBCharacteristicWriteType = .WithResponse) -> Future<Characteristic>

// Write a Deserializable characteristic value
public func write<T:Deserializable>(value:T, timeout: Double = Double.infinity, type: CBCharacteristicWriteType = .WithResponse) -> Future<Characteristic>

// Write a RawDeserializable characteristic value
public func write<T:RawDeserializable>(value:T, timeout: Double = Double.infinity, type: CBCharacteristicWriteType = .WithResponse) -> Future<Characteristic>

// Write a RawArrayDeserializable characteristic value
public func write<T:RawArrayDeserializable>(value:T, timeout: Double = Double.infinity, type: CBCharacteristicWriteType = .WithResponse) -> Future<Characteristic>

// Write a RawPairDeserializable characteristic value
public func write<T:RawPairDeserializable>(value:T, timeout: Double = Double.infinity, type: CBCharacteristicWriteType = .WithResponse) -> Future<Characteristic>

// Write a RawArrayPairDeserializable characteristic value
public func write<T:RawArrayPairDeserializable>(value:T, timeout: Double = Double.infinity, type: CBCharacteristicWriteType = .WithResponse) -> Future<Characteristic>
```

Each of the `write` methods input parameters with only variation in the type and return a [SimpleFutures](https://github.com/troystribling/SimpleFutures) `Future<Characteristic>` yielding the `Characteristic`,

<table>
	<tr>
		<td>value</td>
		<td>The value written to the characteristic.</td>
	</tr>
	<tr>
		<td>timeout</td>
		<td>Write timeout in seconds. The default value is infinite.</td>
	</tr>
	<tr>
		<td>type</td>
		<td>Characteristic write types, see <a href="https://developer.apple.com/reference/corebluetooth/cbcharacteristicwritetype">CBCharacteristicWriteType</a> type, The default value is .WithResponse.
		</td>
	</tr>
</table>

Using the [RawDeserializable enum](/Documentation/SerializationDeserialization.md/#serde_rawdeserializable) an application can write a `Characteristic` after connecting to a `Peripheral` and running `Service` and `Characteristic` discovery with the following,

```swift
// RawDeserializable enum
enum Enabled : UInt8, RawDeserializable {
    case No  = 0
    case Yes = 1
    public static let uuid = "F000AA12-0451-4000-B000-000000000000"
}
let enabledUUID = CBUUID(string:Enabled.uuid)!

let writeCharacteristicFuture = characteristicsDiscoveredFuture.flatmap {peripheral -> Future<Characteristic> in
	if let service = peripheral.service(serviceUUID),
	       characteristic = service.characteristic(enabledUUID) {
		return characteristic.write(Enabled.Yes, timeout: 20.0)
	} else {
		let promise = Promise<Characteristic>()
		promise.failure(ApplicationError.characteristicNotFound)
		return promise.future
	}
}

writeCharacteristicFuture.onSuccess { characteristic in
}
writeCharacteristicFuture.onFailure { error in
}
```

Here the [`characteristicsDiscoveredFuture`](#central_characteristic_discovery) is flatmapped to `write<T: RawDeserializable>(value:T, timeout: Double = Double.infinity, type: CBCharacteristicWriteType = .WithResponse) -> Future<Characteristic> to ensure that characteristic has been discovered before writing. An error is returned if the characteristic is not found. 

### <a name="central_characteristic_read">Characteristic Read</a>

After a `Peripherals` `Characteristics` are discovered reading `Characteristic` values is possible. `Characteristic` provides the following method to retrieve values from connected `Peripherals`,

```swift
// Read a characteristic from a peripheral service
public func read(timeout: Double = Double.infinity) -> Future<Characteristic>
```

The `read` method takes a single input parameter, used to specify the timeout. The default value for `timeout` is infinite. `read` returns a [SimpleFutures](https://github.com/troystribling/SimpleFutures) `Future<Characteristic>` yielding the `Characteristic`. To retrieve the `Characteristic` value after a successful read the following methods are available, where each returns values a different type,

```swift
// Return the characteristic value as and NSData object
public var dataValue : NSData!

// Return the characteristic value as a String Dictionary.
public var stringValue :[String:String]?

// Return a Deserializable characteristic value
public func value<T: Deserializable>() -> T?

// Return a RawDeserializable characteristic value
public func value<T: RawDeserializable where T.RawType: Deserializable>() -> T?

// Return a RawArrayDeserializable characteristic value
public func value<T: RawArrayDeserializable where T.RawType: Deserializable>() -> T?

// Return a RawPairDeserializable characteristic value
public func value<T: RawPairDeserializable where T.RawType1: Deserializable, T.RawType2: Deserializable>() -> T?
```

Using the [RawDeserializable enum](#central_characteristic_write) an application can read a `Characteristic` after connecting to a `Peripheral` and running `Service` and `Characteristic` discovery with the following,

```swift
let readCharacteristicFuture = characteristicsDiscoveredFuture.flatmap { peripheral -> Future<Characteristic> in
	if let service = peripheral.service(serviceUUID), characteristic = service.characteristic(enabledUUID) {
		return characteristic.read(10.0)
	} else {
		let promise = Promise<Characteristic>()
		promise.failure(ApplicationError.characteristicNotFound)
		return promise.future
	}
}
readCharacteristicFuture { characteristic in
	if let value : Enabled = characteristic.value {
	}
}
readCharacteristicFuture { error in
}
```

Here the [`characteristicsDiscoveredFuture`](#central_characteristic_discovery) is flatmapped to `read(timeout: Double = Double.infinity) -> Future<Characteristic> to ensure that characteristic has been discovered before reading. On a successful read the value is retrieved using `public func value<T: RawDeserializable where T.RawType: Deserializable>() -> T?`. An error is returned if the characteristic is not found. 

### <a name="central_characteristic_update">Characteristic Update Notifications</a>

After a `Peripherals` `Characteristics` are discovered subscribing to `Characteristic` value update notifications is possible. Several `Characteristic` methods are available,

```swift
// subscribe to characteristic update
public func startNotifying() -> Future<Characteristic>

// receive characteristic value updates
public func receiveNotificationUpdates(capacity:Int? = nil) -> FutureStream<Characteristic>

// unsubscribe from characteristic updates
public func stopNotifying() -> Future<Characteristic>

// stop receiving characteristic value updates
public func stopNotificationUpdates()
```

The work flow for receiving notification updates is to first subscribe to the notifications using `startNotifying()`. The application will then start receiving notifications. To process the notifications call `receiveNotificationUpdates(capacity:Int? = nil) -> FutureStream<Characteristic>` which returns a [SimpleFutures](https://github.com/troystribling/SimpleFutures) `FutureStream<Characteristic>` yielding the `Characteristic` from which the updated characteristic can be obtained.

To stop processing notifications call `stopNotifying()` and to unsubscribe to notifications call `stopNotificationUpdates()`.

Using the [RawDeserializable enum](#central_characteristic_write) an application can receive notifications from a `Characteristic` as follows,

```swift
let subscribeCharacteristicFuture = characteristicsDiscoveredFuture.flatmap { peripheral -> Future<Characteristic> in
	if let service = peripheral.service(serviceUUID), characteristic = service.characteristic(enabledUUID) {
		return characteristic.startNotifying()
	} else {
		let promise = Promise<Characteristic>()
		promise.failure(ApplicationError.characteristicNotFound)
		return promise.future
	}
}

subscribeCharacteristicFuture.onSuccess { characteristic in
}
subscribeCharacteristicFuture.onFailure { error in
}

let updateCharacteristicFuture = subscribeCharacteristicFuture.flatmap{ characteristic -> FutureStream<Characteristic> in
	return characteristic.receiveNotificationUpdates()
}
updateCharacteristicFuture.onSuccess { characteristic in
	if let value : Enabled = characteristic.value {
	}
}
updateCharacteristicFuture.onFailure { error in 
}
```

Here the [`characteristicsDiscoveredFuture`](#central_characteristic_discovery) is flatmapped to `startNotifying() -> Future<Characteristic>` to ensure that characteristic has been discovered before subscribing to updates.  Then `subscribeCharacteristicFuture` is flatmapped again to `receiveNotificationUpdates(capacity: Int?) -> FutureStream<Characteristic>` to ensure that the subscription is completed before receiving updates.

An application can unsubscribe to `Characteristic` value notifications and stop receiving updates by using the following,

```swift
// serviceUUID and enabledUUID are define in the example above
if let service = peripheral.service(serviceUUID), characteristic = service.characteristic(enabledUUID) {
	
	// stop receiving updates
	characteristic.stopNotificationUpdates()

	// unsubscribe to notifications
	characteristic.stopNotifying()
}
```

### <a name="central_retrieve_peripherals">Retrieve Peripherals</a>

### <a name="central_rssi">Peripheral RSSI</a>

### <a name="central_state_restoration">State Restoration</a>

### <a name="central_errors">Errors</a>

```swift
public enum CharacteristicError : Swift.Error {
    case readTimeout
    case writeTimeout
    case notSerializable
    case readNotSupported
    case writeNotSupported
    case notifyNotSupported
}

public enum PeripheralError : Swift.Error {
    case disconnected
    case noServices
    case serviceDiscoveryTimeout
}

public enum CentralManagerError : Swift.Error {
    case isScanning
    case isPoweredOff
    case restoreFailed
    case peripheralScanTimeout
    case unsupported
}

public enum ServiceError : Swift.Error {
    case characteristicDiscoveryTimeout
    case characteristicDiscoveryInProgress
}
```

### <a name="central_stats">Statistics</a>