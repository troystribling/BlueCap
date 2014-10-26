//
//  PeripheralServiceCharacteristicEditValueViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/20/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import UIKit
import BlueCapKit

class PeripheralServiceCharacteristicEditValueViewController : UIViewController, UITextFieldDelegate {
   
    @IBOutlet var valueTextField    : UITextField!
    var characteristic              : Characteristic?
    var valueName                   : String?
    var progressView                = ProgressView()
    
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
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.Bordered, target:nil, action:nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"peripheralDisconnected", name:BlueCapNotification.peripheralDisconnected, object:self.characteristic?.service.peripheral)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"didBecomeActive", name:BlueCapNotification.didBecomeActive, object:nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"didResignActive", name:BlueCapNotification.didResignActive, object:nil)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func peripheralDisconnected() {
        Logger.debug("PeripheralServiceCharacteristicEditValueViewController#peripheralDisconnected")
    }

    func didResignActive() {
        self.navigationController?.popToRootViewControllerAnimated(false)
        Logger.debug("PeripheralServiceCharacteristicEditValueViewController#didResignActive")
    }
    
    func didBecomeActive() {
        Logger.debug("PeripheralServiceCharacteristicEditValueViewController#didBecomeActive")
    }

    // UITextFieldDelegate
    func textFieldShouldReturn(textField: UITextField!) -> Bool {
        if let newValue = self.valueTextField.text {
            if let valueName = self.valueName {
                if !valueName.isEmpty {
                    if let characteristic = self.characteristic {
                        if var values = characteristic.stringValues {
                            values[valueName] = newValue
                            self.progressView.show()
                            characteristic.write(values, afterWriteSuccessCallback: {
                                    self.progressView.remove()
                                    self.navigationController?.popViewControllerAnimated(true)
                                    return
                                }, afterWriteFailedCallback: {(error) in
                                    self.presentViewController(UIAlertController.alertOnError(error) {(action) in
                                            self.navigationController?.popViewControllerAnimated(true)
                                            return
                                        }, animated:true, completion:nil)
                                })
                        }
                    }
                }
            }
        }
        return true
    }

}
