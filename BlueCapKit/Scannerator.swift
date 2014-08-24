//
//  Scannerator.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/24/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation
import CoreBluetooth

public class Scannerator {
    
    private var timeoutRetries              = 0
    
    internal var timeoutSeconds : Float    = 10.0
    
    public var onTimeout : (() -> ())?
    
    public init() {
    }
    
    public init(timeoutSeconds:Float, timeoutRetries:Int) {
        self.timeoutRetries = timeoutRetries
        self.timeoutSeconds = timeoutSeconds
    }
    
    internal func didTimeout() {
    }
}