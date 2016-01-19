//
//  ViewController.swift
//  Beacon
//
//  Created by Troy Stribling on 4/13/15.
//  Copyright (c) 2015 Troy Stribling. The MIT License (MIT).
//

import UIKit
import CoreBluetooth
import CoreMotion
import BlueCapKit

class ViewController: UITableViewController {
    
    @IBOutlet var xAccelerationLabel        : UILabel!
    @IBOutlet var yAccelerationLabel        : UILabel!
    @IBOutlet var zAccelerationLabel        : UILabel!
    @IBOutlet var xRawAccelerationLabel     : UILabel!
    @IBOutlet var yRawAccelerationLabel     : UILabel!
    @IBOutlet var zRawAccelerationLabel     : UILabel!
    
    @IBOutlet var rawUpdatePeriodlabel      : UILabel!
    @IBOutlet var updatePeriodLabel         : UILabel!
    
    @IBOutlet var startAdvertisingSwitch    : UISwitch!
    @IBOutlet var startAdvertisingLabel     : UILabel!
    @IBOutlet var enableLabel               : UILabel!
    @IBOutlet var enabledSwitch             : UISwitch!
    
    let accelerometer                           = Accelerometer()
    
    let accelerometerService                    = MutableService(uuid:TISensorTag.AccelerometerService.uuid, peripheralManager:PeripheralManager.sharedInstance)
    let accelerometerDataCharacteristic         = MutableCharacteristic(uuid:TISensorTag.AccelerometerService.Data.uuid,
                                                    properties:[.Read, .Indicate],
                                                    permissions:[.Readable, .Writeable],
                                                    value:Serde.serialize(TISensorTag.AccelerometerService.Data(x:1.0, y:0.5, z:-1.5)!))
    let accelerometerEnabledCharacteristic      = MutableCharacteristic(uuid:TISensorTag.AccelerometerService.Enabled.uuid,
                                                    properties:[.Read, .Write],
                                                    permissions:[.Readable, .Writeable],
                                                    value:Serde.serialize(TISensorTag.AccelerometerService.Enabled.No.rawValue))
    let accelerometerUpdatePeriodCharacteristic = MutableCharacteristic(uuid:TISensorTag.AccelerometerService.UpdatePeriod.uuid,
                                                    properties:[.Read, .Write],
                                                    permissions:[.Readable, .Writeable],
                                                    value:Serde.serialize(UInt8(100)))
    
