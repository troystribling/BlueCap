//
//  PeripheralServiceCharacteristicViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/23/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import UIKit
import BlueCapKit
import CoreBluetooth

class PeripheralServiceCharacteristicViewController : UITableViewController {

    private static var BCPeripheralStateKVOContext = UInt8()

    struct MainStoryboard {
        static let peripheralServiceCharacteristicValueSegue = "PeripheralServiceCharacteristicValues"
        static let peripheralServiceCharacteristicEditWriteOnlyDiscreteValuesSegue = "PeripheralServiceCharacteristicEditWriteOnlyDiscreteValues"
        static let peripheralServiceCharacteristicEditWriteOnlyValueSeque = "PeripheralServiceCharacteristicEditWriteOnlyValue"
    }
    
    weak var characteristic: BCCharacteristic!
    var peripheralViewController: PeripheralViewController!
    
    @IBOutlet var valuesLabel: UILabel!

    @IBOutlet var notifySwitch: UISwitch!
    @IBOutlet var notifyLabel: UILabel!
    
    @IBOutlet var uuidLabel: UILabel!
    @IBOutlet var broadcastingLabel: UILabel!
    @IBOutlet var notifyingLabel: UILabel!
    
    @IBOutlet var propertyBroadcastLabel: UILabel!
    @IBOutlet var propertyReadLabel: UILabel!
    @IBOutlet var propertyWriteWithoutResponseLabel: UILabel!
    @IBOutlet var propertyWriteLabel: UILabel!
    @IBOutlet var propertyNotifyLabel: UILabel!
    @IBOutlet var propertyIndicateLabel: UILabel!
    @IBOutlet var propertyAuthenticatedSignedWritesLabel: UILabel!
    @IBOutlet var propertyExtendedPropertiesLabel: UILabel!
    @IBOutlet var propertyNotifyEncryptionRequiredLabel: UILabel!
    @IBOutlet var propertyIndicateEncryptionRequiredLabel: UILabel!
    
