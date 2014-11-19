//
//  BeaconRegionViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 9/13/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import UIKit
import BlueCapKit

class BeaconRegionViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet var nameTextField : UITextField!
    @IBOutlet var uuidTextField : UITextField!
    var regionName              : String?
    
    required init(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if let regionName = self.regionName {
            self.navigationItem.title = regionName
            self.nameTextField.text = regionName
            let beacons = BeaconStore.getBeacons()
            if let uuid = beacons[regionName] {
                self.uuidTextField.text = uuid.UUIDString
            }
        }
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"didBecomeActive", name:BlueCapNotification.didBecomeActive, object:nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"didResignActive", name:BlueCapNotification.didResignActive, object:nil)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func didResignActive() {
        Logger.debug("BeaconRegionsViewController#didResignActive")
        self.navigationController?.popToRootViewControllerAnimated(false)
    }
    
    func didBecomeActive() {
        Logger.debug("BeaconRegionsViewController#didBecomeActive")
    }

    // UITextFieldDelegate
    func textFieldShouldReturn(textField: UITextField!) -> Bool {
        self.nameTextField.resignFirstResponder()
        let enteredUUID = self.uuidTextField.text
        let enteredName = self.nameTextField.text
        if enteredName != nil && enteredUUID != nil  {
            if !enteredName!.isEmpty && !enteredUUID!.isEmpty {
                if let uuid = NSUUID(UUIDString:enteredUUID) {
                    BeaconStore.addBeacon(enteredName!, uuid:uuid)
                    if let regionName = self.regionName {
                        if regionName != enteredName! {
                            BeaconStore.removeBeacon(regionName)
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
