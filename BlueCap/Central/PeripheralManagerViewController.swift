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
    
    @IBOutlet var nameTextField     : UITextField!
    @IBOutlet var advertiseButton   : UIButton!
    
    var peripheral : String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.Bordered, target:nil, action:nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @IBAction func toggleAdvertise(sender:AnyObject) {
        let peripheralManager = PeripheralManager.sharedInstance()
        if peripheralManager.isAdvertising {
            self.navigationItem.backBarButtonItem.enabled = true
        } else {
            self.navigationItem.backBarButtonItem.enabled = false
        }
    }
    
    // UITextFieldDelegate
    func textFieldShouldReturn(textField: UITextField!) -> Bool {
        if let enteredName = self.nameTextField.text {
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
        return true
    }

}
