//
//  Peripheral.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/8/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import Foundation
import CoreBluetooth

enum PeripheralConnectionError {
    case None, Timeout, Unknown
}

public enum ConnectionEvent {
    case Connect, Timeout, Disconnect, ForceDisconnect, Failed, GiveUp
}

public protocol CBPeripheralInjectable {
    var name : String?                      {get}
    var state : CBPeripheralState           {get}
    var identifier : NSUUID                 {get}
    var delegate : CBPeripheralDelegate?    {get set}
    var services : [CBService]?             {get}
    
    func discoverServices(services:[CBUUID]?)
    func discoverCharacteristics(characteristics:[CBUUID]?, forService:CBService)
    func setNotifyValue(state:Bool, forCharacteristic:CBCharacteristic)
    func readValueForCharacteristic(characteristic:CBCharacteristic)
    func writeValue(data:NSData, forCharacteristic:CBCharacteristic, type:CBCharacteristicWriteType)
}

extension CBPeripheral : CBPeripheralInjectable {}

public struct PeripheralAdvertisements {
    
    let advertisements : [String: AnyObject]
    
    public var localName : String? {
        if let localname = self.advertisements[CBAdvertisementDataLocalNameKey] {
            return localname as? String
        } else {
            return nil
        }
    }
    
    public var manufactuereData : NSData? {
        if let mfgData = self.advertisements[CBAdvertisementDataManufacturerDataKey] {
            return mfgData as? NSData
        } else {
            return nil;
        }
    }
    
    public var txPower : NSNumber? {
        if let txPower = self.advertisements[CBAdvertisementDataTxPowerLevelKey] {
            return txPower as? NSNumber
        } else {
            return nil
        }
    }
    
    public var isConnectable : NSNumber? {
        if let isConnectable = self.advertisements[CBAdvertisementDataIsConnectable] {
            return isConnectable as? NSNumber
        } else {
            return nil
        }
    }
    
    public var serviceUUIDs : [CBUUID]? {
        if let serviceUUIDs = self.advertisements[CBAdvertisementDataServiceUUIDsKey] {
            return serviceUUIDs as? [CBUUID]
        } else {
            return nil
        }
    }
    
    public var serviceData : [CBUUID:NSData]? {
        if let serviceData = self.advertisements[CBAdvertisementDataServiceDataKey] {
            return serviceData as? [CBUUID:NSData]
        } else {
            return nil
        }
    }
    
    public var overflowServiceUUIDs : [CBUUID]? {
        if let serviceUUIDs = self.advertisements[CBAdvertisementDataOverflowServiceUUIDsKey] {
            return serviceUUIDs as? [CBUUID]
        } else {
            return nil
        }
    }
    
    public var solicitedServiceUUIDs : [CBUUID]? {
        if let serviceUUIDs = self.advertisements[CBAdvertisementDataSolicitedServiceUUIDsKey] {
            return serviceUUIDs as? [CBUUID]
        } else {
            return nil
        }
    }    
}

public class Peripheral : NSObject, CBPeripheralDelegate {
    
    private var servicesDiscoveredPromise : Promise<Peripheral>
    private var readRSSIPromise : Promise<Int>

    private var connectionPromise : StreamPromise<(Peripheral, ConnectionEvent)>?

    private var timeoutCount : UInt         = 0
    private var disconnectCount : UInt      = 0
    
    private var connectionSequence          = 0
    private var currentError                = PeripheralConnectionError.None
    private var forcedDisconnect            = false

    private let timeoutQueue : Queue
    
    private let _discoveredAt               = NSDate()
    private var _connectedAt : NSDate?
    private var _disconnectedAt : NSDate?
    
    private var discoveredServices          = [CBUUID:Service]()
    private var discoveredCharacteristics   = [CBUUID:Characteristic]()

    internal var connectionTimeout          = 10.0
    internal var timeoutRetries : UInt?
    internal var disconnectRetries : UInt?
    internal weak var centralManager : CentralManager?
    
    public let cbPeripheral : CBPeripheralInjectable
    public let advertisements : PeripheralAdvertisements
    public let rssi : Int

    public var discoveredAt : NSDate {
        return self._discoveredAt
    }
    
    public var connectedAt : NSDate? {
        return self._connectedAt
    }
    
    public var disconnectedAt : NSDate? {
        return self._disconnectedAt
    }
    
    public var name : String {
        if let name = self.cbPeripheral.name {
            return name
        } else {
            return "Unknown"
        }
    }

    public var state : CBPeripheralState {
        return self.cbPeripheral.state
    }
    
