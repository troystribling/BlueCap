//
//  PeripheralManagerBeaconViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 9/28/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import UIKit
import BlueCapKit

class PeripheralManagerBeaconViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet var nameTextField     : UITextField!
    @IBOutlet var uuidTextField     : UITextField!
    @IBOutlet var majorTextField    : UITextField!
    @IBOutlet var minorTextField    : UITextField!
    
    var beaconName                      : String?
    var peripheralManagerViewController : PeripheralManagerViewController?

    
    required init(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let beaconName = self.beaconName {
            self.navigationItem.title = beaconName
            self.nameTextField.text = beaconName
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
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"didBecomeActive", name:BlueCapNotification.didBecomeActive, object:nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"didResignActive", name:BlueCapNotification.didResignActive, object:nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func didResignActive() {
        Logger.debug("PeripheralManagerBeaconViewController#didResignActive")
    }
    
    func didBecomeActive() {
        Logger.debug("PeripheralManagerBeaconViewController#didBecomeActive")
    }

    @IBAction func generateUUID(sender:AnyObject) {
        if let uuid = Optional(NSUUID()) {
            self.uuidTextField.text = uuid.UUIDString
        }
    }
    
    // UITextFieldDelegate
    func textFieldShouldReturn(textField: UITextField!) -> Bool {
        self.nameTextField.resignFirstResponder()
        let enteredUUID = self.uuidTextField.text
        let enteredName = self.nameTextField.text
        let enteredMajor = self.majorTextField.text
        let enteredMinor = self.minorTextField.text
        if enteredName != nil && enteredUUID != nil && enteredMinor != nil && enteredMinor != nil  {
            if !enteredName!.isEmpty && !enteredUUID!.isEmpty && !enteredMinor!.isEmpty && !enteredMajor!.isEmpty {
                if let uuid = Optional(NSUUID(UUIDString:enteredUUID)) {
                    if let minor = enteredMinor!.toInt() {
                        if let major = enteredMajor!.toInt() {
                            if minor < 65536 && major < 65536 {
                                PeripheralStore.addBeaconConfig(enteredName!, config:[UInt16(minor), UInt16(major)])
                            } else {
                                self.presentViewController(UIAlertController.alertOnErrorWithMessage("major and minor must be less than 65536"), animated:true, completion:nil)
                                return false
                            }
                        } else {
                            self.presentViewController(UIAlertController.alertOnErrorWithMessage("major is not convertable to a num ber"), animated:true, completion:nil)
                            return false
                        }
                    } else {
                        self.presentViewController(UIAlertController.alertOnErrorWithMessage("minor is not convertable to a num ber"), animated:true, completion:nil)
                        return false
                    }
                    PeripheralStore.addBeacon(enteredName!, uuid:uuid)
                    if let beaconName = self.beaconName {
                        if self.beaconName != enteredName! {
                            PeripheralStore.removeBeacon(beaconName)
                            PeripheralStore.removeBeaconConfig(beaconName)
                        }
                    }
                    self.navigationController?.popViewControllerAnimated(true)
                    return true
                } else {
                    self.presentViewController(UIAlertController.alertOnErrorWithMessage("UUID '\(enteredUUID)' is Invalid"), animated:true, completion:nil)
                    return false
                }
            } else {
                return false
            }
        } else {
            return false
        }
    }

}
