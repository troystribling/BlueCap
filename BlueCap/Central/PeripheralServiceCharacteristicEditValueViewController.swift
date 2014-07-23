//
//  PeripheralServiceCharacteristicEditValueViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/20/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import UIKit
import BlueCapKit

class PeripheralServiceCharacteristicEditValueViewController : UITableViewController, UITextFieldDelegate {
   
    @IBOutlet var valueTextField    : UITextField
    var characteristic              : Characteristic?
    var valueName                   : String?
    
    init(coder aDecoder:NSCoder!) {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let valueName = self.valueName {
            self.navigationItem.title = self.valueName
            if let value = self.characteristic?.stringValues?[valueName] {
                self.valueTextField.text = value
            }
        }
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.Bordered, target:nil, action:nil)
    }
    
    // UITextFieldDelegate
    func textFieldShouldReturn(textField: UITextField!) -> Bool {
        let value = self.valueTextField.text
        var values = self.characteristic?.stringValues
        let valueName = self.valueName
        if value && values && valueName {
//            values![valueName!] = value!
        }
        return true
    }
    
}