    public var services : [Service] {
        return Array(self.discoveredServices.values)
    }
    
    public var identifier : NSUUID {
        return self.cbPeripheral.identifier
    }
    
    public init(cbPeripheral: CBPeripheralInjectable, centralManager: CentralManager, advertisements: [String:AnyObject], rssi: Int) {
        self.cbPeripheral = cbPeripheral
        self.advertisements = PeripheralAdvertisements(advertisements:advertisements)
        self.centralManager = centralManager
        self.rssi = rssi
        self.timeoutQueue = Queue("us.gnos.peripheral-timeout-\(cbPeripheral.identifier.UUIDString)")
        self.servicesDiscoveredPromise = Promise<Peripheral>()
        self.readRSSIPromise = Promise<Int>()
        super.init()
        self.cbPeripheral.delegate = self
    }
    
    public func service(uuid:CBUUID) -> Service? {
        return self.discoveredServices[uuid]
    }
    
    func readRSSI() -> Future<Int> {
        self.centralManager?.centralQueue.sync {
            self.readRSSIPromise = Promise<Int>()
        }
        return self.readRSSIPromise.future
    }
    
    public func reconnect() {
        if let centralManager = self.centralManager where self.state == .Disconnected {
            Logger.debug("reconnect peripheral \(self.name)")
            centralManager.connectPeripheral(self)
            self.forcedDisconnect = false
            self.connectionSequence += 1
            self.timeoutConnection(self.connectionSequence)
        }
    }
     
    public func connect(capacity: Int? = nil, timeoutRetries: UInt? = nil, disconnectRetries: UInt? = nil, connectionTimeout: Double = 10.0) -> FutureStream<(Peripheral, ConnectionEvent)> {
        self.connectionPromise = StreamPromise<(Peripheral, ConnectionEvent)>(capacity:capacity)
        self.timeoutRetries = timeoutRetries
        self.disconnectRetries = disconnectRetries
        self.connectionTimeout = connectionTimeout
        Logger.debug("connect peripheral \(self.name)")
        self.reconnect()
        return self.connectionPromise!.future
    }
    
    public func disconnect() {
        if let central = self.centralManager {
            central.discoveredPeripherals.removeValueForKey(self.cbPeripheral.identifier)
            self.forcedDisconnect = true
            if self.state == .Connected {
                Logger.debug("disconnect peripheral \(self.name)")
                central.cancelPeripheralConnection(self)
            } else {
                self.didDisconnectPeripheral()
            }
        }
    }
    
    public func terminate() {
        self.disconnect()
    }

    // service discovery
    public func discoverServices(services: [CBUUID]?) -> Future<Peripheral> {
        Logger.debug(" \(self.name)")
        self.centralManager?.centralQueue.sync {
            self.servicesDiscoveredPromise = Promise<Peripheral>()
            self.discoverIfConnected(services)
        }
        return self.servicesDiscoveredPromise.future
    }
    
    public func discoverAllServices() -> Future<Peripheral> {
        Logger.debug("peripheral name \(self.name)")
        return self.discoverServices(nil)
    }

    public func discoverAllPeripheralServices() -> Future<Peripheral> {
        return self.discoverPeripheralServices(nil)
    }

    public func discoverPeripheralServices(services: [CBUUID]?) -> Future<Peripheral> {
        let peripheralDiscoveredPromise = Promise<Peripheral>()
        Logger.debug("peripheral name \(self.name)")
        let servicesDiscoveredFuture = self.discoverServices(services)
        servicesDiscoveredFuture.onSuccess {_ in
            if self.services.count > 1 {
                self.discoverService(self.services[0], tail:Array(self.services[1..<self.services.count]), promise: peripheralDiscoveredPromise)
            } else {
                if self.services.count > 0 {
                    let discoveryFuture = self.services[0].discoverAllCharacteristics()
                    discoveryFuture.onSuccess {_ in
                        peripheralDiscoveredPromise.success(self)
                    }
                    discoveryFuture.onFailure {error in
                        peripheralDiscoveredPromise.failure(error)
                    }
                } else {
                    peripheralDiscoveredPromise.failure(BCError.peripheralNoServices)
                }
            }
        }
        servicesDiscoveredFuture.onFailure {(error) in
            peripheralDiscoveredPromise.failure(error)
        }
        return peripheralDiscoveredPromise.future
    }
    
