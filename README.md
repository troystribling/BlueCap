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
- [Example](/Examples) applications implementing Central and Peripheral roles.
- A full featured extendable Central scanner and Peripheral emulator available in the [App Store](https://itunes.apple.com/us/app/bluecap/id931219725?mt=8#).
- Thread safe.
- Comprehensive test coverage.

# Requirements

- iOS 8.0+
- Xcode 7.3

# Installation

## CocoaPods

[CocoaPods](https://cocoapods.org) is an Xcode dependency manager. It is installed with the following command,

```bash
gem install cocoapods
```

> Requires CocoaPods 1.0+

Add `BluCapKit` to your to your project `Podfile`,

```ruby
platform :ios, '8.0'
use_frameworks!

target 'Your Target Name' do
  pod 'BlueCapKit', '~> 0.2'
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
3. Under your Projects *Info* tab set the *iOS Deployment Target* to 8.0 and verify that the BlueCapKit.xcodeproj *iOS Deployment Target* is also 8.0.
4. Under the *General* tab for your project target add the top BlueCapKit.framework as an *Embedded Binary*.
5. Under the *Build Phases* tab add BlueCapKit.framework as a *Target Dependency* and under *Link Binary With Libraries* add CoreLocation.framework and CoreBluetooth.framework.

# Getting Started

With BlueCap it is possible to easily implement Central and Peripheral applications, serialize and deserialize messages exchanged with bluetooth devices and define reusable GATT profile definitions. The BlueCap asynchronous interface uses [futures](https://github.com/troystribling/SimpleFutures) instead of the usual block interface or the protocol-delegate pattern. Futures can be chained with the result of the previous passed as input to the next. This simplifies application implementation because the persistence of state between asynchronous calls is eliminated and code will not be distributed over multiple files, which is the case for protocol-delegate, or be deeply nested, which is the case for block interfaces. In this section a brief overview of how an application is constructed will be given.  [Following sections](#usage) will describe all use cases supported in some detail. [Example applications](/Examples) are also available.
 
## Central

A simple Central implementation that scans for Peripherals advertising a [TiSensorTag Accelerometer Service](/BlueCapKit/Service%20Profile%20Definitions/TISensorTagServiceProfiles.swift#L17-217) and connects on peripheral discovery will be described. 

All applications begin by calling `CentralManager#whenPowerOn` which returns a `Future<Void>` completed when the `CBCentralManager` state is set to `CBCentralManagerState.PoweredOn`.

```swift
let manager = CentralManager()
let powerOnFuture = manager.whenPowerOn()
```

To start scanning for `Peripherals` advertising the [TiSensorTag Accelerometer Service](/BlueCapKit/Service%20Profile%20Definitions/TISensorTagServiceProfiles.swift#L17-217) `powerOnFuture` will chained to `CentralManager#startScanningForServiceUUIDs` using the `Future#flatmap` combinator.

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
}.flatmap { peripheral -> FutureStream<(peripheral: Peripheral, connectionEvent: ConnectionEvent)> in
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

connectionFuture.onFailure { error in
}
```

Here on `.Timeout` and `.Disconnect` try to reconnect and on `.Giveup` terminate connection

See the [Central Example](/Examples/Central) application for a more detailed implementation that additionally discovers the peripheral and subscribes to accelerometer update notifications.

## Peripheral

A simple Peripheral application that emulates a [TiSensorTag Accelerometer Service](/BlueCapKit/Service%20Profile%20Definitions/TISensorTagServiceProfiles.swift#L17-217) with all characteristics and services will be described. It will advertise the service and respond to characteristic write request.

First the `Characteristics` and `Service` are created,

```swift
// create accelerometer service
let accelerometerService = 
    MutableService(
      profile:  ConfiguredServiceProfile<TISensorTag.AccelerometerService>())

// create accelerometer data characteristic
let accelerometerDataCharacteristic =
    MutableCharacteristic(
      profile: RawArrayCharacteristicProfile<TISensorTag.AccelerometerService.Data>())
  
// create accelerometer enabled characteristic
let accelerometerEnabledCharacteristic = 
    MutableCharacteristic(
      profile: RawCharacteristicProfile<TISensorTag.AccelerometerService.Enabled>())
  
// create accelerometer update period characteristic
let accelerometerUpdatePeriodCharacteristic = 
    MutableCharacteristic(
      profile: RawCharacteristicProfile<TISensorTag.AccelerometerService.UpdatePeriod>())

// add characteristics to service
accelerometerService.characteristics = 
    [accelerometerDataCharacteristic,
     accelerometerEnabledCharacteristic,
     accelerometerUpdatePeriodCharacteristic]
```

Next respond to write events on the `Enabled Characteristic`,

```swift
let accelerometerEnabledFuture = 
  self.accelerometerEnabledCharacteristic.startRespondingToWriteRequests()
  
accelerometerEnabledFuture.onSuccess { request in  
    if request.value.length == 1 {
        accelerometerEnabledCharacteristic.value = request.value
        accelerometerEnabledCharacteristic.respondToRequest(
		      request, withResult: CBATTError.Success)
    } else {
        accelerometerEnabledCharacteristic.respondToRequest(
	        request, withResult: CBATTError.InvalidAttributeValueLength)
	}
}
```

and respond to write events on the `Update Period Characteristic`,

```swift
let accelerometerUpdatePeriodFuture =
    accelerometerUpdatePeriodCharacteristic.startRespondingToWriteRequests()
  
accelerometerUpdatePeriodFuture.onSuccess { request in
    if request.value.length > 0 && request.value.length <= 8 {
        accelerometerUpdatePeriodCharacteristic.value = request.value
        accelerometerUpdatePeriodCharacteristic.respondToRequest(
		      request, withResult: CBATTError.Success)
	} else {
	    accelerometerUpdatePeriodCharacteristic.respondToRequest(
          request, withResult: CBATTError.InvalidAttributeValueLength)
	}
}
```

Next power on the `PeripheralManager`, add services and start advertising.

```swift
let manager = PeripheralManager()

let startAdvertiseFuture = manager.powerOn().flatmap { _ -> Future<Void> in
	manager.removeAllServices()
	manager.addService(accelerometerService)
}.flatmap { _ -> Future<Void> in
    manager.startAdvertising(TISensorTag.AccelerometerService.name, uuids: [uuid])
}

startAdvertiseFuture.onSuccess {
}

startAdvertiseFuture.onFailure {error in
}
```

## Examples

[Examples](/Examples) are available that implement both Central and Peripheral roles. The [BluCap](https://itunes.apple.com/us/app/bluecap/id931219725?mt=8#) app is also available. The example projects are constructed using either [CocoaPods](https://cocoapods.org) or [Carthage](https://github.com/Carthage/Carthage). The CocaPods projects require installing the Pod before building,

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
		<td>BlueCap provides Central, Peripheral and iBeacon Ranging Bluetooth LE functions and implementations of GATT profiles. In Central mode a scanner for Bluetooth LE peripherals is provided. In peripheral mode an emulation of any of the included GATT profiles or an iBeacon is supported. In iBeacon Ranging mode beacon regions can be configured and monitored.</td>
	</tr>
	<tr>
		<td><a href="/Examples/Central">Central</a></td>
		<td>Central implements the BLE Central role scanning for services advertising TiSensorTag Accelerometer Service. When a peripheral is discovered a connection is established, services are discovered, the accelerometer is enabled and the application subscribes to accelerometer data updates. It is also possible to change the data update period.</td>
	</tr>
	<tr>
		<td><a href="/Examples/CentralWithProfile">CentralWithProfile</a></td>
		<td>A version of Central that uses GATT Profile Definitions to create services.</td>
	</tr>
	<tr>
		<td><a href="/Examples/Peripheral">Peripheral</a></td>
		<td>Peripheral implements the BLE Peripheral role advertising a TiSensorTag Accelerometer Service. Peripheral uses the onboard accelerometer to provide data notification updates.</td>
	</tr>
	<tr>
		<td><a href="/Examples/PeripheralWithIndication">PeripheralWithIndication</a></td>
		<td>A version of Peripheral that uses indications instead of notifications.</td>
	</tr>
	<tr>
		<td><a href="Examples/PeripheralWithProfile">PeripheralWithProfile</a></td>
		<td>A version of Peripheral that uses GATT Profile Definitions to create services.</td>
	</tr>
	<tr>
		<td><a href="/Examples/Beacon">Beacon</a></td>
		<td>Peripheral emulating an iBeacon.</td>
	</tr>
</table>

# <a name="usage">Documentation</a>

BlueCap supports many features that simplify writing Bluetooth LE applications. Use cases with example implementations are described in each of the following sections.

1. [Serialization/Deserialization](/Documentation/SerializationDeserialization.md): Serialization and deserialization of device messages.
 
2. [GATT Profile Definition](/Documentation/GATTProfileDefinition.md): Define reusable GATT profiles and add profiles to the BlueCap app.

3. [CentralManager](/Documentation/CentralManager.md): The BlueCap CentralManager implementation replaces [CBCentralManagerDelegate](https://developer.apple.com/library/prerelease/ios/documentation/CoreBluetooth/Reference/CBCentralManagerDelegate_Protocol/index.html#//apple_ref/occ/intf/CBCentralManagerDelegate) and [CBPeripheralDelegate](https://developer.apple.com/library/prerelease/ios/documentation/CoreBluetooth/Reference/CBPeripheralDelegate_Protocol/index.html#//apple_ref/occ/intf/CBPeripheralDelegate) protocol implementations with a Scala Futures interface using [SimpleFutures](https://github.com/troystribling/SimpleFutures). 

4. [PeripheralManager](/Documentation/PeripheralManager.md): The BlueCap PeripheralManager implementation replaces [CBPeripheralManagerDelegate](https://developer.apple.com/library/prerelease/ios/documentation/CoreBluetooth/Reference/CBPeripheralManagerDelegate_Protocol/index.html#//apple_ref/occ/intf/CBPeripheralManagerDelegate) protocol implementations with a Scala Futures interface using [SimpleFutures](https://github.com/troystribling/SimpleFutures).