    required init?(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad()  {
        self.navigationItem.title = self.characteristic.name

        self.setUI()
        
        self.uuidLabel.text = self.characteristic.UUID.UUIDString
        self.notifyingLabel.text = self.booleanStringValue(self.characteristic.isNotifying)
        
        self.propertyBroadcastLabel.text = self.booleanStringValue(self.characteristic.propertyEnabled(.Broadcast))
        self.propertyReadLabel.text = self.booleanStringValue(self.characteristic.propertyEnabled(.Read))
        self.propertyWriteWithoutResponseLabel.text = self.booleanStringValue(self.characteristic.propertyEnabled(.WriteWithoutResponse))
        self.propertyWriteLabel.text = self.booleanStringValue(self.characteristic.propertyEnabled(.Write))
        self.propertyNotifyLabel.text = self.booleanStringValue(self.characteristic.propertyEnabled(.Notify))
        self.propertyIndicateLabel.text = self.booleanStringValue(self.characteristic.propertyEnabled(.Indicate))
        self.propertyAuthenticatedSignedWritesLabel.text = self.booleanStringValue(self.characteristic.propertyEnabled(.AuthenticatedSignedWrites))
        self.propertyExtendedPropertiesLabel.text = self.booleanStringValue(self.characteristic.propertyEnabled(.ExtendedProperties))
        self.propertyNotifyEncryptionRequiredLabel.text = self.booleanStringValue(self.characteristic.propertyEnabled(.NotifyEncryptionRequired))
        self.propertyIndicateEncryptionRequiredLabel.text = self.booleanStringValue(self.characteristic.propertyEnabled(.IndicateEncryptionRequired))
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.Plain, target:nil, action:nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.setUI()
        let options = NSKeyValueObservingOptions([.New])
        self.characteristic?.service?.peripheral?.addObserver(self, forKeyPath: "state", options: options, context: &PeripheralServiceCharacteristicViewController.BCPeripheralStateKVOContext)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(PeripheralServiceCharacteristicViewController.didEnterBackground), name: UIApplicationDidEnterBackgroundNotification, object: nil)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        self.characteristic?.service?.peripheral?.removeObserver(self, forKeyPath: "state", context: &PeripheralServiceCharacteristicViewController.BCPeripheralStateKVOContext)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    override func prepareForSegue(segue:UIStoryboardSegue, sender:AnyObject!) {
        if segue.identifier == MainStoryboard.peripheralServiceCharacteristicValueSegue {
            let viewController = segue.destinationViewController as! PeripheralServiceCharacteristicValuesViewController
            viewController.characteristic = self.characteristic
        } else if segue.identifier == MainStoryboard.peripheralServiceCharacteristicEditWriteOnlyDiscreteValuesSegue {
            let viewController = segue.destinationViewController as! PeripheralServiceCharacteristicEditDiscreteValuesViewController
            viewController.characteristic = self.characteristic
        } else if segue.identifier == MainStoryboard.peripheralServiceCharacteristicEditWriteOnlyValueSeque {
            let viewController = segue.destinationViewController as! PeripheralServiceCharacteristicEditValueViewController
            viewController.characteristic = self.characteristic
            viewController.valueName = nil
        }
    }
    
    override func shouldPerformSegueWithIdentifier(identifier: String?, sender: AnyObject?) -> Bool {
        if let _ = identifier {
            return (self.characteristic.propertyEnabled(.Read) || self.characteristic.isNotifying || self.characteristic.propertyEnabled(.Write)) && self.peripheralViewController.peripheralConnected
        } else {
            return false
        }
    }
    
    @IBAction func toggleNotificatons() {
        if self.characteristic.isNotifying {
            let future = self.characteristic.stopNotifying()
            future.onSuccess {_ in
                self.setUI()
                self.characteristic.stopNotificationUpdates()
            }
            future.onFailure {(error) in
                self.notifySwitch.on = false
                self.setUI()
                self.presentViewController(UIAlertController.alertOnError("Stop Notifications Error", error: error), animated: true, completion: nil)
            }
        } else {
            let future = self.characteristic.startNotifying()
            future.onSuccess {_ in
                self.setUI()
            }
            future.onFailure {(error) in
                self.notifySwitch.on = false
                self.setUI()
                self.presentViewController(UIAlertController.alertOnError("Start Notifications Error", error: error), animated: true, completion: nil)
            }
        }
    }
    
    func setUI() {
        if (!self.characteristic.propertyEnabled(.Read) && !self.characteristic.propertyEnabled(.Write) && !self.characteristic.isNotifying) || !self.peripheralViewController.peripheralConnected {
            self.valuesLabel.textColor = UIColor.lightGrayColor()
        } else {
            self.valuesLabel.textColor = UIColor.blackColor()
        }
        if self.peripheralViewController.peripheralConnected &&
            (characteristic.propertyEnabled(.Notify)                     ||
             characteristic.propertyEnabled(.Indicate)                   ||
             characteristic.propertyEnabled(.NotifyEncryptionRequired)   ||
             characteristic.propertyEnabled(.IndicateEncryptionRequired)) {
            self.notifyLabel.textColor = UIColor.blackColor()
            self.notifySwitch.enabled = true
            self.notifySwitch.on = self.characteristic.isNotifying
        } else {
            self.notifyLabel.textColor = UIColor.lightGrayColor()
            self.notifySwitch.enabled = false
            self.notifySwitch.on = false
        }
        self.notifyingLabel.text = self.booleanStringValue(self.characteristic.isNotifying)
    }
    
    func booleanStringValue(value: Bool) -> String {
        return value ? "YES" : "NO"
    }
    
    func peripheralDisconnected() {
        BCLogger.debug()
        if self.peripheralViewController.peripheralConnected {
            self.presentViewController(UIAlertController.alertWithMessage("Peripheral disconnected") {(action) in
                    self.peripheralViewController.peripheralConnected = false
                    self.setUI()
                }, animated: true, completion: nil)
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
        case("state", &PeripheralServiceCharacteristicViewController.BCPeripheralStateKVOContext):
            if let change = change, newValue = change[NSKeyValueChangeNewKey], newRawState = newValue as? Int, newState = CBPeripheralState(rawValue: newRawState) {
                if newState == .Disconnected {
                    dispatch_async(dispatch_get_main_queue()) { self.peripheralDisconnected() }
                }
            }
        default:
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.row == 0 {
            if self.characteristic.propertyEnabled(.Read) || self.characteristic.isNotifying  {
                self.performSegueWithIdentifier(MainStoryboard.peripheralServiceCharacteristicValueSegue, sender: indexPath)
            } else if (self.characteristic.propertyEnabled(.Write) || self.characteristic.propertyEnabled(.WriteWithoutResponse)) && !self.characteristic.propertyEnabled(.Read) {
                if self.characteristic.stringValues.isEmpty {
                    self.performSegueWithIdentifier(MainStoryboard.peripheralServiceCharacteristicEditWriteOnlyValueSeque, sender: indexPath)
                } else {
                    self.performSegueWithIdentifier(MainStoryboard.peripheralServiceCharacteristicEditWriteOnlyDiscreteValuesSegue, sender: indexPath)
                }
            }
        }
    }

}
