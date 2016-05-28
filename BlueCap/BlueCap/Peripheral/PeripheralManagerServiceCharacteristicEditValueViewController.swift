//
//  PeripheralManagerServiceCharacteristicEditValueViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/20/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import UIKit
import BlueCapKit

class PeripheralManagerServiceCharacteristicEditValueViewController: UIViewController, UITextViewDelegate {
  
    @IBOutlet var valueTextField: UITextField!
    var characteristic: BCMutableCharacteristic?
    var valueName: String?
    var peripheralManagerViewController: PeripheralManagerViewController?

    
    required init?(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let valueName = self.valueName {
            self.navigationItem.title = valueName
            if let value = self.characteristic?.stringValue?[valueName] {
                self.valueTextField.text = value
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(PeripheralManagerServiceCharacteristicEditValueViewController.didEnterBackground), name: UIApplicationDidEnterBackgroundNotification, object: nil)
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
    
    // UITextFieldDelegate
    func textFieldShouldReturn(textField: UITextField!) -> Bool {
        if let newValue = self.valueTextField.text,
            valueName = self.valueName,
            characteristic = self.characteristic  where !valueName.isEmpty {
            if var values = characteristic.stringValue {
                values[valueName] = newValue
                characteristic.updateValueWithString(values)
                self.navigationController?.popViewControllerAnimated(true)
            }
        }
        return true
    }

}