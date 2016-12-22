[![Build Status](https://travis-ci.org/troystribling/BlueCap.svg?branch=master)](https://travis-ci.org/troystribling/BlueCap)
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
- [Example](/Examples) applications implementing Central and Peripheral roles.
- A full featured extendable Central scanner and Peripheral emulator available in the [App Store](https://itunes.apple.com/us/app/bluecap/id931219725?mt=8#).
- Thread safe.
- Comprehensive test coverage.

# Requirements

- iOS 9.0+
- Xcode 8.2

# Installation

## CocoaPods

[CocoaPods](https://cocoapods.org) is an Xcode dependency manager. It is installed with the following command,

```bash
gem install cocoapods
```

> Requires CocoaPods 1.1+

Add `BluCapKit` to your to your project `Podfile`,

```ruby
platform :ios, '9.0'
use_frameworks!

target 'Your Target Name' do
  pod 'BlueCapKit', '~> 0.3'
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

All applications begin by calling `CentralManager#whenStateChanges` which returns a `Future<Void>` completed when the `CBCentralManager` state is set to `CBCentralManagerState.PoweredOn`.

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
}

let serviceUUID = CBUUID(string: TISensorTag.AccelerometerService.uuid)
    
let scanFuture = stateChangeFuture.flatMap { state -> FutureStream<Peripheral> in
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

scanFuture.onFailure { error in
    guard let appError = error as? AppError else {
        return
    }
    switch appError {
    case .invalidState:
	      break
    case .resetting:
        manager.reset()
    case .poweredOff:
        break
    case .unknown:
        break
    }
}

```

Here when `.poweredOn` is received the scan is started. On all other state changes the appropriate error is `thrown` and handled in the error handler.

To connect discovered peripheral the scan is followed by `Peripheral#connect` and combined with `FutureStream#flatMap`,

```swift
let connectionFuture = scanFuture.flatMap { peripheral -> FutureStream<Peripheral> in
    manager.stopScanning()
    return peripheral.connect(timeoutRetries: 5, disconnectRetries:5, connectionTimeout: 10.0)
}
```

Here the scan is also stopped after a peripheral with the desire service UUID is discovered.

The `Peripheral` `Services` and `Characteristics` need to be discovered and the connection events need to be handled. `Service` and `Characteristic` discovery are performed by 'Peripheral#discoverServices' and `Service#discoverCharacteristics` and more errors are added to `AppError`.

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

var peripheral: Peripheral?

let discoveryFuture = connectionFuture.flatMap { peripheral -> Future<Peripheral> in
    return peripheral.discoverServices([serviceUUID])
}.flatMap { discoveredPeripheral -> Future<Service> in
    guard let service = peripheral.service(serviceUUID) else {
        throw AppError.serviceNotFound
    }
    peripheral = discoveredPeripheral
    return service.discover(: [dataUUID, enabledUUID, updatePeriodUUID])
}

discoveryFuture.onFailure { error in
    guard let appError = error as? AppError else {
        return
    }
    switch appError {
    case .serviceNotFound:
        break
    }
}
```

Finally read and subscribe to the data `Characteristic` and handle the `dataCharactertisticNotFound`.

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

let subscriptionFuture = discoveryFuture.flatMap { service -> Future<Characteristic> in
    guard let dataCharacteristic = service.characteristic(dataUUID) else {
        throw AppError.dataCharactertisticNotFound
    }
    self.accelerometerDataCharacteristic = dataCharacteristic
    return self.accelerometerEnabledCharacteristic.read(timeout: 10.0)
}.flatMap { _ -> Future<Characteristic> in
    guard let accelerometerDataCharacteristic = self.accelerometerDataCharacteristic else {
        throw AppError.dataCharactertisticNotFound
    }
    return accelerometerDataCharacteristic.startNotifying()
}.flatMap { characteristic -> FutureStream<(characteristic: Characteristic, data: Data?)> in
    return characteristic.receiveNotificationUpdates(capacity: 10)
}

dataUpdateFuture.onFailure { [unowned self] error in
    guard let appError = error as? AppError else {
        return
    }
    switch appError {
    case .dataCharactertisticNotFound:
       break
    default:
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
}

let manager = PeripheralManager(options: [CBPeripheralManagerOptionRestoreIdentifierKey : "us.gnos.BlueCap.peripheral-manager-documentation" as NSString])
    
let startAdvertiseFuture = manager.whenStateChanges().flatMap { state -> Future<Void> in
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
}.flatMap { _ -> Future<Void> in 
    manager.startAdvertising(TISensorTag.AccelerometerService.name, uuids:[CBUUID(string: TISensorTag.AccelerometerService.uuid)])
}

startAdvertiseFuture.onFailure { error in
    switch error {
    case AppError.poweredOff:
        manager.reset()            
    case AppError.resetting:
        manager.reset()
    default:
	      break
    }
    manager.stopAdvertising()
}
```

Now respond to write events on `accelerometerEnabledFuture` and `accelerometerUpdatePeriodFuture`.

```swift
// respond to Update Period write requests
let accelerometerUpdatePeriodFuture = startAdvertiseFuture.flatMap {
    accelerometerUpdatePeriodCharacteristic.startRespondingToWriteRequests()
}

accelerometerUpdatePeriodFuture.onSuccess {  (request, _) in
    guard let value = request.value, value.count > 0 && value.count <= 8 else {
        return
    }
    self.accelerometerUpdatePeriodCharacteristic.value = value
    self.accelerometerUpdatePeriodCharacteristic.respondToRequest(request, withResult:CBATTError.success)
}

// respond to Enabled write requests
let accelerometerEnabledFuture = startAdvertiseFuture.flatMap {
    accelerometerEnabledCharacteristic.startRespondingToWriteRequests(capacity: 2)
}

accelerometerEnabledFuture.onSuccess { (request, _) in
    guard let value = request.value, value.count == 1 else {
        return
    }
    self.accelerometerEnabledCharacteristic.value = request.value
    self.accelerometerEnabledCharacteristic.respondToRequest(request, withResult:CBATTError.success)
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

</table>

# <a name="usage">Documentation</a>

BlueCap supports many features that simplify writing Bluetooth LE applications. Use cases with example implementations are described in each of the following sections.

1. [CentralManager](/Documentation/CentralManager.md): The BlueCap CentralManager implementation replaces [CBCentralManagerDelegate](https://developer.apple.com/library/prerelease/ios/documentation/CoreBluetooth/Reference/CBCentralManagerDelegate_Protocol/index.html#//apple_ref/occ/intf/CBCentralManagerDelegate) and [CBPeripheralDelegate](https://developer.apple.com/library/prerelease/ios/documentation/CoreBluetooth/Reference/CBPeripheralDelegate_Protocol/index.html#//apple_ref/occ/intf/CBPeripheralDelegate) protocol implementations with a Scala Futures interface using [SimpleFutures](https://github.com/troystribling/SimpleFutures). 

2. [PeripheralManager](/Documentation/PeripheralManager.md): The BlueCap PeripheralManager implementation replaces [CBPeripheralManagerDelegate](https://developer.apple.com/library/prerelease/ios/documentation/CoreBluetooth/Reference/CBPeripheralManagerDelegate_Protocol/index.html#//apple_ref/occ/intf/CBPeripheralManagerDelegate) protocol implementations with a Scala Futures interface using [SimpleFutures](https://github.com/troystribling/SimpleFutures).

3. [Serialization/Deserialization](/Documentation/SerializationDeserialization.md): Serialization and deserialization of device messages.
 
4. [GATT Profile Definition](/Documentation/GATTProfileDefinition.md): Define reusable GATT profiles and add profiles to the BlueCap app.


