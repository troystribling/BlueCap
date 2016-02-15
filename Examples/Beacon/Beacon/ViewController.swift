//
//  ViewController.swift
//  Beacon
//
//  Created by Troy Stribling on 4/13/15.
//  Copyright (c) 2015 Troy Stribling. The MIT License (MIT).
//

import UIKit
import CoreBluetooth
import BlueCapKit

class ViewController: UITableViewController, UITextFieldDelegate {
    
    @IBOutlet var nameTextField: UITextField!
    @IBOutlet var uuidTextField: UITextField!
    @IBOutlet var majorTextField: UITextField!
    @IBOutlet var minorTextField: UITextField!
    @IBOutlet var generateUUIDButton: UIButton!
    @IBOutlet var startAdvertisingSwitch: UISwitch!
    @IBOutlet var startAdvertisingLabel: UILabel!

    let manager = BCPeripheralManager()

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.startAdvertisingLabel.textColor = UIColor.lightGrayColor()
        self.startAdvertisingSwitch.on = false
        self.setUI()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    @IBAction func generateUUID(sender: AnyObject) {
        let uuid = NSUUID()
        self.uuidTextField.text = uuid.UUIDString
        BeaconStore.setBeaconUUID(uuid)
        self.setUI()
    }

    // UITextFieldDelegate
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        return self.addBeacon(textField)
    }
    
    func addBeacon(textField: UITextField) -> Bool {
        if let enteredName = self.nameTextField.text, enteredMajor = self.majorTextField.text, enteredMinor = self.minorTextField.text
        where !enteredName.isEmpty && !enteredMinor.isEmpty && !enteredMajor.isEmpty {
            if let minor = Int(enteredMinor),  major = Int(enteredMajor) where minor < 65536 && major < 65536 {
                if let enteredUUID = self.uuidTextField.text where !enteredUUID.isEmpty {
                    if let uuid = NSUUID(UUIDString: enteredUUID), minor = Int(enteredMinor),  major = Int(enteredMajor) {
                        BeaconStore.setBeaconUUID(uuid)
                        BeaconStore.setBeaconConfig([UInt16(minor), UInt16(major)])
                        BeaconStore.setBeaconName(enteredName)
                        textField.resignFirstResponder()
                        self.setUI()
                    } else {
                        self.presentViewController(UIAlertController.alertOnErrorWithMessage("UUID '\(enteredUUID)' is Invalid"), animated: true, completion: nil)
                        self.startAdvertisingSwitch.on = false
                        return false
                    }
                }
                return true
            } else {
                self.presentViewController(UIAlertController.alertOnErrorWithMessage("major and minor not convertable to a number"), animated: true, completion: nil)
                return false
            }
        } else {
            return false
        }
    }
    
    @IBAction func toggleAdvertise(sender: AnyObject) {
        if self.manager.isAdvertising {
            let stopAdvertiseFuture = self.manager.stopAdvertising()
            stopAdvertiseFuture.onSuccess {
                self.presentViewController(UIAlertController.alertWithMessage("stoped advertising"), animated: true, completion: nil)
            }
            stopAdvertiseFuture.onFailure {error in
                self.presentViewController(UIAlertController.alertOnError(error), animated: true, completion: nil)
            }
        } else {
            // Start advertising on bluetooth power on
            if let beaconRegion = self.createBeaconRegion() {
                let startAdvertiseFuture = self.manager.whenPowerOn().flatmap{ _ in
                    self.manager.startAdvertising(beaconRegion)
                }
                startAdvertiseFuture.onSuccess {
                    self.presentViewController(UIAlertController.alertWithMessage("powered on and started advertising"), animated: true, completion: nil)
                }
                startAdvertiseFuture.onFailure { error in
                    self.presentViewController(UIAlertController.alertOnError(error), animated: true, completion: nil)
                    self.startAdvertisingSwitch.on = false
                }
            }

            // stop advertising on bluetooth power off
            let powerOffFuture = self.manager.whenPowerOff().flatmap { _ in
                self.manager.stopAdvertising()
            }
            powerOffFuture.onSuccess {
                self.startAdvertisingSwitch.on = false
                self.startAdvertisingSwitch.enabled = false
                self.startAdvertisingLabel.textColor = UIColor.lightGrayColor()
                self.presentViewController(UIAlertController.alertWithMessage("powered off and stopped advertising"), animated: true, completion: nil)
            }
            powerOffFuture.onFailure {error in
                self.startAdvertisingSwitch.on = false
                self.startAdvertisingSwitch.enabled = false
                self.startAdvertisingLabel.textColor = UIColor.lightGrayColor()
                self.presentViewController(UIAlertController.alertWithMessage("advertising failed"), animated: true, completion: nil)
            }

            // enable controls when bluetooth is powered on again after stop advertising is successul
            let powerOffFutureSuccessFuture = powerOffFuture.flatmap { _ in
                self.manager.whenPowerOn()
            }
            powerOffFutureSuccessFuture.onSuccess {
                self.startAdvertisingSwitch.enabled = true
                self.startAdvertisingLabel.textColor = UIColor.blackColor()
            }
            
            // enable controls when bluetooth is powered on again after stop advertising fails
            let powerOffFutureFailedFuture = powerOffFuture.recoverWith { _  in
                self.manager.whenPowerOn()
            }
            powerOffFutureFailedFuture.onSuccess {
                if self.manager.poweredOn {
                    self.startAdvertisingSwitch.enabled = true
                    self.startAdvertisingLabel.textColor = UIColor.blackColor()
                }
            }
        }
    }

    func createBeaconRegion() -> FLBeaconRegion? {
        if let name = BeaconStore.getBeaconName(), uuid = BeaconStore.getBeaconUUID() {
            let config = BeaconStore.getBeaconConfig()
            if config.count == 2 {
                return FLBeaconRegion(proximityUUID: uuid, identifier: name, major: config[1], minor: config[0])
            } else {
                self.presentViewController(UIAlertController.alertOnErrorWithMessage("configuration invalid"), animated: true, completion: nil)
                return nil
            }
        } else {
            self.presentViewController(UIAlertController.alertOnErrorWithMessage("configuration invalid"), animated: true, completion: nil)
            return nil
        }
    }
    
    func setUI() {
        var uuidSet = false
        if let uuid = BeaconStore.getBeaconUUID() {
            self.uuidTextField.text = uuid.UUIDString
            uuidSet = true
        }
        var nameSet = false
        if let name = BeaconStore.getBeaconName() {
            self.nameTextField.text = name
            nameSet = true
        }
        var majoMinorSet = false
        let beaconConfig = BeaconStore.getBeaconConfig()
        if beaconConfig.count == 2 {
            self.minorTextField.text = "\(beaconConfig[0])"
            self.majorTextField.text = "\(beaconConfig[1])"
            majoMinorSet = true
        }
        if uuidSet && nameSet && majoMinorSet {
            self.startAdvertisingLabel.textColor = UIColor.blackColor()
            self.startAdvertisingSwitch.enabled = true
        } else {
            self.startAdvertisingLabel.textColor = UIColor.lightGrayColor()
            self.startAdvertisingSwitch.enabled = false
        }
    }
}
