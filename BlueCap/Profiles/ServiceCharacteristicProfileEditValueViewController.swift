//
//  ServiceCharacteristicProfileEditValueViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/7/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import UIKit
import BlueCapKit

class ServiceCharacteristicProfileEditValueViewController : UIViewController, UITextFieldDelegate {
    
    @IBOutlet var valueTextField        : UITextField!
    weak var characteristicProfile      : CharacteristicProfile?
    var valueName                       : String?
    
    var  values : Dictionary<String, String>? {
    if let characteristicProfile = self.characteristicProfile {
        if let initialValue = characteristicProfile.initialValue {
            return characteristicProfile.stringValues(initialValue)
        } else {
            return nil
        }
    } else {
        return nil
        }
    }

    init(coder aDecoder:NSCoder!) {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let valueName = self.valueName {
            self.navigationItem.title = valueName
            if let value = self.values?[valueName] {
                self.valueTextField.text = value
            }
        }
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.Bordered, target:nil, action:nil)
    }
    
    // UITextFieldDelegate
    func textFieldShouldReturn(textField: UITextField!) -> Bool {
        if let newValue = self.valueTextField.text {
            if let valueName = self.valueName {
                if var values = self.values {
                    values[valueName] = newValue
                    if let characteristicProfile  = self.characteristicProfile {
                        characteristicProfile.initialValue = characteristicProfile.dataFromStringValue(values)
                        self.navigationController.popViewControllerAnimated(true)
                    }
                }
            }
        }
        return true
    }
    
}
