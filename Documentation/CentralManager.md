# <a name="central">CentralManager</a>

The `BlueCap` `CentralManager` implementation replaces [`CBCentralManagerDelegate`](https://developer.apple.com/library/prerelease/ios/documentation/CoreBluetooth/Reference/CBCentralManagerDelegate_Protocol/index.html#//apple_ref/occ/intf/CBCentralManagerDelegate) and [`CBPeripheralDelegate`](https://developer.apple.com/library/prerelease/ios/documentation/CoreBluetooth/Reference/CBPeripheralDelegate_Protocol/index.html#//apple_ref/occ/intf/CBPeripheralDelegate) protocol implementations with with a Scala Futures interface using [`SimpleFutures`](https://github.com/troystribling/SimpleFutures). Futures provide an interface for performing nonblocking asynchronous requests and serialization of multiple requests. BlueCap also provides connection management events, scan, discovery and connection timeouts and much more. This section will give example implementations for supported use cases.

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
    case unlikely
}
```

The state of `CBCentralManager` is communicated to an application by the `CentralManager` method,

```swift
public func whenStateChanges() -> FutureStream<ManagerState>
```

To process `ManagerState` change events use,

```swift
let manager = CentralManager(options [CBCentralManagerOptionRestoreIdentifierKey : "us.gnos.BlueCap.documentation-manager" as NSString])

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

### <a name="central_service_scanning">Service Scanning</a>

Scans for advertising peripherals are initiated by calling the `CentralManager` methods,

```swift
// Scan promiscuously for all advertising peripherals
public func startScanning(capacity: Int = Int.max, timeout: TimeInterval = TimeInterval.infinity, options: [String : Any]? = nil) -> FutureStream<Peripheral>

// Scan for peripherals advertising services with UUIDs
 public func startScanning(forServiceUUIDs uuids: [CBUUID]?, capacity: Int = Int.max, timeout: TimeInterval = TimeInterval.infinity, options: [String : Any]? = nil) -> FutureStream<Peripheral>
```

