//
//  CharacteristicTests.swift
//  BlueCapKit
//
//  Created by Troy Stribling on 1/7/15.
//  Copyright (c) 2015 gnos.us. All rights reserved.
//

import UIKit
import XCTest
import CoreBluetooth
import BlueCapKit

class CharacteristicTests: XCTestCase {

    // CharacteristicMock
    struct MockValues {
        static var isNotifying             = false
        static var stringValues            = [String]()
        static var propertyEnabled         = true
        static var stringValue             = ["Mock":"1"]
        static var dataFromStringValue     = "01".dataFromHexString()
        static var connectorator           = Connectorator()
        static var afterDiscoveredPromise  = StreamPromise<CharacteristicMock>()
    }
    
    struct CharacteristicMock : CharacteristicWrappable {
        
        var uuid : CBUUID! {
            return CBUUID(string:"2f0a0017-69aa-f316-3e78-4194989a6c1a")
        }
        
        var name : String {
            return "Mock"
        }
        
        var connectorator : Connectorator? {
            return MockValues.connectorator
        }
        
        var isNotifying : Bool {
            return MockValues.isNotifying
        }
        
        var stringValues : [String] {
            return MockValues.stringValues
        }
        
        var afterDiscoveredPromise  : StreamPromise<CharacteristicMock>? {
            return MockValues.afterDiscoveredPromise
        }
        
        func stringValue(data:NSData?) -> [String:String]? {
            return MockValues.stringValue
        }
        
        func dataFromStringValue(stringValue:[String:String]) -> NSData? {
            return MockValues.dataFromStringValue
        }
        
        func setNotifyValue(state:Bool) {
            MockValues.isNotifying = state
        }
        
        func propertyEnabled(property:CBCharacteristicProperties) -> Bool {
            return MockValues.propertyEnabled
        }
        
        func readValueForCharacteristic() {
        }
        
        func writeValue(value:NSData) {
        }
    }
    
    var characteristicImpl = CharacteristicImpl<CharacteristicMock>()
    // CharacteristicMock
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    

}
