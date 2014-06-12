//
//  Descriptor.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/8/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation
import CoreBluetooth

class Descriptor {
    
    let cbDescriptor : CBDescriptor!
    
    init(cbDescriptor:CBDescriptor) {
        self.cbDescriptor = cbDescriptor
    }
    
}
