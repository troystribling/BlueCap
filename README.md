[![BlueCap: Swifter CoreBluetooth](https://rawgit.com/troystribling/BlueCap/6de55eaf194f101d690ba7c2d0e8b20051fd8299/Assets/banner.png)](https://itunes.apple.com/us/app/bluecap/id931219725?mt=8#)

BlueCap provides a swift wrapper around CoreBluetooth and much more.

# Features

- A futures interface replacing protocol implementations, using [SimpleFutures](https://github.com/troystribling/SimpleFutures).
- Connection events for connect, disconnect and timeout.
- A framework for specification of GATT profiles.
- Characteristic profile types encapsulating serialization and deserialization.
- [Example](https://github.com/troystribling/BlueCap/tree/master/Examples) applications implementing Central and Peripheral.
- A full featured extendable Central scanner and Peripheral emulator available in the [App Store](https://itunes.apple.com/us/app/bluecap/id931219725?mt=8#).
- Comprehensive test coverage

# Requirements

- iOS 8.0+
- Xcode 6.3+

# Installation

# Usage

## Serialization/Deserialization

### `Deserializable` Protocol

### `RawDeserializable` Protocol

### `RawArrayDeserializable` Protocol

### `RawPairDeserializable` Protocol

### `RawArrayPairDeserializable` Protocol

### `Serde`

## GATT Profile Definition

### `ServiceConfigurable` Protocol

### `CharacteristicConfigurable` Protocol

### `StringDeserializable` Protocol

### `ConfiguredServiceProfile`

### `RawCharacteristicProfile`

### `RawArrayCharacteristicProfile`

### `RawPairCharacteristicProfile`

### `RawArrayPairCharacteristicProfile`

### `StringCharacteristicProfile`

### `ProfileManager`

### `Strings`

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

