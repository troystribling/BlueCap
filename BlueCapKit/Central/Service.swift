//
//  Service.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/11/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation
import CoreBluetooth

///////////////////////////////////////////
// ServiceImpl
public protocol ServiceWrappable {
    
    var uuid : CBUUID!              {get}
    var name : String               {get}
    var state: CBPeripheralState    {get}
    
    func discoverCharacteristics(characteristics:[CBUUID]!)
    func didDiscoverCharacteristics(error:NSError!)
    func didDiscoverCharacteristics()
    func discoverAllCharacteristics() -> Future<Self>
}

public final class ServiceImpl<Wrapper:ServiceWrappable> {
    
    private var characteristicsDiscoveredPromise    = Promise<Wrapper>()
    
    public func discoverAllCharacteristics(service:Wrapper) -> Future<Wrapper> {
        Logger.debug("ServiceImpl#discoverAllCharacteristics: uuid=\(service.uuid.UUIDString), name=\(service.name)")
        return self.discoverIfConnected(service, characteristics:nil)
    }
    
    public func discoverCharacteristics(service:Wrapper, characteristics:[CBUUID]!) -> Future<Wrapper> {
        Logger.debug("ServiceImpl#discoverCharacteristics: uuid=\(service.uuid.UUIDString), name=\(service.name)")
        return self.discoverIfConnected(service, characteristics:characteristics)
    }
    
    private func discoverIfConnected(service:Wrapper, characteristics:[CBUUID]!) -> Future<Wrapper> {
        self.characteristicsDiscoveredPromise = Promise<Wrapper>()
        if service.state == .Connected {
            service.discoverCharacteristics(characteristics)
        } else {
            self.characteristicsDiscoveredPromise.failure(BCError.peripheralDisconnected)
        }
        return self.characteristicsDiscoveredPromise.future
    }
    
    internal init() {
    }
    
    internal func didDiscoverCharacteristics(service:Wrapper, error:NSError!) {
        if let error = error {
            Logger.debug("ServiceImpl#didDiscoverCharacteristics failed")
            self.characteristicsDiscoveredPromise.failure(error)
        } else {
            service.didDiscoverCharacteristics()
            Logger.debug("ServiceImpl#didDiscoverCharacteristics success")
            self.characteristicsDiscoveredPromise.success(service)
        }
    }
    
}
// ServiceImpl
///////////////////////////////////////////

public final class Service : ServiceWrappable {
    
    internal var impl = ServiceImpl<Service>()
    
    // ServiceWrappable
    public var name : String {
        if let profile = self.profile {
            return profile.name
        } else {
            return "Unknown"
        }
    }
    
    public var uuid : CBUUID! {
        return self.cbService.UUID
    }
    
    public var state : CBPeripheralState {
        return self.peripheral.state
    }
    
    public func discoverCharacteristics(characteristics:[CBUUID]!) {
        self.peripheral.cbPeripheral.discoverCharacteristics(characteristics, forService:self.cbService)
    }
    
    public func didDiscoverCharacteristics() {
        self.discoveredCharacteristics.removeAll()
        for characteristic in self.cbService.characteristics {
            let cbCharacteristic = characteristic as! CBCharacteristic
            let bcCharacteristic = Characteristic(cbCharacteristic:cbCharacteristic, service:self)
            self.discoveredCharacteristics[bcCharacteristic.uuid] = bcCharacteristic
            bcCharacteristic.didDiscover()
            Logger.debug("Service#didDiscoverCharacteristics: uuid=\(bcCharacteristic.uuid.UUIDString), name=\(bcCharacteristic.name)")
        }
        
    }
    
    public func discoverAllCharacteristics() -> Future<Service> {
        Logger.debug("Service#discoverAllCharacteristics: ")
        return self.impl.discoverIfConnected(self, characteristics:nil)
    }
    
    public func didDiscoverCharacteristics(error:NSError!) {
        self.impl.didDiscoverCharacteristics(self, error:error)
    }

    // ServiceWrappable
    
    private let profile         : ServiceProfile?
    internal let _peripheral    : Peripheral
    internal let cbService      : CBService
    
    internal var discoveredCharacteristics  = [CBUUID:Characteristic]()
    
    public var characteristics : [Characteristic] {
        return self.discoveredCharacteristics.values.array
    }
    
    public var peripheral : Peripheral {
        return self._peripheral
    }
    
    public func discoverCharacteristics(characteristics:[CBUUID]) -> Future<Service> {
        Logger.debug("Service#discoverCharacteristics")
        return self.impl.discoverIfConnected(self, characteristics:characteristics)
    }
    
    internal init(cbService:CBService, peripheral:Peripheral) {
        self.cbService = cbService
        self._peripheral = peripheral
        self.profile = ProfileManager.sharedInstance.serviceProfiles[cbService.UUID]
    }
    
}