    required init?(coder aDecoder:NSCoder) {
        self.accelerometerService.characteristics =
            [self.accelerometerDataCharacteristic, self.accelerometerEnabledCharacteristic, self.accelerometerUpdatePeriodCharacteristic]
        super.init(coder:aDecoder)
        self.respondToWriteRequests()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if self.accelerometer.accelerometerAvailable {
            self.startAdvertisingSwitch.enabled = true
            self.startAdvertisingLabel.textColor = UIColor.blackColor()
            self.enabledSwitch.enabled = true
            self.enableLabel.textColor = UIColor.blackColor()
            self.updatePeriod()
        } else {
            self.startAdvertisingSwitch.enabled = false
            self.startAdvertisingSwitch.on = false
            self.startAdvertisingLabel.textColor = UIColor.lightGrayColor()
            self.enabledSwitch.enabled = false
            self.enabledSwitch.on = false
            self.enableLabel.textColor = UIColor.lightGrayColor()
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    @IBAction func toggleEnabled(sender:AnyObject) {
        if self.accelerometer.accelerometerActive {
            self.accelerometer.stopAccelerometerUpdates()
        } else {
            let accelrometerDataFuture = self.accelerometer.startAcceleromterUpdates()
            accelrometerDataFuture.onSuccess {data in
                self.updateAccelerometerData(data)
            }
            accelrometerDataFuture.onFailure {error in
                self.presentViewController(UIAlertController.alertOnError(error), animated:true, completion:nil)
            }
        }
    }
    
    @IBAction func toggleAdvertise(sender:AnyObject) {
        let manager = PeripheralManager.sharedInstance
        if manager.isAdvertising {
            manager.stopAdvertising().onSuccess {
                self.presentViewController(UIAlertController.alertWithMessage("stoped advertising"), animated:true, completion:nil)
            }
            self.accelerometerUpdatePeriodCharacteristic.stopRespondingToWriteRequests()
        } else {
            self.startAdvertising()
        }
    }
    
    func startAdvertising() {
        let uuid = CBUUID(string:TISensorTag.AccelerometerService.uuid)
        let manager = PeripheralManager.sharedInstance
        // on power on remove all services add service and start advertising
        let startAdvertiseFuture = manager.powerOn().flatmap {_ -> Future<Void> in
            manager.removeAllServices()
        }.flatmap {_ -> Future<Void> in
                manager.addService(self.accelerometerService)
        }.flatmap {_ -> Future<Void> in
                manager.startAdvertising(TISensorTag.AccelerometerService.name, uuids:[uuid])
        }
        startAdvertiseFuture.onSuccess {
            self.presentViewController(UIAlertController.alertWithMessage("powered on and started advertising"), animated:true, completion:nil)
        }
        startAdvertiseFuture.onFailure {error in
            self.presentViewController(UIAlertController.alertOnError(error), animated:true, completion:nil)
            self.startAdvertisingSwitch.on = false
        }
        // stop advertising and updating accelerometer on bluetooth power off
        let powerOffFuture = manager.powerOff().flatmap { _ -> Future<Void> in
            if self.accelerometer.accelerometerActive {
                self.accelerometer.stopAccelerometerUpdates()
                self.enabledSwitch.on = false
            }
            return manager.stopAdvertising()
        }
        powerOffFuture.onSuccess {
            self.startAdvertisingSwitch.on = false
            self.startAdvertisingSwitch.enabled = false
            self.startAdvertisingLabel.textColor = UIColor.lightGrayColor()
            self.presentViewController(UIAlertController.alertWithMessage("powered off and stopped advertising"), animated:true, completion:nil)
        }
        powerOffFuture.onFailure {error in
            self.startAdvertisingSwitch.on = false
            self.startAdvertisingSwitch.enabled = false
            self.startAdvertisingLabel.textColor = UIColor.lightGrayColor()
            self.presentViewController(UIAlertController.alertWithMessage("advertising failed"), animated:true, completion:nil)
        }
        // enable controls when bluetooth is powered on again after stop advertising is successul
        let powerOffFutureSuccessFuture = powerOffFuture.flatmap {_ -> Future<Void> in
            manager.powerOn()
        }
        powerOffFutureSuccessFuture.onSuccess {
            self.presentViewController(UIAlertController.alertWithMessage("restart application"), animated:true, completion:nil)
        }
        // enable controls when bluetooth is powered on again after stop advertising fails
        let powerOffFutureFailedFuture = powerOffFuture.recoverWith {_  -> Future<Void> in
            manager.powerOn()
        }
        powerOffFutureFailedFuture.onSuccess {
            if PeripheralManager.sharedInstance.poweredOn {
                self.presentViewController(UIAlertController.alertWithMessage("restart application"), animated:true, completion:nil)
            }
        }
    }
    
    func respondToWriteRequests() {
        let accelerometerUpdatePeriodFuture = self.accelerometerUpdatePeriodCharacteristic.startRespondingToWriteRequests(2)
        accelerometerUpdatePeriodFuture.onSuccess {(request, _) in
            if let value = request.value where value.length > 0 && value.length <= 8 {
                self.accelerometerUpdatePeriodCharacteristic.value = value
                self.accelerometerUpdatePeriodCharacteristic.respondToRequest(request, withResult:CBATTError.Success)
                self.updatePeriod()
            } else {
                self.accelerometerUpdatePeriodCharacteristic.respondToRequest(request, withResult:CBATTError.InvalidAttributeValueLength)
            }
        }
        let accelerometerEnabledFuture = self.accelerometerEnabledCharacteristic.startRespondingToWriteRequests(2)
        accelerometerEnabledFuture.onSuccess {(request, _) in
            if let value = request.value where value.length == 1 {
                self.accelerometerEnabledCharacteristic.value = request.value
                self.accelerometerEnabledCharacteristic.respondToRequest(request, withResult:CBATTError.Success)
                self.updateEnabled()
            } else {
                self.accelerometerEnabledCharacteristic.respondToRequest(request, withResult:CBATTError.InvalidAttributeValueLength)
            }
        }
    }
    
    func updateAccelerometerData(data:CMAcceleration) {
        self.xAccelerationLabel.text = NSString(format: "%.2f", data.x) as String
        self.yAccelerationLabel.text = NSString(format: "%.2f", data.y) as String
        self.zAccelerationLabel.text = NSString(format: "%.2f", data.z) as String
        if let xRaw = Int8(doubleValue:(-64.0*data.x)), yRaw = Int8(doubleValue:(-64.0*data.y)), zRaw = Int8(doubleValue:(64.0*data.z)) {
            self.xRawAccelerationLabel.text = "\(xRaw)"
            self.yRawAccelerationLabel.text = "\(yRaw)"
            self.zRawAccelerationLabel.text = "\(zRaw)"
            if let data = TISensorTag.AccelerometerService.Data(rawValue:[xRaw, yRaw, zRaw])
                where self.accelerometerDataCharacteristic.hasSubscriber && !self.accelerometerDataCharacteristic.updateValue(data){
                self.presentViewController(UIAlertController.alertWithMessage("Accerometer indication update failed"), animated:true, completion:nil)
            }
        }
    }
    
    func updatePeriod() {
        if let value = self.accelerometerUpdatePeriodCharacteristic.value {
            if let period : TISensorTag.AccelerometerService.UpdatePeriod = Serde.deserialize(value) {
                self.accelerometer.updatePeriod = Double(period.period)/1000.0
                self.updatePeriodLabel.text =  NSString(format: "%d", period.period) as String
                self.rawUpdatePeriodlabel.text = NSString(format: "%d", period.periodRaw) as String
            }
        }
    }
    
    func updateEnabled() {
        if let value = self.accelerometerEnabledCharacteristic.value, enabled:TISensorTag.AccelerometerService.Enabled = Serde.deserialize(value) where self.enabledSwitch.on != enabled.boolValue {
            self.enabledSwitch.on = enabled.boolValue
            self.toggleEnabled(self)
        }
    }
}
