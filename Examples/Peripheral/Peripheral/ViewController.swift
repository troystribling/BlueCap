//
//  ViewController.swift
//  Beacon
//
//  Created by Troy Stribling on 4/13/15.
//  Copyright (c) 2015 gnos.us. All rights reserved.
//

import UIKit
import CoreBluetooth
import CoreMotion
import BlueCapKit

class ViewController: UITableViewController {
    
    let g =  9.81
    
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
    
    var startAdvertiseFuture            : Future<Void>?
    var stopAdvertiseFuture             : Future<Void>?
    var powerOffFuture                  : Future<Void>?
    var powerOffFutureSuccessFuture     : Future<Void>?
    var powerOffFutureFailedFuture      : Future<Void>?
    
    let accelerometer           = Accelerometer()
    var accelrometerDataFuture  : FutureStream<CMAcceleration>?
    
    required init(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
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
            self.accelrometerDataFuture = self.accelerometer.startAcceleromterUpdates()
            self.accelrometerDataFuture?.onSuccess {data in
                self.updateAccelerometerData(data)
            }
            self.accelrometerDataFuture?.onFailure {error in
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
        } else {
            // start monitoring when bluetooth is powered on
            if let uuid = CBUUID(string:TISensorTag.AccelerometerService.uuid) {
                if let serviceProfile = ProfileManager.sharedInstance.service(uuid) {
                    let service = MutableService(profile:serviceProfile)
                    service.characteristicsFromProfiles(serviceProfile.characteristics)
                    self.startAdvertiseFuture = manager.powerOn().flatmap {_ -> Future<Void> in
                        manager.removeAllServices()
                    }.flatmap {_ -> Future<Void> in
                        manager.addService(service)
                    }.flatmap {_ -> Future<Void> in
                        manager.startAdvertising(TISensorTag.AccelerometerService.name, uuids:[uuid])
                    }
                    self.startAdvertiseFuture?.onSuccess {
                        self.presentViewController(UIAlertController.alertWithMessage("powered on and started advertising"), animated:true, completion:nil)
                    }
                    self.startAdvertiseFuture?.onFailure {error in
                        self.presentViewController(UIAlertController.alertOnError(error), animated:true, completion:nil)
                        self.startAdvertisingSwitch.on = false
                    }
                    // stop advertising on bluetooth power off
                    self.powerOffFuture = manager.powerOff().flatmap { _ -> Future<Void> in
                        manager.stopAdvertising()
                    }
                    self.powerOffFuture?.onSuccess {
                        self.startAdvertisingSwitch.on = false
                        self.startAdvertisingSwitch.enabled = false
                        self.startAdvertisingLabel.textColor = UIColor.lightGrayColor()
                        self.presentViewController(UIAlertController.alertWithMessage("powered off and stopped advertising"), animated:true, completion:nil)
                    }
                    self.powerOffFuture?.onFailure {error in
                        self.startAdvertisingSwitch.on = false
                        self.startAdvertisingSwitch.enabled = false
                        self.startAdvertisingLabel.textColor = UIColor.lightGrayColor()
                        self.presentViewController(UIAlertController.alertWithMessage("advertising failed"), animated:true, completion:nil)
                    }
                    // enable controls when bluetooth is powered on again after stop advertising is successul
                    self.powerOffFutureSuccessFuture = self.powerOffFuture?.flatmap {_ -> Future<Void> in
                        manager.powerOn()
                    }
                    self.powerOffFutureSuccessFuture?.onSuccess {
                        self.startAdvertisingSwitch.enabled = true
                        self.startAdvertisingLabel.textColor = UIColor.blackColor()
                    }
                    // enable controls when bluetooth is powered on again after     stop advertising fails
                    self.powerOffFutureFailedFuture = self.powerOffFuture?.recoverWith {_  -> Future<Void> in
                        manager.powerOn()
                    }
                    self.powerOffFutureFailedFuture?.onSuccess {
                        if PeripheralManager.sharedInstance.poweredOn {
                            self.startAdvertisingSwitch.enabled = true
                            self.startAdvertisingLabel.textColor = UIColor.blackColor()
                        }
                    }
                }
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
            if PeripheralManager.sharedInstance.isAdvertising {
                
            }
        }
    }
    
    func updatePeriod() {
        let value = self.accelerometer.updatePeriod
        if let msValue = UInt16(doubleValue:1000.0*value), rawValue = UInt16(doubleValue:100.0*value) {
            self.updatePeriodLabel.text =  NSString(format: "%d", msValue) as String
            self.rawUpdatePeriodlabel.text = NSString(format: "%d", rawValue) as String
        }
    }
    
}
