//
//  BeaconViewControllerTableViewController.swift
//  Beacon
//
//  Created by Troy Stribling on 4/13/15.
//  Copyright (c) 2015 gnos.us. All rights reserved.
//

import UIKit
import CoreBluetooth
import BlueCapKit

class BeaconViewControllerTableViewController: UITableViewController, UITextFieldDelegate {
    
    @IBOutlet var nameTextField             : UITextField!
    @IBOutlet var uuidTextField             : UITextField!
    @IBOutlet var majorTextField            : UITextField!
    @IBOutlet var minorTextField            : UITextField!
    @IBOutlet var generateUUIDButton        : UIButton!
    @IBOutlet var startAdvertisingSwitch    : UISwitch!
    @IBOutlet var startAdvertisingLabel     : UILabel!
    
    required init(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let beaconName = self.beaconName {
            self.navigationItem.title = beaconName
            self.nameTextField.text = beaconName
            self.doneBarButtonItem.enabled = false
            if let uuid = PeripheralStore.getBeacon(beaconName) {
                self.uuidTextField.text = uuid.UUIDString
            }
            let beaconConfig = PeripheralStore.getBeaconConfig(beaconName)
            self.minorTextField.text = "\(beaconConfig[0])"
            self.majorTextField.text = "\(beaconConfig[1])"
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func didResignActive() {
        Logger.debug("PeripheralManagerBeaconViewController#didResignActive")
        if let peripheralManagerViewController = self.peripheralManagerViewController {
            self.navigationController?.popToViewController(peripheralManagerViewController, animated:false)
        }
    }
    
    func didBecomeActive() {
        Logger.debug("PeripheralManagerBeaconViewController#didBecomeActive")
    }

    func enableAdvertising() {
        
    }
    
    func disableAdvertising() {
        
    }
    

    @IBAction func generateUUID(sender:AnyObject) {
        self.uuidTextField.text = NSUUID().UUIDString
        self.enableAdvertising()
    }
    
    @IBAction func toggleAdvertising(sender:AnyObject) {
    
    }
    
    // UITextFieldDelegate
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return self.addBeacon()
    }
    
    func addBeacon() -> Bool {
        let enteredUUID = self.uuidTextField.text
        let enteredName = self.nameTextField.text
        let enteredMajor = self.majorTextField.text
        let enteredMinor = self.minorTextField.text
        if let enteredUUID self.uuidTextField.text, enteredName = self.nameTextField.text, enteredMajor = self.majorTextField.text, enteredMinor = self.minorTextField.text where (!enteredName.isEmpty && !enteredUUID.isEmpty && !enteredMinor.isEmpty && !enteredMajor.isEmpty) {
//                if let uuid = NSUUID(UUIDString:enteredUUID) {
//                    if let minor = enteredMinor!.toInt() {
//                        if let major = enteredMajor!.toInt() {
//                            if minor < 65536 && major < 65536 {
//                                PeripheralStore.addBeaconConfig(enteredName!, config:[UInt16(minor), UInt16(major)])
//                            } else {
//                                self.presentViewController(UIAlertController.alertOnErrorWithMessage("major and minor must be less than 65536"), animated:true, completion:nil)
//                                return false
//                            }
//                        } else {
//                            self.presentViewController(UIAlertController.alertOnErrorWithMessage("major is not convertable to a number"), animated:true, completion:nil)
//                            return false
//                        }
//                    } else {
//                        self.presentViewController(UIAlertController.alertOnErrorWithMessage("minor is not convertable to a number"), animated:true, completion:nil)
//                        return false
//                    }
//                    PeripheralStore.addBeacon(enteredName!, uuid:uuid)
//                    if let beaconName = self.beaconName {
//                        if self.beaconName != enteredName! {
//                            PeripheralStore.removeBeacon(beaconName)
//                            PeripheralStore.removeBeaconConfig(beaconName)
//                        }
//                    }
//                    self.navigationController?.popViewControllerAnimated(true)
//                    return true
//                } else {
//                    self.presentViewController(UIAlertController.alertOnErrorWithMessage("UUID '\(enteredUUID)' is Invalid"), animated:true, completion:nil)
//                    return false
//                }
        } else {
            return false
        }
    }
    
//    @IBAction func toggleAdvertise(sender:AnyObject) {
//        let manager = PeripheralManager.sharedInstance
//        if manager.isAdvertising {
//            manager.stopAdvertising().onSuccess {
//                self.setUIState()
//            }
//        } else {
//            if let peripheral = self.peripheral {
//                let afterAdvertisingStarted = {
//                    self.setUIState()
//                }
//                let afterAdvertisingStartFailed:(error:NSError)->() = {(error) in
//                    self.setUIState()
//                    self.presentViewController(UIAlertController.alertOnError(error), animated:true, completion:nil)
//                }
//                let advertisedServices = PeripheralStore.getAdvertisedPeripheralServicesForPeripheral(peripheral)
//                if PeripheralStore.getBeaconEnabled(peripheral) {
//                    if let name = self.advertisedBeaconLabel.text {
//                        if let uuid = PeripheralStore.getBeacon(name) {
//                            let beaconConfig = PeripheralStore.getBeaconConfig(name)
//                            let beaconRegion = BeaconRegion(proximityUUID:uuid, identifier:name, major:beaconConfig[1], minor:beaconConfig[0])
//                            let future = manager.startAdvertising(beaconRegion)
//                            future.onSuccess(afterAdvertisingStarted)
//                            future.onFailure(afterAdvertisingStartFailed)
//                        }
//                    }
//                } else if advertisedServices.count > 0 {
//                    let future = manager.startAdvertising(peripheral, uuids:advertisedServices)
//                    future.onSuccess(afterAdvertisingStarted)
//                    future.onFailure(afterAdvertisingStartFailed)
//                } else {
//                    let future = manager.startAdvertising(peripheral)
//                    future.onSuccess(afterAdvertisingStarted)
//                    future.onFailure(afterAdvertisingStartFailed)
//                }
//            }
//        }
//    }
//    
//    @IBAction func toggleBeacon(sender:AnyObject) {
//        if let peripheral = self.peripheral {
//            if PeripheralStore.getBeaconEnabled(peripheral) {
//                PeripheralStore.setBeaconEnabled(peripheral, enabled:false)
//            } else {
//                if let name = self.advertisedBeaconLabel.text {
//                    if let uuid = PeripheralStore.getBeacon(name) {
//                        PeripheralStore.setBeaconEnabled(peripheral, enabled:true)
//                    } else {
//                        self.presentViewController(UIAlertController.alertWithMessage("iBeacon is invalid"), animated:true, completion:nil)
//                    }
//                }
//            }
//            self.setUIState()
//        }
//    }
    

}