Both methods return a [SimpleFutures](https://github.com/troystribling/SimpleFutures) `FutureStream<Peripheral>` yielding the discovered `Peripheral`.

The input parameters for both methods are,

<table>
  <tr>
    <td>uuids</td>
    <td>Scanned service UUIDs.</td>
  </tr>
	<tr>
		<td>capacity</td>
		<td>FutureStream capacity. The default value is infinite.</td>
	</tr>
	<tr>
		<td>timeout</td>
		<td>Scan timeout. The default value is infinite. The error CentralManagerError.peripheralScanTimeout is thrown and scanning stops if nothing is discovered within the timeout.</td>
	</tr>
	<tr>
		<td>options</td>
		<td> See CBCentralManager scanning <a href="https://developer.apple.com/library/ios/documentation/CoreBluetooth/Reference/CBCentralManager_Class/#//apple_ref/doc/constant_group/Peripheral_Scanning_Options">options</a>.</td>
	</tr>
</table>

An application starts scanning for `Peripherals` advertising `Services` with `UUIDs` after power on with the following,

```swift
public enum AppError : Error {
   case unauthorized
    case unknown
    case unsupported
    case resetting
    case poweredOff
    case poweredOn
    case unlikely
}

let manager = CentralManager(options [CBCentralManagerOptionRestoreIdentifierKey : "us.gnos.BlueCap.documentation-manager" as NSString])

let serviceUUID = CBUUID(string: TISensorTag.AccelerometerService.uuid)

Var discoveredPeripheral: Peripheral?

let scanFuture = manager.whenStateChanges().flatMap { [weak manager] state -> FutureStream<Peripheral> in
    guard let manager = manager else {
        throw AppError.unlikely
    }    
    switch state {
    case .poweredOn:
        return manager.startScanning(forServiceUUIDs: [serviceUUID], capacity: 10)
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

scanFuture.onSuccess { peripheral in
    discoveredPeripheral = peripheral
}

scanFuture.onFailure { [weak manager] error in
    guard let manager = manager, let appError = error as? else {
        return
    }
    switch appError {
    case AppError.invalidState:
	      manager.stopScanning()
        break
    case AppError.resetting:
        manager.stopScanning()
        manager.reset()
    case AppError.poweredOff:
        manager.stopScanning()
        break
    case AppError.unknown:
        manager.stopScanning()
        break
    case default:
        break
    }
}
```

Here the scan is started when `CentralManager` transitions to `.powerOn`.

Also, An error was added to handle `CentralManager` state transitions other than `.powerOn`. `CentralManager#reset` is used to recreate `CBCentralManager`.

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

After discovering a `Peripheral` a connection must be established to run discovery and begin messaging. Connecting and maintaining a connection to a Bluetooth device can be difficult since signals are weak and devices may have relative motion. `BlueCap` `Peripherals` have a configurable connection attempt timeout and errors indicating force disconnect, connection attempt timeout and formatting of `CoreBluetooth` disconnection and errors.

To connect to a `Peripheral` use The `Peripheral` method,

```swift
public func connect(connectionTimeout: TimeInterval = TimeInterval.infinity, capacity: Int = Int.max) -> FutureStream<Void>
```

The method returns a [SimpleFutures](https://github.com/troystribling/SimpleFutures) `FutureStream<Void>`. 

The input parameters are,

<table>
	<tr>
		<td>connectionTimeout</td>
		<td>Connection timeout in seconds. The default value is infinite. If the timeout is exceeded PeripheralError.connectionTimeout is thrown.</td>
	</tr>
	<tr>
		<td>capacity</td>
		<td>FutureStream capacity. The default value is infinite.</td>
	</tr>
</table>

```swift
// Reconnect with specified delay
public func reconnect(withDelay delay: Double = 0.0)

// Force disconnect from peripheral
public func disconnect()

// Disconnect from peripheral and remove it from application 
// cache
public func terminate()
```

The `Peripheral#reconnect` method is used to establish a connection to a previously connected `Peripheral`. The method takes a single parameter `reconnectDelay` used to specify a delay, in seconds, before trying to reconnect. The default value is `0.0` seconds. If it is called before `Peripheral#connect` a connection with default parameters will be attempted.

`Peripheral#disconnect` preforms and immediate disconnection from the connected `Peripheral` and `throws` `PeripheralError.forcedDisconnect`.

`Peripheral#terminate` performs a `Peripheral#disconnect` and also removes the `Peripheral` from the application cache.

After a `Peripheral` is discovered an application connects using,

```swift
let connectionFuture = scanFuture.flatMap { [weak manager] () -> FutureStream<Void> in
    manager?.stopScanning()
    discoveredPeripheral = peripheral
    return peripheral.connect(timeoutRetries:5, disconnectRetries:5, connectionTimeout: 10.0)
}

connectionFuture.onSuccess { [weak peripheral] in
	  // handle successful connection
}

connectionFuture.onFailure { error in
    switch error {
    case PeripheralError.disconnected:
        discoveredPeripheral.reconnect()
        break
    case PeripheralError.forcedDisconnect:
        break
    case PeripheralError.connectionTimeout:
        break
    default:
        break
    }
}

```

Here the `scanFuture` is completed after `Peripheral` discovery and `flatMap` combines it with the connection `FutureStream`. This ensures that connections are made after `Peripherals` are discovered. Connection errors are handled in `onFailure`. A reconnection attempt is made on `PeripheralError.disconnected`.

### <a name="central_characteristic_discovery">Service and Characteristic Discovery</a>

After a `Peripheral` is connected its `Services` and `Characteristics` must be discovered before `Characteristic` values can be read or written to or update notifications can be received.

The `Peripheral` methods used to discover `Services` are,

```swift
// Discover all services supported by peripheral
public func discoverAllServices(timeout: TimeInterval = TimeInterval.infinity) -> Future<Void>

// Discover services with specified UUIDs
public func discoverServices(_ services: [CBUUID]?, timeout: TimeInterval = TimeInterval.infinity) -> Future<Void>
```

Both methods return a [SimpleFutures](https://github.com/troystribling/SimpleFutures) `Future<Void>` and only take a `timeout` parameter. If the timeout is exceeded the `PeripheralError.serviceDiscoveryTimeout` is thrown.

The `Service` methods used to discover `Characteristics` are,

```swift
// Discover all characteristics supported by service
public func discoverAllCharacteristics(timeout: TimeInterval = TimeInterval.infinity) -> Future<Void>

// Discover characteristics with specified UUIDs
public func discoverCharacteristics(_ characteristics: [CBUUID], timeout: TimeInterval = TimeInterval.infinity) -> Future<Void>
```

Both methods return a [SimpleFutures](https://github.com/troystribling/SimpleFutures) `Future<Void>` and only take a `timeout` parameter. If the timeout is exceeded `ServiceError.characteristicDiscoveryTimeout` is thrown.

After a `Peripheral` is connected `Services` and `Characteristics` are discovered using,

```swift
public enum AppError : Error {
    case serviceNotFound
}

let serviceUUID = CBUUID(string: TISensorTag.AccelerometerService.uuid)

let characteristicUUID = CBUUID(string: TISensorTag.AccelerometerService.Data.uuid)

let discoveryFuture = connectionFuture.flatMap { [weak peripheral] () -> Future<Void> in
    guard let peripheral = peripheral else {
        throw AppError.unlikely
    }    
    peripheral.discoverServices([serviceUUID])
}.flatMap { [peripheral weak] -> Future<Void> in
    guard let peripheral = peripheral, let service = peripheral.service.characteristics(withUUID: serviceUUID)?.first else {
        throw AppError.serviceNotFound
    }
    return service.discoverCharacteristics([dataUUID])
}

discoveryFuture.onFailure { error in
    switch error {
    case PeripheralError.disconnected:
        break
    case PeripheralError.forcedDisconnect:
        break
    case PeripheralError.connectionTimeout:
        break
    case PeripheralError.serviceDiscoveryTimeout:
        break
    case ServiceError.characteristicDiscoveryTimeout:
        break
    case AppError.serviceNotFound:
        break
    default:
        break
    }
}
```

Here the `connectionFuture` is completed after the `Peripheral` connects and `flatMap` combines it with the `Service` discovery `Future` and another `flatMap` combines with `Characteristic` discovery.

Discovery of all supported `Peripheral` `Services` and `Characteristics` could be done in a single `flatMap` using,

```swift
let discoveryFuture = connectionFuture.flatMap { [weak peripheral] -> Future<[Void]> in
    guard let peripheral = peripheral else {
        throw AppError.unlikely
    }    
    peripheral.services.map { $0.discoverAllCharacteristics() }.sequence()
}
```

Here the [SimpleFutures](https://github.com/troystribling/SimpleFutures) `Future#sequence` method is used to create a `Future` that completes when all `Characteristic` discovery tasks complete.

### <a name="central_characteristic_write">Characteristic Write</a>

After `Peripheral` `Characteristics` are discovered writing `Characteristic` values is possible. `Characteristic` methods available for writing, where each supports a value of a different type,

```swift
// Write an Data object to characteristic value
public func write(data value: Data, timeout: TimeInterval = TimeInterval.infinity, type: CBCharacteristicWriteType = .withResponse) -> Future<Void>

// Write a characteristic String Dictionary value
public func write(string stringValue: [String: String], timeout: TimeInterval = TimeInterval.infinity, type: CBCharacteristicWriteType = .withResponse) -> Future<Void>

// Write a Deserializable characteristic value
public func write<T: Deserializable>(_ value: T, timeout: TimeInterval = TimeInterval.infinity, type: CBCharacteristicWriteType = .withResponse) -> Future<Void>

// Write a RawDeserializable characteristic value
public func write<T: RawDeserializable>(_ value: T, timeout: TimeInterval = TimeInterval.infinity, type: CBCharacteristicWriteType = .withResponse) -> Future<Void>

// Write a RawArrayDeserializable characteristic value
public func write<T: RawArrayDeserializable>(_ value: T, timeout: TimeInterval = TimeInterval.infinity, type: CBCharacteristicWriteType = .withResponse) -> Future<Void>

// Write a RawPairDeserializable characteristic value
public func write<T: RawPairDeserializable>(_ value: T, timeout: TimeInterval = TimeInterval.infinity, type: CBCharacteristicWriteType = .withResponse) -> Future<Void>

// Write a RawArrayPairDeserializable characteristic value
public func write<T: RawArrayPairDeserializable>(_ value: T, timeout: TimeInterval = TimeInterval.infinity, type: CBCharacteristicWriteType = .withResponse) -> Future<Void>
```

Each of the `write` method takes a writable input of a different type. The other parameters are the same. Each returns a [SimpleFutures](https://github.com/troystribling/SimpleFutures) `Future<Void>`,

The input parameters are,

<table>
	<tr>
		<td>timeout</td>
		<td>Write timeout in seconds. The default value is infinite. If timeout is exceeded CharacteristicError.writeTimeout is shown.</td>
	</tr>
	<tr>
		<td>type</td>
		<td>Characteristic write types, see <a href="https://developer.apple.com/reference/corebluetooth/cbcharacteristicwritetype">CBCharacteristicWriteType</a> type, The default value is .WithResponse.
		</td>
	</tr>
</table>

Using the [RawDeserializable enum](/Documentation/SerializationDeserialization.md/#serde_rawdeserializable) an application can write a `Characteristic` when a connected `Peripheral` is available and `Services` and `Characteristics` are discovered,

```swift
let writeFuture = characteristic.write(Enabled.yes)
```

Here the `characteristic` is assumed to belong to a connected `Peripheral`. This could also be part of a `flatMap` chain,

```swift
public enum AppError : Error {
    case unlikely
}

let writeFuture = discoveryFuture.flatMap { [weak characteristic] () -> Future<Void> in
    guard let let characteristic = characteristic else {
        throw AppError.unlikely
    }
    return characteristic.write(Enabled.yes)
}
```

Here `discoveryFuture` is completed after `Characteristic` discovery and ``flatMap` is used to combine with `Characteristic#write`.

### <a name="central_characteristic_read">Characteristic Read</a>

After `Peripheral` `Characteristics` are discovered reading `Characteristic` values is possible. `Characteristic` provides the following method to retrieve values from connected `Peripherals`,

```swift
// Read a characteristic from a peripheral service
public func read(timeout: TimeInterval = TimeInterval.infinity) -> Future<Void>
```

The `read` method takes a single input parameter, used to specify the timeout. The default value for `timeout` is infinite. If the timeout is exceeded `CharacteristicError.readTimout` is thrown. `read` returns a [SimpleFutures](https://github.com/troystribling/SimpleFutures) `Future<Void>`. 

To retrieve the `Characteristic` value after a successful read the following methods are available. Each returns values a different type,

```swift
// Return the characteristic value as and NSData object
public var dataValue: Data?

// Return the characteristic value as a String Dictionary.
public var stringValue: [String : String]? 

// Return a Deserializable characteristic value
public func value<T: Deserializable>() -> T?

// Return a RawDeserializable characteristic value
public func value<T: RawDeserializable>() -> T?  where T.RawType: Deserializable 

// Return a RawArrayDeserializable characteristic value
public func value<T: RawArrayDeserializable>() -> T? where T.RawType: Deserializable

// Return a RawPairDeserializable characteristic value
public func value<T: RawPairDeserializable>() -> T? where T.RawType1: Deserializable, T.RawType2: Deserializable
```

Using the [RawDeserializable enum](#central_characteristic_write) an application can read a `Characteristic` after connecting to a `Peripheral` and running `Service` and `Characteristic` discovery with the following,

```swift
let readFuture = characteristic.read()
```

Here the `characteristic` is assumed to belong to a connected `Peripheral`. This could also be part of a `flatMap` chain,

```swift
let readFuture = discoveryFuture.flatMap { [weak characteristic] () -> Future<Void> in
	return characteristic.read()
}
```

Here `discoveryFuture` is completed after `Characteristic` discovery and `flatMap` is used to combine with `Characteristic#read`. 

### <a name="central_characteristic_update">Characteristic Update Notifications</a>

After `Peripheral` `Characteristics` are discovered subscribing to `Characteristic` value update notifications is possible. Several `Characteristic` methods are available,

```swift
// Subscribe to characteristic update
public func startNotifying() -> Future<Void>

// Receive characteristic value updates
public func receiveNotificationUpdates(capacity: Int = Int.max) -> FutureStream<Data)>

// Unsubscribe from characteristic updates
public func stopNotifying() -> Future<Void>

// Stop receiving characteristic value updates
public func stopNotificationUpdates()
```

The work flow for receiving notification updates is to first subscribe to the notifications using `Characteristic#startNotifying`. The application will then start receiving notifications. To process the notifications call `Characteristic#receiveNotificationUpdates` which returns a [SimpleFutures](https://github.com/troystribling/SimpleFutures) `FutureStream<Data?>` from which the updated `Characteristic` value can be obtained.

To stop processing notifications call `Characteristic#stopNotificationUpdates` and to unsubscribe to notifications call `Characteristic#stopNotifying`.

Using the [RawDeserializable enum](#central_characteristic_write) an application can receive notifications form a `Characteristic` after connecting to a `Peripheral` and running `Service` and `Characteristic` discovery with the following,

```swift
let notificationFuture = characteristics.startNotifying().flatMap { [weak characteristic] () -> FutureStream<Data?> in
    guard let let characteristic = characteristic else {
        throw AppError.unlikely
    }
    characteristic.receiveNotificationUpdates(capacity: 10)
}
```

An application can unsubscribe to `Characteristic` value notifications and stop receiving updates by using the following,

```swift
characteristic.stopNotificationUpdates()
characteristic.stopNotifying()
```

### <a name="central_retrieve_peripherals">Retrieve Peripherals</a>

Discovered `Peripherals` can be retrieved from the system cache using the following `CentralManager` methods,

```swift
// Retrieve the connected peripherals with specified service UUIDs
public func retrieveConnectedPeripherals(withServices services: [CBUUID]) -> [Peripheral]

// Retrieve peripherals with UUIDs
public func retrievePeripherals(withIdentifiers identifiers: [UUID]) -> [Peripheral]

// Retrive peripherals using framework cached peripheral UUIDs
public func retrievePeripherals() -> [Peripheral]
```

Each of these methods will repopulate the BlueCap framework cache with the retrieved peripherals overwriting any that collide.

An application would populate the framework cache from the system cache with,

```swift
let manager = CentralManager(options [CBCentralManagerOptionRestoreIdentifierKey : "us.gnos.BlueCap.documentation-manager" as NSString])

let serviceUUID = CBUUID(string: TISensorTag.AccelerometerService.uuid)

let peripherals = central.retrieveConnectedPeripherals([serviceUUID]) 
```

### <a name="central_rssi">Peripheral RSSI</a>

`Peripheral` provides the following methods to retrieve RSSI,

```swift
// read current RSSI
public func readRSSI() -> Future<Int>

// Start polling RSSI at the specified period
public func startPollingRSSI(period: Double = 10.0, capacity: Int = Int.max) -> FutureStream<Int>

// Stop polling RSSI
public func stopPollingRSSI()
```

### <a name="central_state_restoration">State Restoration</a>

CoreBluetooth provides [state restoration](https://developer.apple.com/library/content/documentation/NetworkingInternetWeb/Conceptual/CoreBluetooth_concepts/CoreBluetoothBackgroundProcessingForIOSApps/PerformingTasksWhileYourAppIsInTheBackground.html) for apps that have declared `bluetooth-central` background execution permission. Apps with this permission can be restarted with a previous state if evicted from memory while in the background. 

`CentralManager` provides the following method to process the restored application state,

```swift
public func whenStateRestored() -> Future<Void>
```

### <a name="central_errors">Errors</a>

```swift
public enum CharacteristicError : Swift.Error {
    // Thrown by read when timeout is exceeded
    case readTimeout.
    // Thrown by write when timeout is exceeded
    case writeTimeout.
    // Thrown by write if given string cannot be serialized
    case notSerializable.
    // Thrown by read if Characteristic read property is not enabled
    case readNotSupported
    // Thrown by write if Characteristic read property is not enabled.
    case writeNotSupported
    // Thrown by startNotifying if Characteristic notifiy or indicate property is not enabled.
    case notifyNotSupported
    // Characteristic needs to be added to a PeripheralManager.
    case unconfigured
}

public enum PeripheralError : Swift.Error {
    // Thrown by any method that requires a Peripheral be connected if the peripheral is not connected or is disconnected.
    case disconnected   
		// Peripheral was disconnected by application.
    case forcedDisconnect
    // Thrown by Peripheral connect when the specified timeout is exceeded.
    case connectionTimeout
    // Thrown by discoverAllServices and discoverServices if service discovery timeout is exceeded.
    case serviceDiscoveryTimeout
}

public enum CentralManagerError : Swift.Error {
    case isScanning
    // Thrown by startScanning if scan is started and CentralManager is poweredOff.
    case isPoweredOff
    // Thrown on state restoration failure.
    case restoreFailed
    // Thrown by startScanning if scan timeout is exceeded.
    case serviceScanTimeout
}

public enum ServiceError : Swift.Error {
    // Thrown by discoverAllCharcteristics and discoverCharcteristics if service discovery timeout is exceeded.
    case characteristicDiscoveryTimeout
    // Service has no associated Peripheral.
    case unconfigured
}
```

### <a name="central_stats">Statistics</a>

`Peripheral` provides the following properties to monitor performance,

<table>
	<tr>
		<td>discoveredAt: Date</td>
		<td>Date of discovery.</td>
	</tr>
	<tr>
		<td>connectedAt: Date</td>
		<td>Date of last connection.</td>
	</tr>
	<tr>
		<td>disconnectedAt: Date</td>
		<td>Date of last disconnection</td>
	</tr>
	<tr>
		<td>timeoutCount: UInt</td>
		<td>Number of connection timeouts.</td>
	</tr>
	<tr>
		<td>disconnectionCount: UInt</td>
		<td>Number of disconnections</td>
	</tr>
	<tr>
		<td>connectionCount: UInt</td>
		<td>Number of successful connections.</td>
	</tr>
	<tr>
		<td>secondsConnected: TimeInterval</td>
		<td>Seconds of current connection if Peripheral is connected  or seconds of last connection if Peripheral is disconnected.</td>
	</tr>
	<tr>
		<td>totalSecondsConnected: TimeInterval</td>
		<td>Total seconds since discovery has been connected excluding current connection if connected.</td>
	</tr>
	<tr>
		<td>cumlativeSecondsConnected: TimeInterval</td>
		<td>Total seconds since discovery has been connected including the current connection if connected.</td>
	</tr>
	<tr>
		<td>cumlativeSecondsDisconnected: TimeInterval</td>
		<td>Total seconds since discovery disconnected.</td>
	</tr>
</table>
