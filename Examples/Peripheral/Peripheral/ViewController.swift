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
    @IBOutlet var startAdvertisingSwitch    : UISwitch!
    @IBOutlet var startAdvertisingLabel     : UILabel!
    
    var startAdvertiseFuture    : Future<Void>?
    var stopAdvertiseFuture     : Future<Void>?
    var powerOnFuture           : Future<Void>?
    
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
    
    @IBAction func toggleAdvertise(sender:AnyObject) {
        let manager = PeripheralManager.sharedInstance
        if manager.isAdvertising {
            manager.stopAdvertising().onSuccess {
                self.presentViewController(UIAlertController.alertWithMessage("stoped advertising"), animated:true, completion:nil)
            }
        } else {
//            self.startAdvertiseFuture = manager.powerOn().flatmap{ _ -> Future<Void> in
//                manager.startAdvertising(beaconRegion)
//            }
//            self.startAdvertiseFuture?.onSuccess {
//                self.presentViewController(UIAlertController.alertWithMessage("powered on and started advertising"), animated:true, completion:nil)
//            }
//            self.startAdvertiseFuture?.onFailure {error in
//                self.presentViewController(UIAlertController.alertOnError(error), animated:true, completion:nil)
//                self.startAdvertisingSwitch.on = false
//            }
        }
        self.stopAdvertiseFuture = manager.powerOff().flatmap { _ -> Future<Void> in
            manager.stopAdvertising()
        }
        self.stopAdvertiseFuture?.onSuccess {
            self.startAdvertisingSwitch.on = false
            self.startAdvertisingSwitch.enabled = false
            self.startAdvertisingLabel.textColor = UIColor.lightGrayColor()
            self.presentViewController(UIAlertController.alertWithMessage("powered off and stopped advertising"), animated:true, completion:nil)
        }
        self.stopAdvertiseFuture?.onFailure {error in
            self.presentViewController(UIAlertController.alertOnError(error), animated:true, completion:nil)
        }
        self.powerOnFuture = self.stopAdvertiseFuture?.flatmap { _ -> Future<Void> in
            manager.powerOn()
        }
        self.powerOnFuture?.onSuccess {
            self.startAdvertisingSwitch.enabled = true
            self.startAdvertisingLabel.textColor = UIColor.blackColor()
        }
    }
    
}
