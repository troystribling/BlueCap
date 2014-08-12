//
//  PeripheralManagerViewController.swift
//  BlueCapUI
//
//  Created by Troy Stribling on 6/5/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import UIKit
import BlueCapKit

class PeripheralManagerViewController : UITableViewController, UITextFieldDelegate {
    
    @IBOutlet var nameTextField         : UITextField!
    @IBOutlet var advertiseButton       : UIButton!
    
    var peripheral : String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setAdvertiseButtonlabel()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @IBAction func toggleAdvertise(sender:AnyObject) {
        self.setAdvertiseButtonlabel()
    }

    func setAdvertiseButtonlabel() {
        if self.nameTextField.text != "" {
            self.advertiseButton.enabled = false
            let peripheralManager = PeripheralManager.sharedInstance()
            if peripheralManager.isAdvertising {
                self.advertiseButton.setTitle("Start Advertising", forState:.Normal)
                self.navigationItem.backBarButtonItem.enabled = true
                self.advertiseButton.setTitleColor(UIColor(red:0.1, green:0.7, blue:0.1, alpha:1.0), forState:.Normal)
            } else {
                self.advertiseButton.setTitle("Stop Advertising", forState:.Normal)
                self.advertiseButton.setTitleColor(UIColor(red:0.7, green:0.1, blue:0.1, alpha:1.0), forState:.Normal)
                self.navigationItem.backBarButtonItem.enabled = false
            }
        } else {
            self.advertiseButton.setTitleColor(UIColor(red:0.1, green:0.7, blue:0.1, alpha:1.0), forState:.Normal)
            self.advertiseButton.enabled = false
        }
    }
    
    // UITextFieldDelegate
    func textFieldShouldReturn(textField: UITextField!) -> Bool {
        self.nameTextField.resignFirstResponder()
        if let enteredName = self.nameTextField.text {
            if enteredName != "" {
                if let oldname = self.peripheral {
                    let services = PeripheralStore.getPeripheralServices(oldname)
                    PeripheralStore.removePeripheral(oldname)
                    PeripheralStore.addPeripheral(enteredName)
                    PeripheralStore.addPeripheralServices(enteredName, services:services)
                    self.peripheral = enteredName
                } else {
                    PeripheralStore.addPeripheral(enteredName)
                }
            }
        }
        return true
    }

}
