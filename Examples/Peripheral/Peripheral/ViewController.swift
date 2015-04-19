//
//  ViewController.swift
//  Beacon
//
//  Created by Troy Stribling on 4/13/15.
//  Copyright (c) 2015 gnos.us. All rights reserved.
//

import UIKit
import CoreBluetooth
import BlueCapKit

class ViewController: UITableViewController {
    
    @IBOutlet var xAccelerationLabel        : UILabel!
    @IBOutlet var yAccelerationLabel        : UILabel!
    @IBOutlet var zAccelerationLabel        : UILabel!
    @IBOutlet var xRawAccelerationLabel     : UILabel!
    @IBOutlet var yRawAccelerationLabel     : UILabel!
    @IBOutlet var zRawAccelerationLabel     : UILabel!
    @IBOutlet var updatePeriodLabel         : UILabel!
    @IBOutlet var startAdvertisingSwitch    : UISwitch!
    @IBOutlet var enabledSwitch             : UISwitch!
    @IBOutlet var startAdvertisingLabel     : UILabel!
    
    var startAdvertiseFuture            : Future<Void>?
    var stopAdvertiseFuture             : Future<Void>?
    var powerOffFuture                  : Future<Void>?
    var powerOffFutureSuccessFuture     : Future<Void>?
    var powerOffFutureFailedFuture      : Future<Void>?
    
    let acceleromter = Accelerometer()
    
    required init(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    @IBAction func toggleEnabled(sender:AnyObject) {
        
    }
    
    @IBAction func toggleAdvertise(sender:AnyObject) {
        let manager = PeripheralManager.sharedInstance
        if manager.isAdvertising {
            manager.stopAdvertising().onSuccess {
                self.presentViewController(UIAlertController.alertWithMessage("stoped advertising"), animated:true, completion:nil)
            }
        } else {
            // start monitoring when bluetooth is powered on
            self.startAdvertiseFuture = manager.powerOn().flatmap{ _ -> Future<Void> in
                manager.startAdvertising("BluecapKit")
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
            // enable controls when bluetooth is powered on again when stop advertising is successul
            self.powerOffFutureSuccessFuture = self.powerOffFuture?.flatmap { _ -> Future<Void> in
                manager.powerOn()
            }
            self.powerOffFutureSuccessFuture?.onSuccess {
                self.startAdvertisingSwitch.enabled = true
                self.startAdvertisingLabel.textColor = UIColor.blackColor()
            }
            // enable controls when bluetooth is powered on again when stop advertising fails
            self.powerOffFutureFailedFuture = self.powerOffFuture?.recoverWith { _  -> Future<Void> in
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
