//
//  PeripheralServiceCharacteristicEditValueViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/20/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import UIKit
import BlueCapKit
import CoreBluetooth

class PeripheralServiceCharacteristicEditValueViewController : UIViewController, UITextFieldDelegate {

    private static var BCPeripheralStateKVOContext = UInt8()

    @IBOutlet var valueTextField: UITextField!
    var characteristic: BCCharacteristic!
    var peripheralViewController: PeripheralViewController?
    var valueName: String?
    
    var progressView = ProgressView()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if let valueName = self.valueName {
            self.navigationItem.title = valueName
            if let value = self.characteristic.stringValue?[valueName] {
                self.valueTextField.text = value
            }
        }
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        let options = NSKeyValueObservingOptions([.New])
        self.characteristic?.service?.peripheral?.addObserver(self, forKeyPath: "state", options: options, context: &PeripheralServiceCharacteristicEditValueViewController.BCPeripheralStateKVOContext)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(PeripheralServiceCharacteristicEditValueViewController.didEnterBackground), name: UIApplicationDidEnterBackgroundNotification, object: nil)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        self.characteristic?.service?.peripheral?.removeObserver(self, forKeyPath: "state", context: &PeripheralServiceCharacteristicEditValueViewController.BCPeripheralStateKVOContext)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func peripheralDisconnected() {
        BCLogger.debug()
        if let peripheralViewController = self.peripheralViewController {
            if peripheralViewController.peripheralConnected {
                self.presentViewController(UIAlertController.alertWithMessage("Peripheral disconnected") { action in
                        peripheralViewController.peripheralConnected = false
                        self.navigationController?.popViewControllerAnimated(true)
                    }, animated:true, completion:nil)
            }
        }
    }

    func didEnterBackground() {
        self.navigationController?.popToRootViewControllerAnimated(false)
        BCLogger.debug()
    }

    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String: AnyObject]?, context: UnsafeMutablePointer<Void>) {
        guard keyPath != nil else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
            return
        }
        switch (keyPath!, context) {
        case("state", &PeripheralServiceCharacteristicEditValueViewController.BCPeripheralStateKVOContext):
            if let change = change, newValue = change[NSKeyValueChangeNewKey], newRawState = newValue as? Int, newState = CBPeripheralState(rawValue: newRawState) {
                if newState == .Disconnected {
                    dispatch_async(dispatch_get_main_queue()) { self.peripheralDisconnected() }
                }
            }
        default:
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }

    // UITextFieldDelegate
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if let newValue = self.valueTextField.text {
            let afterWriteSuceses = { (characteristic: BCCharacteristic) -> Void in
                self.progressView.remove()
                self.navigationController?.popViewControllerAnimated(true)
                return
            }
            let afterWriteFailed = { (error: NSError) -> Void in
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
                    let write = characteristic.writeString(values, timeout: Double(ConfigStore.getCharacteristicReadWriteTimeout()))
                    write.onSuccess(afterWriteSuceses)
                    write.onFailure(afterWriteFailed)
                } else {
                    let write = characteristic.writeData(newValue.dataFromHexString(), timeout: Double(ConfigStore.getCharacteristicReadWriteTimeout()))
                    write.onSuccess(afterWriteSuceses)
                    write.onFailure(afterWriteFailed)
                }
            } else {
                BCLogger.debug("VALUE: \(newValue.dataFromHexString())")
                let write = characteristic.writeData(newValue.dataFromHexString(), timeout:Double(ConfigStore.getCharacteristicReadWriteTimeout()))
                write.onSuccess(afterWriteSuceses)
                write.onFailure(afterWriteFailed)
            }
        }
        return true
    }

}
