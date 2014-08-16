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
    
    struct MainStoryboard {
        static let peripheralManagerServicesSegue = "PeripheralManagerServices"
    }
    
    @IBOutlet var nameTextField         : UITextField!
    @IBOutlet var advertiseButton       : UIButton!
    
    var peripheral : String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let peripheral = self.peripheral {
            self.nameTextField.text = peripheral
        }
    }
    
    override func viewWillAppear(animated:Bool) {
        super.viewWillAppear(animated)
        self.navigationItem.title = "Peripheral"
        PeripheralManager.sharedInstance().powerOn({
                self.setAdvertiseButtonlabel()
            }, afterPowerOff:{
                self.setAdvertiseButtonlabel()
            })
    }

    override func viewWillDisappear(animated: Bool) {
        self.navigationItem.title = ""
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func prepareForSegue(segue:UIStoryboardSegue!, sender:AnyObject!) {
        if segue.identifier == MainStoryboard.peripheralManagerServicesSegue {
        }
    }
    
    override func shouldPerformSegueWithIdentifier(identifier:String!, sender:AnyObject!) -> Bool {
        if identifier == MainStoryboard.peripheralManagerServicesSegue {
            let manager = PeripheralManager.sharedInstance()
            return manager.isPoweredOn && !manager.isAdvertising
        } else {
            return true
        }
    }

    @IBAction func toggleAdvertise(sender:AnyObject) {
        let manager = PeripheralManager.sharedInstance()
        if manager.isAdvertising {
            manager.stopAdvertising(){
                self.setAdvertiseButtonlabel()
            }
        } else {
            manager.startAdvertising(self.nameTextField.text, afterAdvertisingStartedSuccess:{
                    self.setAdvertiseButtonlabel()
                }, afterAdvertisingStartFailed:{(error) in
                    self.setAdvertiseButtonlabel()
                })
        }
    }

    func setAdvertiseButtonlabel() {
        if self.nameTextField.text != "" {
            self.advertiseButton.enabled = true
            let peripheralManager = PeripheralManager.sharedInstance()
            if peripheralManager.isAdvertising {
                self.advertiseButton.setTitle("Stop Advertising", forState:.Normal)
                self.advertiseButton.setTitleColor(UIColor(red:0.7, green:0.1, blue:0.1, alpha:1.0), forState:.Normal)
                self.navigationItem.setHidesBackButton(true, animated:true)
            } else {
                self.advertiseButton.setTitle("Start Advertising", forState:.Normal)
                self.advertiseButton.setTitleColor(UIColor(red:0.1, green:0.7, blue:0.1, alpha:1.0), forState:.Normal)
                self.navigationItem.setHidesBackButton(false, animated:true)
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
            self.setAdvertiseButtonlabel()
        }
        return true
    }

}
