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
    
    public var regionCreateSuccess  : ((region:CircularRegion) -> ())?
    public var regionCreateFailed   : ((region:CircularRegion) -> ())?
    
    public override init(initializer:(regionConnectorator:RegionConnectorator)->()) {
        super.init()
        initializer(regionConnectorator:self)
    }
    
    private func createRegion() {
        LocationManager.currentLocation({(location:CLLocation) in
            }, locationUpdateFailed:{(error:NSError!) in
            }
        )
    }
}
