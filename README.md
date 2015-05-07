[![BlueCap: Swifter CoreBluetooth](https://rawgit.com/troystribling/BlueCap/6de55eaf194f101d690ba7c2d0e8b20051fd8299/Assets/banner.png)](https://itunes.apple.com/us/app/bluecap/id931219725?mt=8#)

BlueCap provides a swift wrapper around CoreBluetooth and much more.

# Features

- A [futures](https://github.com/troystribling/SimpleFutures) interface replacing protocol implementations.
- Connection events for connect, disconnect and timeout.
- Service scan timeout.
- A framework for specification of GATT profiles.
- Characteristic profile types encapsulating serialization and deserialization.
- [Example](https://github.com/troystribling/BlueCap/tree/master/Examples) applications implementing Central and Peripheral.
- A full featured extendable Central scanner and Peripheral emulator available in the [App Store](https://itunes.apple.com/us/app/bluecap/id931219725?mt=8#).
- Comprehensive test coverage

# Requirements

- iOS 8.0+
- Xcode 6.3+

# Installation

1. Place the BlueCap somewhere in your project directory. You can either copy it or add it as a git submodule.
2. Open the BluCap project folder and drag BlueCapKit.xcodeproj into the project navigator of your applications Xcode project.
3. Under your Projects Info tab set the iOS Deployment Target to 8.0 and that the BlueCapKit.xcodeproj iOS Deployment Target is also 8.0.
4. Under the General tab for your project target add the top BlueCapKit.framework as an Embedded Binary.
5. Under the Build Phases tab add BlueCapKit.framework as a Target Dependency and under Link Binary With Libraries add CoreLocation.framework and CoreBluetooth.framework.
6. To enable debug log output select your project target and the Build Settings tab. Under Other Swift Flags under Debug add -D DEBUG.

# Usage

With BlueCap you can serialize and deserialize messages exchanged with bluetooth devices, define reusable GATT profile definitions and easily implement Central and Peripheral applications. The following sections will address each of these items in some detail. [Simple example applications](https://github.com/troystribling/BlueCap/tree/master/Examples) are also available.
 
## Serialization/Deserialization

### Deserializable Protocol

### RawDeserializable Protocol

### RawArrayDeserializable Protocol

### RawPairDeserializable Protocol

### RawArrayPairDeserializable Protocol

### Serde

## GATT Profile Definition

### ServiceConfigurable Protocol

### CharacteristicConfigurable Protocol

### StringDeserializable Protocol

### ConfiguredServiceProfile

### RawCharacteristicProfile

### RawArrayCharacteristicProfile

### RawPairCharacteristicProfile

### RawArrayPairCharacteristicProfile

### StringCharacteristicProfile

### ProfileManager

### Strings

### Add Profile to BlueCap App

## Central

### PowerOn/PowerOff

### Service Scanning

### Peripheral Connection

### Service and Characteristic Discovery

### Characteristic Read/Write

### Characteristic Update Notifications

## Peripheral

### PowerOn/PowerOff

### Advertising

### Read Characteristic

### Set Characteristic Value

### Updating Characteristic Value

### iBeacon Emulation

