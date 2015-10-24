//
//  PeripheralServiceCharacteristicEditValueViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/20/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import UIKit
import BlueCapKit

class PeripheralServiceCharacteristicEditValueViewController : UIViewController, UITextFieldDelegate {
   
    @IBOutlet var valueTextField    : UITextField!
    var characteristic              : Characteristic!
    var peripheralViewController    : PeripheralViewController?
    var valueName                   : String?
    
    var progressView                = ProgressView()
    
    required init?(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if let valueName = self.valueName {
            self.navigationItem.title = valueName
            if let value = self.characteristic.stringValue?[valueName] {
                self.valueTextField.text = value
            }
        }
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.Plain, target:nil, action:nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"peripheralDisconnected", name:BlueCapNotification.peripheralDisconnected, object:self.characteristic.service.peripheral)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"didBecomeActive", name:BlueCapNotification.didBecomeActive, object:nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"didResignActive", name:BlueCapNotification.didResignActive, object:nil)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func peripheralDisconnected() {
        Logger.debug()
        if let peripheralViewController = self.peripheralViewController {
            if peripheralViewController.peripehealConnected {
                self.presentViewController(UIAlertController.alertWithMessage("Peripheral disconnected") {(action) in
                        peripheralViewController.peripehealConnected = false
                        self.navigationController?.popViewControllerAnimated(true)
                    }, animated:true, completion:nil)
            }
        }
    }

    func didResignActive() {
        self.navigationController?.popToRootViewControllerAnimated(false)
        Logger.debug()
    }
    
    func didBecomeActive() {
        Logger.debug()
    }

    // UITextFieldDelegate
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if let newValue = self.valueTextField.text {
            let afterWriteSuceses = {(characteristic:Characteristic) -> Void in
                self.progressView.remove()
                self.navigationController?.popViewControllerAnimated(true)
                return
            }
            let afterWriteFailed = {(error:NSError) -> Void in
                self.progressView.remove()
                self.presentViewController(UIAlertController.alertOnError("Characteristic Write Error", error:error) {(action) in
                    self.navigationController?.popViewControllerAnimated(true)
                        return
                    } , animated:true, completion:nil)
            }
            self.progressView.show()
            if let valueName = self.valueName {
                if var values = self.characteristic.stringValue {
                    values[valueName] = newValue
                    let write = characteristic.writeString(values, timeout:Double(ConfigStore.getCharacteristicReadWriteTimeout()))
                    write.onSuccess(afterWriteSuceses)
                    write.onFailure(afterWriteFailed)
                } else {
                    let write = characteristic.writeData(newValue.dataFromHexString(), timeout:Double(ConfigStore.getCharacteristicReadWriteTimeout()))
                    write.onSuccess(afterWriteSuceses)
                    write.onFailure(afterWriteFailed)
                }
            } else {
                Logger.debug("VALUE: \(newValue.dataFromHexString())")
                let write = characteristic.writeData(newValue.dataFromHexString(), timeout:Double(ConfigStore.getCharacteristicReadWriteTimeout()))
                write.onSuccess(afterWriteSuceses)
                write.onFailure(afterWriteFailed)
            }
        }
        return true
    }

}