    public func discoverService(head: Service, tail: [Service], promise: Promise<Peripheral>) {
        let discoveryFuture = head.discoverAllCharacteristics()
        Logger.debug("service name \(head.name) count \(tail.count + 1)")
        if tail.count > 0 {
            discoveryFuture.onSuccess {_ in
                self.discoverService(tail[0], tail:Array(tail[1..<tail.count]), promise:promise)
            }
        } else {
            discoveryFuture.onSuccess {_ in
                promise.success(self)
            }
        }
        discoveryFuture.onFailure {error in
            promise.failure(error)
        }
    }

    // CBPeripheralDelegate
    // peripheral
    public func peripheralDidUpdateName(_:CBPeripheral) {
        Logger.debug()
    }
    
    public func peripheral(_: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        Logger.debug()
    }
    
    public func peripheral(_: CBPeripheral, didReadRSSI RSSI: NSNumber, error: NSError?) {
        self.didReadRSSI(RSSI, error:error)
    }
    
    // services
    public func peripheral(_: CBPeripheral, didDiscoverServices error: NSError?) {
        if let services = self.cbPeripheral.services {
            self.didDiscoverServices(services, error:error)
        }
    }
    
    public func peripheral(_: CBPeripheral, didDiscoverIncludedServicesForService service: CBService, error: NSError?) {
        Logger.debug("peripheral name \(self.name)")
    }
    
    // characteristics
    public func peripheral(_: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        guard let characteristics = service.characteristics else {
            return
        }
        self.didDiscoverCharacteristicsForService(service, characteristics: characteristics, error: error)
    }

    public func peripheral(_: CBPeripheral, didUpdateNotificationStateForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        self.didUpdateNotificationStateForCharacteristic(characteristic, error:error)
    }

    public func peripheral(_: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        self.didUpdateValueForCharacteristic(characteristic, error:error)
    }

    public func peripheral(_: CBPeripheral, didWriteValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        self.didWriteValueForCharacteristic(characteristic, error:error)
    }

    public func peripheral(_: CBPeripheral, didDiscoverDescriptorsForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        Logger.debug()
    }
    
    public func peripheral(_: CBPeripheral, didUpdateValueForDescriptor descriptor: CBDescriptor, error: NSError?) {
        Logger.debug()
    }
    
    public func peripheral(_: CBPeripheral, didWriteValueForDescriptor descriptor: CBDescriptor, error: NSError?) {
        Logger.debug()
    }
    
    public func didDiscoverCharacteristicsForService(service: CBService, characteristics: [CBCharacteristic], error: NSError?) {
        Logger.debug("peripheral name \(self.name)")
        if let bcService = self.discoveredServices[service.UUID] {
            bcService.didDiscoverCharacteristics(characteristics, error:error)
            if error == nil {
                for cbCharacteristic in characteristics {
                    self.discoveredCharacteristics[cbCharacteristic.UUID] = bcService.discoveredCharacteristics[cbCharacteristic.UUID]
                }
            }
        }
    }
    
    public func didDiscoverServices(discoveredServices: [CBService], error: NSError?) {
        Logger.debug("peripheral name \(self.name)")
        self.clearAll()
        if let error = error {
            self.servicesDiscoveredPromise.failure(error)
        } else {
            for service in discoveredServices {
                let bcService = Service(cbService:service, peripheral:self)
                self.discoveredServices[bcService.uuid] = bcService
                Logger.debug("uuid=\(bcService.uuid.UUIDString), name=\(bcService.name)")
            }
            self.servicesDiscoveredPromise.success(self)
        }
    }
    
    public func didUpdateNotificationStateForCharacteristic(characteristic: CBCharacteristic, error: NSError?) {
        Logger.debug()
        if let bcCharacteristic = self.discoveredCharacteristics[characteristic.UUID] {
            Logger.debug("uuid=\(bcCharacteristic.uuid.UUIDString), name=\(bcCharacteristic.name)")
            bcCharacteristic.didUpdateNotificationState(error)
        }
    }
    
    public func didUpdateValueForCharacteristic(characteristic: CBCharacteristic, error: NSError?) {
        Logger.debug()
        if let bcCharacteristic = self.discoveredCharacteristics[characteristic.UUID] {
            Logger.debug("uuid=\(bcCharacteristic.uuid.UUIDString), name=\(bcCharacteristic.name)")
            bcCharacteristic.didUpdate(error)
        }
    }
    
    public func didWriteValueForCharacteristic(characteristic: CBCharacteristic, error: NSError?) {
        Logger.debug()
        if let bcCharacteristic = self.discoveredCharacteristics[characteristic.UUID] {
            Logger.debug("uuid=\(bcCharacteristic.uuid.UUIDString), name=\(bcCharacteristic.name)")
            bcCharacteristic.didWrite(error)
        }
    }
    
