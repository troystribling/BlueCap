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
            self.doneBarButtonItem.isEnabled = false
            if let uuid = PeripheralStore.getBeacon(beaconName) {
                self.uuidTextField.text = uuid.uuidString
            }
            let beaconConfig = PeripheralStore.getBeaconConfig(beaconName)
            self.minorTextField.text = "\(beaconConfig[0])"
            self.majorTextField.text = "\(beaconConfig[1])"
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector:#selector(PeripheralManagerBeaconViewController.didEnterBackground), name: NSNotification.Name.UIApplicationDidEnterBackground, object:nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    func didEnterBackground() {
        Logger.debug()
        if let peripheralManagerViewController = self.peripheralManagerViewController {
            _ = self.navigationController?.popToViewController(peripheralManagerViewController, animated:false)
        }
    }
    
    @IBAction func generateUUID(_ sender: AnyObject) {
        self.uuidTextField.text = UUID().uuidString
        let enteredName = self.nameTextField.text
        let enteredMajor = self.majorTextField.text
        let enteredMinor = self.minorTextField.text
        if enteredName != nil && enteredMinor != nil && enteredMinor != nil {
            if !enteredName!.isEmpty && !enteredMinor!.isEmpty && !enteredMajor!.isEmpty {
                self.doneBarButtonItem.isEnabled = true
            }
        }
    }
    
    @IBAction func done(_ sender:AnyObject) {
        _ = self.addBeacon()
    }
    
    // UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return self.addBeacon()
    }
    
    func addBeacon() -> Bool {
        if let enteredUUID = self.uuidTextField.text, let enteredName = self.nameTextField.text, let enteredMajor = self.majorTextField.text, let enteredMinor = self.minorTextField.text
        , !enteredName.isEmpty && !enteredUUID.isEmpty && !enteredMinor.isEmpty && !enteredMajor.isEmpty {
            if let uuid = UUID(uuidString:enteredUUID) {
                if let minor = Int(enteredMinor), let major = Int(enteredMajor) , minor < 65536 && major < 65536 {
                    PeripheralStore.addBeaconConfig(enteredName, config:[UInt16(minor), UInt16(major)])
                    PeripheralStore.addBeacon(enteredName, uuid:uuid)
                    if let beaconName = self.beaconName {
                        if self.beaconName != enteredName {
                            PeripheralStore.removeBeacon(beaconName)
                            PeripheralStore.removeBeaconConfig(beaconName)
                        }
                    }
                    _ = self.navigationController?.popViewController(animated: true)
                    return true

                } else {
                    self.present(UIAlertController.alertOnErrorWithMessage("major or minor not convertable to a number"), animated:true, completion:nil)
                    return false
                }
            } else {
                self.present(UIAlertController.alertOnErrorWithMessage("UUID '\(enteredUUID)' is Invalid"), animated:true, completion:nil)
                return false
            }
        } else {
            return false
        }
    }

}
