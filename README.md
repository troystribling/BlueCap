[![Build Status](https://travis-ci.org/troystribling/BlueCap.svg?branch=master)](https://travis-ci.org/troystribling/BlueCap)
[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/BlueCapKit.svg)](https://img.shields.io/cocoapods/v/BlueCapKit.svg)
[![Platform](https://img.shields.io/cocoapods/p/BlueCapKit.svg?style=flat)](http://cocoadocs.org/docsets/BlueCapKit)
[![License](https://img.shields.io/cocoapods/l/BlueCapKit.svg?style=flat)](http://cocoadocs.org/docsets/BlueCapKit)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

[![BlueCap: Swifter CoreBluetooth](https://rawgit.com/troystribling/BlueCap/6de55eaf194f101d690ba7c2d0e8b20051fd8299/Assets/banner.png)](https://itunes.apple.com/us/app/bluecap/id931219725?mt=8#)

# Features

- A [futures](https://github.com/troystribling/SimpleFutures) interface replacing protocol implementations.
- Timeout for `Peripheral` connection, `Service` scan, `Service` + `Characteristic` discovery and `Characteristic` read/write.
- A DSL for specification of GATT profiles.
- Characteristic profile types encapsulating serialization and deserialization.
- [Example](/Examples) applications implementing CentralManager and PeripheralManager.
- A full featured extendable scanner and Peripheral simulator available in the [App Store](https://itunes.apple.com/us/app/bluecap/id931219725?mt=8#).
- Thread safe.
- Comprehensive test coverage.

# Requirements

- iOS 10.0+
- Xcode 9.3

# Installation

## CocoaPods

[CocoaPods](https://cocoapods.org) is an Xcode dependency manager. It is installed with the following command,

```bash
gem install cocoapods
```

> Requires CocoaPods 1.1+

Add `BluCapKit` to your to your project `Podfile`,

```ruby
platform :ios, '10.0'
use_frameworks!

target 'Your Target Name' do
  pod 'BlueCapKit', '~> 0.7'
end
```

To enable `DBUG` output add this [`post_install` hook](https://gist.github.com/troystribling/2d4630200d3dd4e3fc8b6d5e14e4732a) to your `Podfile`

## Carthage

[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager for Xcode projects.
It can be installed using [Homebrew](http://brew.sh/),

```bash
brew update
brew install carthage
```

To add `BlueCapKit` to your `Cartfile`

```ogdl
github "troystribling/BlueCap" ~> 0.7
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

This will only download `BlueCapKit`. Then follow the steps in [Manual](#manual) to add it to a project.

## <a name="manual">Manual</a>

1. Place the BlueCap somewhere in your project directory. You can either copy it or add it as a git submodule.
2. Open the BlueCap project folder and drag BlueCapKit.xcodeproj into the project navigator of your applications Xcode project.
3. Under your Projects *Info* tab set the *iOS Deployment Target* to 9.0 and verify that the BlueCapKit.xcodeproj *iOS Deployment Target* is also 9.0.
4. Under the *General* tab for your project target add the top BlueCapKit.framework as an *Embedded Binary*.
5. Under the *Build Phases* tab add BlueCapKit.framework as a *Target Dependency* and under *Link Binary With Libraries* add CoreLocation.framework and CoreBluetooth.framework.

# Getting Started

With BlueCap it is possible to easily implement `CentralManager` and `PeripheralManager` applications, serialize and deserialize messages exchanged with Bluetooth devices and define reusable GATT profile definitions. The BlueCap asynchronous interface uses [Futures](https://github.com/troystribling/SimpleFutures) instead of the usual block interface or the protocol-delegate pattern. Futures can be chained with the result of the previous passed as input to the next. This simplifies application implementation because the persistence of state between asynchronous calls is eliminated and code will not be distributed over multiple files, which is the case for protocol-delegate, or be deeply nested, which is the case for block interfaces. In this section a brief overview of how an application is constructed will be given.  [Following sections](#usage) will describe supported use cases. [Example applications](/Examples) are also available.

## CentralManager

A simple CentralManager implementation that scans for Peripherals advertising a [TiSensorTag Accelerometer Service](/BlueCapKit/Service%20Profile%20Definitions/TISensorTagServiceProfiles.swift#L16-216), connects on peripheral discovery, discovers service and characteristics and subscribes to accelerometer data updates will be described.

All applications begin by calling `CentralManager#whenStateChanges`.

```swift
let manager = CentralManager(options: [CBCentralManagerOptionRestoreIdentifierKey : "us.gnos.BlueCap.central-manager-documentation" as NSString])

let stateChangeFuture = manager.whenStateChanges()
```

To start scanning for `Peripherals` advertising the [TiSensorTag Accelerometer Service](/BlueCapKit/Service%20Profile%20Definitions/TISensorTagServiceProfiles.swift#L16-218) follow `whenStateChanges()` with `CentralManager#startScanning` and combine the two with the [SimpleFutures](https://github.com/troystribling/SimpleFutures) `FutureStream#flatMap` combinator. An application error object is also defined,

```swift
public enum AppError : Error {
    case invalidState
    case resetting
    case poweredOff
    case unknown
    case unlikely
}

let serviceUUID = CBUUID(string: TISensorTag.AccelerometerService.uuid)

let scanFuture = stateChangeFuture.flatMap { [weak manager] state -> FutureStream<Peripheral> in
    guard let manager = manager else {
        throw AppError.unlikely
    }
    switch state {
    case .poweredOn:
        return manager.startScanning(forServiceUUIDs: [serviceUUID])
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

scanFuture.onFailure { [weak manager] error in
    guard let appError = error as? AppError else {
        return
    }
    switch appError {
    case .invalidState:
	break
    case .resetting:
        manager?.reset()
    case .poweredOff:
        break
    case .unknown:
        break
    }
}

```

Here when `.poweredOn` is received the scan is started. On all other state changes the appropriate error is `thrown` and handled in the error handler.

To connect discovered peripherals the scan is followed by `Peripheral#connect` and combined with `FutureStream#flatMap`,

```swift
var peripheral: Peripheral?

let connectionFuture = scanFuture.flatMap { [weak manager] discoveredPeripheral  -> FutureStream<Void> in
    manager?.stopScanning()
    peripheral = discoveredPeripheral
    return peripheral.connect(connectionTimeout: 10.0)
}
```

Here the scan is also stopped after a peripheral with the desired service UUID is discovered.

The `Peripheral` `Services` and `Characteristics` need to be discovered and the connection errors need to be handled. `Service` and `Characteristic` discovery are performed by 'Peripheral#discoverServices' and `Service#discoverCharacteristics` and more errors are added to `AppError`.

```swift
public enum AppError : Error {
    case dataCharactertisticNotFound
    case enabledCharactertisticNotFound
    case updateCharactertisticNotFound
    case serviceNotFound
    case invalidState
    case resetting
    case poweredOff
    case unknown
    case unlikely
}

let discoveryFuture = connectionFuture.flatMap { [weak peripheral] () -> Future<Void> in
    guard let peripheral = peripheral else {
        throw AppError.unlikely
    }
    return peripheral.discoverServices([serviceUUID])
}.flatMap { [weak peripheral] () -> Future<Void> in
    guard let peripheral = peripheral, let service = peripheral.services(withUUID: serviceUUID)?.first else {
        throw AppError.serviceNotFound
    }
    return service.discoverCharacteristics([dataUUID, enabledUUID, updatePeriodUUID])
}

discoveryFuture.onFailure { [weak peripheral] error in
    switch error {
    case PeripheralError.disconnected:
        peripheral?.reconnect()
    case AppError.serviceNotFound:
        break
    default:
	break
    }
}
```

Here a reconnect attempt is made if the `Peripheral` is disconnected and the `AppError.serviceNotFound` error is handled. Finally read and subscribe to the data `Characteristic` and handle the `dataCharactertisticNotFound`.

```swift
public enum AppError : Error {
    case dataCharactertisticNotFound
    case enabledCharactertisticNotFound
    case updateCharactertisticNotFound
    case serviceNotFound
    case invalidState
    case resetting
    case poweredOff
    case unknown
}

var accelerometerDataCharacteristic: Characteristic?

let subscriptionFuture = discoveryFuture.flatMap { [weak peripheral] () -> Future<Void> in
   guard let peripheral = peripheral, let service = peripheral.services(withUUID: serviceUUID)?.first else {
        throw AppError.serviceNotFound
    }
    guard let dataCharacteristic = service.service.characteristics(withUUID: dataUUID)?.first else {
        throw AppError.dataCharactertisticNotFound
    }
    accelerometerDataCharacteristic = dataCharacteristic
    return dataCharacteristic.read(timeout: 10.0)
}.flatMap { [weak accelerometerDataCharacteristic] () -> Future<Void> in
    guard let accelerometerDataCharacteristic = accelerometerDataCharacteristic else {
        throw AppError.dataCharactertisticNotFound
    }
    return accelerometerDataCharacteristic.startNotifying()
}.flatMap { [weak accelerometerDataCharacteristic] () -> FutureStream<Data?> in
    guard let accelerometerDataCharacteristic = accelerometerDataCharacteristic else {
        throw AppError.dataCharactertisticNotFound
    }
    return accelerometerDataCharacteristic.receiveNotificationUpdates(capacity: 10)
}

dataUpdateFuture.onFailure { [weak peripheral] error in
    switch error {
    case PeripheralError.disconnected:
        peripheral?.reconnect()
    case AppError.serviceNotFound:
        break
    case AppError.dataCharactertisticNotFound:
	break
    default:
	break
    }
}
```

These examples can be written as a single `flatMap` chain as shown in the  [CentralManager Example](/Examples/CentralManager).

## PeripheralManager

A simple `PeripheralManager` application that emulates a [TiSensorTag Accelerometer Service](/BlueCapKit/Service%20Profile%20Definitions/TISensorTagServiceProfiles.swift#L16-218) supporting all `Characteristics` will be described. It will advertise the service and respond to characteristic write requests on the writable `Characteristics`.

First the `Characteristics` and `Service` are created and the `Characteristics` are then added to `Service`

```swift
// create accelerometer service
let accelerometerService = MutableService(uuid: TISensorTag.AccelerometerService.uuid)

// create accelerometer data characteristic
let accelerometerDataCharacteristic = MutableCharacteristic(profile: RawArrayCharacteristicProfile<TISensorTag.AccelerometerService.Data>())

// create accelerometer enabled characteristic
let accelerometerEnabledCharacteristic = MutableCharacteristic(profile: RawCharacteristicProfile<TISensorTag.AccelerometerService.Enabled>())

// create accelerometer update period characteristic
let accelerometerUpdatePeriodCharacteristic = MutableCharacteristic(profile: RawCharacteristicProfile<TISensorTag.AccelerometerService.UpdatePeriod>())

// add characteristics to service
accelerometerService.characteristics = [accelerometerDataCharacteristic, accelerometerEnabledCharacteristic, accelerometerUpdatePeriodCharacteristic]
```

Next create the `PeripheralManager` add the `Service` and start advertising.

```swift
enum AppError: Error {
    case invalidState
    case resetting
    case poweredOff
    case unsupported
    case unlikely
}

let manager = PeripheralManager(options: [CBPeripheralManagerOptionRestoreIdentifierKey : "us.gnos.BlueCap.peripheral-manager-documentation" as NSString])

let startAdvertiseFuture = manager.whenStateChanges().flatMap { [weak manager] state -> Future<Void> in
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
}.flatMap { [weak manager] _ -> Future<Void> in
    guard let manager = manager else {
        throw AppError.unlikely
    }
    manager.startAdvertising(TISensorTag.AccelerometerService.name, uuids:[CBUUID(string: TISensorTag.AccelerometerService.uuid)])
}

startAdvertiseFuture.onFailure { [weak manager] error in
    switch error {
    case AppError.poweredOff:
        manager?.reset()            
    case AppError.resetting:
        manager?.reset()
    default:
	break
    }
    manager?.stopAdvertising()
}
```

Now respond to write events on `accelerometerEnabledFuture` and `accelerometerUpdatePeriodFuture`.

```swift
// respond to Update Period write requests
let accelerometerUpdatePeriodFuture = startAdvertiseFuture.flatMap {
    accelerometerUpdatePeriodCharacteristic.startRespondingToWriteRequests()
}

accelerometerUpdatePeriodFuture.onSuccess {  [weak accelerometerUpdatePeriodCharacteristic] (request, _) in
    guard let accelerometerUpdatePeriodCharacteristic = accelerometerUpdatePeriodCharacteristic else {
        throw AppError.unlikely
    }
    guard let value = request.value, value.count > 0 && value.count <= 8 else {
        return
    }
    accelerometerUpdatePeriodCharacteristic.value = value
    accelerometerUpdatePeriodCharacteristic.respondToRequest(request, withResult:CBATTError.success)
}

// respond to Enabled write requests
let accelerometerEnabledFuture = startAdvertiseFuture.flatMap {
    accelerometerEnabledCharacteristic.startRespondingToWriteRequests(capacity: 2)
}

accelerometerEnabledFuture.onSuccess { [weak accelerometerUpdatePeriodCharacteristic] (request, _) in
    guard let accelerometerEnabledCharacteristic = accelerometerEnabledCharacteristic else {
        throw AppError.unlikely
    }
    guard let value = request.value, value.count == 1 else {
        return
    }
    accelerometerEnabledCharacteristic.value = request.value
    accelerometerEnabledCharacteristic.respondToRequest(request, withResult:CBATTError.success)
}
```

See [PeripheralManager Example](/Examples/PeripheralManager) for details.

## Test Cases

[Test Cases](/Tests) are available. To run type,

```bash
pod install
```

and run from test tab in generated `workspace`.

## Examples

[Examples](/Examples) are available that implement both CentralManager and PeripheralManager. The [BluCap](https://itunes.apple.com/us/app/bluecap/id931219725?mt=8#) app is also available. The example projects are constructed using either [CocoaPods](https://cocoapods.org) or [Carthage](https://github.com/Carthage/Carthage). The CocaPods projects require installing the Pod before building,

```bash
pod install
```

and Carthage projects require,

```bash
carthage update
```

<table>
	<tr>
		<td><a href="/Examples/BlueCap">BlueCap</a></td>
		<td>BlueCap provides CentralManager, PeripheralManager and iBeacon Ranging with implementations of GATT profiles. In CentralManager mode a scanner for Bluetooth LE peripherals is provided. In PeripheralManager mode an emulation of any of the included GATT profiles or an iBeacon is supported. In iBeacon Ranging mode beacon regions can be configured and monitored.</td>
	</tr>
	<tr>
		<td><a href="/Examples/CentralManager">CentralManager</a></td>
		<td>CentralManager implements a BLE CentralManager scanning for services advertising the TiSensorTag Accelerometer Service. When a Peripheral is discovered a connection is established, services are discovered, the accelerometer is enabled and the application subscribes to accelerometer data updates. It is also possible to change the data update period.</td>
	</tr>
	<tr>
		<td><a href="/Examples/CentralManagerWithProfile">CentralManagerWithProfile</a></td>
		<td>A version of CentralManager that uses GATT Profile Definitions to create services.</td>
	</tr>
	<tr>
		<td><a href="/Examples/PeripheralManager">PeripheralManager</a></td>
		<td>PeripheralManager implements a BLE PeripheralManager advertising a TiSensorTag Accelerometer Service. PeripheralManager uses the onboard accelerometer to provide data updates.</td>
	</tr>
	<tr>
		<td><a href="Examples/PeripheralManagerWithProfile">PeripheralManagerWithProfile</a></td>
		<td>A version of Peripheral that uses GATT Profile Definitions to create services.</td>
	</tr>
	<tr>
		<td><a href="/Examples/Beacon">Beacon</a></td>
		<td>Peripheral emulating an iBeacon.</td>
	</tr>
		<tr>
		<td><a href="/Examples/Beacons">Beacons</a></td>
		<td>iBeacon ranging.</td>
	</tr>


</table>

# <a name="usage">Documentation</a>

BlueCap supports many features that simplify writing Bluetooth LE applications. Use cases with example implementations are described in each of the following sections.

1. [CentralManager](/Documentation/CentralManager.md): The BlueCap CentralManager implementation replaces [CBCentralManagerDelegate](https://developer.apple.com/library/prerelease/ios/documentation/CoreBluetooth/Reference/CBCentralManagerDelegate_Protocol/index.html#//apple_ref/occ/intf/CBCentralManagerDelegate) and [CBPeripheralDelegate](https://developer.apple.com/library/prerelease/ios/documentation/CoreBluetooth/Reference/CBPeripheralDelegate_Protocol/index.html#//apple_ref/occ/intf/CBPeripheralDelegate) protocol implementations with a Scala Futures interface using [SimpleFutures](https://github.com/troystribling/SimpleFutures).

2. [PeripheralManager](/Documentation/PeripheralManager.md): The BlueCap PeripheralManager implementation replaces [CBPeripheralManagerDelegate](https://developer.apple.com/library/prerelease/ios/documentation/CoreBluetooth/Reference/CBPeripheralManagerDelegate_Protocol/index.html#//apple_ref/occ/intf/CBPeripheralManagerDelegate) protocol implementations with a Scala Futures interface using [SimpleFutures](https://github.com/troystribling/SimpleFutures).

3. [Serialization/Deserialization](/Documentation/SerializationDeserialization.md): Serialization and deserialization of device messages.

4. [GATT Profile Definition](/Documentation/GATTProfileDefinition.md): Define reusable GATT profiles and add profiles to the BlueCap app.