    public func didDisconnectPeripheral() {
        Logger.debug()
        self._disconnectedAt = NSDate()
        if (self.forcedDisconnect) {
            self.forcedDisconnect = false
            Logger.debug("forced disconnect")
            self.connectionPromise?.success((self, ConnectionEvent.ForceDisconnect))
        } else {
            switch(self.currentError) {
            case .None:
                Logger.debug("no errors disconnecting")
                self.callDidDisconnect()
            case .Timeout:
                Logger.debug("timeout reconnecting")
                self.callDidTimeout()
            case .Unknown:
                Logger.debug("unknown error")
            }
        }
    }

    public func didConnectPeripheral() {
        Logger.debug()
        self._connectedAt = NSDate()
        self.connectionPromise?.success((self, ConnectionEvent.Connect))
    }
    
    public func didFailToConnectPeripheral(error: NSError?) {
        if let error = error {
            Logger.debug("connection failed for \(self.name) with error:'\(error.localizedDescription)'")
            self.currentError = .Unknown
            self.connectionPromise?.failure(error)
            if let disconnectRetries = self.disconnectRetries {
                if self.disconnectCount < disconnectRetries {
                    self.disconnectCount += 1
                } else {
                    self.disconnectCount = 0
                    self.connectionPromise?.success((self, ConnectionEvent.GiveUp))
                }
            }
        } else {
            Logger.debug("connection success")
            self.connectionPromise?.success((self, ConnectionEvent.Failed))
        }
    }
    
    internal func callDidTimeout() {
        Logger.debug()
        if let timeoutRetries = self.timeoutRetries {
            if self.timeoutCount < timeoutRetries {
                self.connectionPromise?.success((self, ConnectionEvent.Timeout))
                self.timeoutCount += 1
            } else {
                self.timeoutCount = 0
                self.connectionPromise?.success((self, ConnectionEvent.GiveUp))
            }
        } else {
            self.connectionPromise?.success((self, ConnectionEvent.Timeout))
        }
    }
    
    internal func callDidDisconnect() {
        Logger.debug()
        if let disconnectRetries = self.disconnectRetries {
            if self.disconnectCount < disconnectRetries {
                self.disconnectCount += 1
                self.connectionPromise?.success((self, ConnectionEvent.Disconnect))
            } else {
                self.disconnectCount = 0
                self.connectionPromise?.success((self, ConnectionEvent.GiveUp))
            }
        } else {
            self.connectionPromise?.success((self, ConnectionEvent.Disconnect))
        }
    }
    
    internal func setNotifyValue(state: Bool, forCharacteristic characteristic: Characteristic) {
        self.cbPeripheral.setNotifyValue(state, forCharacteristic:characteristic.cbCharacteristic)
    }
    
    internal func readValueForCharacteristic(characteristic: Characteristic) {
        self.cbPeripheral.readValueForCharacteristic(characteristic.cbCharacteristic)
    }
    
    internal func writeValue(value: NSData, forCharacteristic characteristic: Characteristic, type: CBCharacteristicWriteType = .WithResponse) {
            self.cbPeripheral.writeValue(value, forCharacteristic:characteristic.cbCharacteristic, type:type)
    }
    
    internal func discoverCharacteristics(characteristics: [CBUUID]?, forService service: Service) {
        self.cbPeripheral.discoverCharacteristics(characteristics, forService:service.cbService)
    }
    
    private func didReadRSSI(RSSI: NSNumber, error: NSError?) {
        Logger.debug()
        if let error = error {
            self.readRSSIPromise.failure(error)
        } else {
            self.readRSSIPromise.success(RSSI.integerValue)
        }
    }

    private func discoverIfConnected(services: [CBUUID]?) {
        if self.state == .Connected {
            self.cbPeripheral.discoverServices(services)
        } else {
            self.servicesDiscoveredPromise.failure(BCError.peripheralDisconnected)
        }
    }

    private func timeoutConnection(sequence: Int) {
        if let centralManager = self.centralManager {
            Logger.debug("sequence \(sequence), timeout:\(self.connectionTimeout)")
            self.timeoutQueue.delay(self.connectionTimeout) {
                if self.state != .Connected && sequence == self.connectionSequence && !self.forcedDisconnect {
                    Logger.debug("timing out sequence=\(sequence), current connectionSequence=\(self.connectionSequence)")
                    self.currentError = .Timeout
                    centralManager.cancelPeripheralConnection(self)
                } else {
                    Logger.debug()
                }
            }
        }
    }

    private func clearAll() {
        self.discoveredServices.removeAll()
        self.discoveredCharacteristics.removeAll()
    }
    
}
