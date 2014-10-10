//
//  Service.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/11/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation
import CoreBluetooth

public class Service : NSObject {
    
    // PRIVATE
    private let profile                                     : ServiceProfile?
    private var characteristicsDiscoveredSuccessCallback    : (() -> ())?
    private var characteristicDiscoveryFailedCallback       : ((error:NSError!) -> ())?
    private var characteristicDiscoveryTimeout              : Float?

    // INTERNAL
    internal let peripheral                     : Peripheral
    internal let cbService                      : CBService
    
    internal var discoveredCharacteristics      = Dictionary<CBUUID, Characteristic>()
    
    // PUBLIC
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
    
    public var characteristics : [Characteristic] {
        return self.discoveredCharacteristics.values.array
    }
    
    // PUBLIC
    public func discoverAllCharacteristics(characteristicsDiscoveredSuccessCallback:() -> (), characteristicDiscoveryFailedCallback:((error:NSError!) -> ())? = nil) {
        Logger.debug("Service#discoverAllCharacteristics")
        self.characteristicsDiscoveredSuccessCallback = characteristicsDiscoveredSuccessCallback
        self.characteristicDiscoveryFailedCallback = characteristicDiscoveryFailedCallback
        self.characteristicDiscoveryTimeout = nil
        self.discoverIfConnected(nil)
    }

    public func discoverAllCharacteristicsWithTimeout(timeout:Float, characteristicsDiscoveredSuccessCallback:() -> (), characteristicDiscoveryFailedCallback:(error:NSError!) -> ()) {
        Logger.debug("Service#discoverAllCharacteristics")
        self.characteristicsDiscoveredSuccessCallback = characteristicsDiscoveredSuccessCallback
        self.characteristicDiscoveryFailedCallback = characteristicDiscoveryFailedCallback
        self.characteristicDiscoveryTimeout = timeout
        self.discoverIfConnected(nil)
    }

    public func discoverCharacteristics(characteristics:[CBUUID], characteristicsDiscoveredSuccessCallback:() -> (), characteristicDiscoveryFailedCallback:((error:NSError!) -> ())? = nil) {
        Logger.debug("Service#discoverCharacteristics")
        self.characteristicsDiscoveredSuccessCallback = characteristicsDiscoveredSuccessCallback
        self.characteristicDiscoveryFailedCallback = characteristicDiscoveryFailedCallback
        self.characteristicDiscoveryTimeout = nil
        self.discoverIfConnected(characteristics)
    }

    public func discoverCharacteristicsWithTimeout(timeout:Float, characteristics:[CBUUID], characteristicsDiscoveredSuccessCallback:() -> (), characteristicDiscoveryFailedCallback:((error:NSError!) -> ())? = nil) {
        Logger.debug("Service#discoverCharacteristics")
        self.characteristicsDiscoveredSuccessCallback = characteristicsDiscoveredSuccessCallback
        self.characteristicDiscoveryFailedCallback = characteristicDiscoveryFailedCallback
        self.characteristicDiscoveryTimeout = timeout
        self.discoverIfConnected(characteristics)
    }

    // PRIVATE
    private func discoverIfConnected(services:[CBUUID]!) {
        if self.peripheral.state == .Connected {
            self.peripheral.cbPeripheral.discoverCharacteristics(nil, forService:self.cbService)
        } else {
            if let characteristicDiscoveryFailedCallback = self.characteristicDiscoveryFailedCallback {
                CentralManager.asyncCallback(){characteristicDiscoveryFailedCallback(error:
                    NSError.errorWithDomain(BCError.domain, code:BCError.PeripheralDisconnected.code, userInfo:[NSLocalizedDescriptionKey:BCError.PeripheralDisconnected.description]))}
            }
        }
    }

    // INTERNAL
    internal init(cbService:CBService, peripheral:Peripheral) {
        self.cbService = cbService
        self.peripheral = peripheral
        self.profile = ProfileManager.sharedInstance().serviceProfiles[cbService.UUID]
    }
    
    internal func didDiscoverCharacteristics() {
        self.discoveredCharacteristics.removeAll()
        if let cbCharacteristics = self.cbService.characteristics {
            for cbCharacteristic : AnyObject in cbCharacteristics {
                let bcCharacteristic = Characteristic(cbCharacteristic:cbCharacteristic as CBCharacteristic, service:self)
                self.discoveredCharacteristics[bcCharacteristic.uuid] = bcCharacteristic
                bcCharacteristic.didDiscover()
                Logger.debug("Service#didDiscoverCharacteristics: uuid=\(bcCharacteristic.uuid.UUIDString), name=\(bcCharacteristic.name)")
            }
            if let characteristicsDiscoveredSuccessCallback = self.characteristicsDiscoveredSuccessCallback {
                CentralManager.asyncCallback(characteristicsDiscoveredSuccessCallback)
            }
        }
    }
}