//
//  PeripheralManagerBeaconViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 9/28/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import UIKit
import BlueCapKit

class PeripheralManagerBeaconViewController: UITableViewController, UITextFieldDelegate {

    @IBOutlet var nameTextField     : UITextField!
    @IBOutlet var uuidTextField     : UITextField!
    @IBOutlet var majorTextField    : UITextField!
    @IBOutlet var minorTextField    : UITextField!
    @IBOutlet var doneBarButtonItem : UIBarButtonItem!
    
    var beaconName                      : String?
    var peripheralManagerViewController : PeripheralManagerViewController?

    
    required init?(coder aDecoder:NSCoder) {
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
        NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(PeripheralManagerBeaconViewController.didEnterBackground), name: UIApplicationDidEnterBackgroundNotification, object:nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func didEnterBackground() {
        BCLogger.debug()
        if let peripheralManagerViewController = self.peripheralManagerViewController {
            self.navigationController?.popToViewController(peripheralManagerViewController, animated:false)
        }
    }
    
    @IBAction func generateUUID(sender: AnyObject) {
        self.uuidTextField.text = NSUUID().UUIDString
        let enteredName = self.nameTextField.text
        let enteredMajor = self.majorTextField.text
        let enteredMinor = self.minorTextField.text
        if enteredName != nil && enteredMinor != nil && enteredMinor != nil {
            if !enteredName!.isEmpty && !enteredMinor!.isEmpty && !enteredMajor!.isEmpty {
                self.doneBarButtonItem.enabled = true
            }
        }
    }
    
    @IBAction func done(sender:AnyObject) {
        self.addBeacon()
    }
    
    // UITextFieldDelegate
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return self.addBeacon()
    }
    
    func addBeacon() -> Bool {
        if let enteredUUID = self.uuidTextField.text, enteredName = self.nameTextField.text, enteredMajor = self.majorTextField.text, enteredMinor = self.minorTextField.text
        where !enteredName.isEmpty && !enteredUUID.isEmpty && !enteredMinor.isEmpty && !enteredMajor.isEmpty {
            if let uuid = NSUUID(UUIDString:enteredUUID) {
                if let minor = Int(enteredMinor), major = Int(enteredMajor) where minor < 65536 && major < 65536 {
                    PeripheralStore.addBeaconConfig(enteredName, config:[UInt16(minor), UInt16(major)])
                    PeripheralStore.addBeacon(enteredName, uuid:uuid)
                    if let beaconName = self.beaconName {
                        if self.beaconName != enteredName {
                            PeripheralStore.removeBeacon(beaconName)
                            PeripheralStore.removeBeaconConfig(beaconName)
                        }
                    }
                    self.navigationController?.popViewControllerAnimated(true)
                    return true

                } else {
                    self.presentViewController(UIAlertController.alertOnErrorWithMessage("major or minor not convertable to a number"), animated:true, completion:nil)
                    return false
                }
            } else {
                self.presentViewController(UIAlertController.alertOnErrorWithMessage("UUID '\(enteredUUID)' is Invalid"), animated:true, completion:nil)
                return false
            }
        } else {
            return false
        }
    }

}
