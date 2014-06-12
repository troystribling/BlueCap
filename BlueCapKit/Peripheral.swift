//
//  Peripheral.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/8/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation
import CoreBluetooth

class Peripheral : NSObject, CBPeripheralDelegate {
    
    // peripheral
    var peripheralConnected         : ((peripheral:Peripheral!, error:NSError!) -> ())?
    var peripheralDisconnected      : ((Peripheral:Peripheral!) -> ())?
    var servicesDiscovered          : ((services:Service[]!) -> ())?
    var characteristicsDiscovered   : ((characteristics:Characteristic[]!) -> ())?
    var descriptorsDiscovered       : ((descriptors:Descriptor[]!) -> ())?
    var peripheralDiscovered        : ((peripheral:Peripheral!, error:NSError!) -> ())?
    
    
    let cbPeripheral    : CBPeripheral!
    let advertisement   : NSDictionary!
    
    var discoveredServices  : Dictionary<String, Service> = [:]
    var discoveredObjects   : Dictionary<String, AnyObject> = [:]
    
    var connectionSequence = 0
    
    var name : String {
        return cbPeripheral.name
    }
    
    init(cbPeripheral:CBPeripheral, advertisement:NSDictionary) {
        self.cbPeripheral = cbPeripheral
        self.advertisement = advertisement
    }
    
    // connect
    func connect(peripheralConnected:(peripheral:Peripheral!, error:NSError!)->()) {
    }
    
    func connect(peripheralConnected:(peripheral:Peripheral!, error:NSError!)->(), perpheralDisconnected:(peripheral:Peripheral!)->()) {
    }

    func connect () {
    }

    func disconnect() {
    }
    
    // service discovery
    func discoverAllServices(servicesDiscovered:(services:Service[]!)->()) {
    }
    
    func discoverServices(services:CBUUID[]!, servicesDiscovered:(services:Service[]!)->()) {
    }
    
    func discoverPeripheral(peripheralDiscovered:(peripheral:Peripheral!, error:NSError!)->()) {
    }
    
    // CBPeripheralDelegate Peripheral
    func peripheralDidUpdateName(peripheral:CBPeripheral!) {
    }
    
    func peripheral(peripheral:CBPeripheral!, didModifyServices invalidatedServices:AnyObject[]!) {
    }

    // CBPeripheralDelegate Services
    func peripheral(peripheral:CBPeripheral!, didDiscoverServices error:NSError!) {
    }
    
    func peripheral(peripheral:CBPeripheral!, didDiscoverIncludedServicesForService service:CBService!, error:NSError!) {
    }
    
    // CBPeripheralDelegate Characteristics
    func peripheral(peripheral:CBPeripheral!, didDiscoverCharacteristicsForService service:CBService!, error:NSError!) {
    }
    
    func peripheral(peripheral:CBPeripheral!, didUpdateNotificationStateForCharacteristic characteristic:CBCharacteristic!, error: NSError!) {
    }

    func peripheral(peripheral:CBPeripheral!, didUpdateValueForCharacteristic characteristic:CBCharacteristic!, error:NSError!) {
    }

    func peripheral(peripheral:CBPeripheral!, didWriteValueForCharacteristic characteristic:CBCharacteristic!, error: NSError!) {
    }
    
    // CBPeripheral Delegate Descriptors
    func peripheral(peripheral:CBPeripheral!, didDiscoverDescriptorsForCharacteristic characteristic:CBCharacteristic!, error:NSError!) {
    }
    
    func peripheral(peripheral:CBPeripheral!, didUpdateValueForDescriptor descriptor:CBDescriptor!, error:NSError!) {
    }
    
    func peripheral(peripheral:CBPeripheral!, didWriteValueForDescriptor descriptor:CBDescriptor!, error:NSError!) {
    }
}
