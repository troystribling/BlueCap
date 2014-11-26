//
//  RegionConnectorator.swift
//  BlueCapKit
//
//  Created by Troy Stribling on 11/12/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation
import CoreLocation
import CoreBluetooth

public class RegionConnectorator : Connectorator {
    
    private var _region     : CircularRegion?
    private var identifier  : String
    
    public var regionCreateSuccess  : ((region:CircularRegion) -> ())?
    public var regionCreateFailed   : ((error:NSError?) -> ())?
    public var enterRegion          : (() -> ())?
    public var exitRegion           : (() -> ())?
    
    public var region : CircularRegion? {
        return self._region
    }
    
    public override init(initializer:(regionConnectorator:RegionConnectorator)->()) {
        self.identifier = "RegionConnectorator"
        super.init()
        initializer(regionConnectorator:self)
        self.createRegion()
    }
    
    public init(identifier:String, initializer:(regionConnectorator:RegionConnectorator)->()) {
        self.identifier = identifier
        super.init()
        initializer(regionConnectorator:self)
        self.createRegion()
    }
    
    private func createRegion() {
        RegionManager.sharedInstance.currentLocation({(location:CLLocation) in
                self._region = CircularRegion(center:location.coordinate, identifier:"RegionConnectorator") {(region) in
                    region.exitRegion = {
                        if let exitRegion = self.exitRegion {
                            CentralManager.asyncCallback(exitRegion)
                        } else {
                            self.peripheral?.disconnect()
                        }
                    }
                    region.enterRegion = {
                        if let enterRegion = self.enterRegion {
                            CentralManager.asyncCallback(enterRegion)
                        } else {
                            self.peripheral?.reconnect()
                        }
                    }
                }
                RegionManager.sharedInstance.startMonitoringForRegion(self._region!)
                if let regionCreateSuccess = self.regionCreateSuccess {
                    regionCreateSuccess(region:self._region!)
                }
            }, locationUpdateFailed:{(error:NSError?) in
                if let regionCreateFailed = self.regionCreateFailed {
                    regionCreateFailed(error:error)
                }
            }
        )
    }
}
