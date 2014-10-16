//
//  PeripheralManagerServiceCharacteristicEditValueViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/20/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import UIKit
import BlueCapKit

class PeripheralManagerServiceCharacteristicEditValueViewController : UIViewController, UITextViewDelegate {
  
    @IBOutlet var valueTextField        : UITextField!
    var characteristic                  : MutableCharacteristic?
    var valueName                       : String?
    var peripheralManagerViewController : PeripheralManagerViewController?

    
    required init(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let valueName = self.valueName {
            self.navigationItem.title = valueName
            if let value = self.characteristic?.stringValues?[valueName] {
                self.valueTextField.text = value
            }
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
        Logger.debug("PeripheralManagerServiceCharacteristicEditValueViewController#didResignActive")
    }
    
    func didBecomeActive() {
        Logger.debug("PeripheralManagerServiceCharacteristicEditValueViewController#didBecomeActive")
    }

    // UITextFieldDelegate
    func textFieldShouldReturn(textField: UITextField!) -> Bool {
        if let newValue = self.valueTextField.text {
            if let valueName = self.valueName {
                if !valueName.isEmpty {
                    if let characteristic = self.characteristic {
                        if var values = characteristic.stringValues {
                            values[valueName] = newValue
                            characteristic.updateValueWithString(values)
                            self.navigationController?.popViewControllerAnimated(true)
                        }
                    }
                }
            }
        }
        return true
    }

}