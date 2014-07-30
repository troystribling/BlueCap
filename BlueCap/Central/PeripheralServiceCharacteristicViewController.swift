//
//  PeripheralServiceCharacteristicViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/23/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import UIKit
import BlueCapKit

class PeripheralServiceCharacteristicViewController : UITableViewController {

    struct MainStoryboard {
        static let peripheralServiceCharacteristicValueSegue = "PeripheralServiceCharacteristicValues"
    }
    
    weak var characteristic                                 : Characteristic?
    
    @IBOutlet var valuesLabel                               : UILabel!

    @IBOutlet var notifiyButton                             : UIButton!
    
    @IBOutlet var uuidLabel                                 : UILabel!
    @IBOutlet var broadcastingLabel                         : UILabel!
    @IBOutlet var notifyingLabel                            : UILabel!
    
    @IBOutlet var propertyBroadcastLabel                    : UILabel!
    @IBOutlet var propertyReadLabel                         : UILabel!
    @IBOutlet var propertyWriteWithoutResponseLabel         : UILabel!
    @IBOutlet var propertyWriteLabel                        : UILabel!
    @IBOutlet var propertyNotifyLabel                       : UILabel!
    @IBOutlet var propertyIndicateLabel                     : UILabel!
    @IBOutlet var propertyAuthenticatedSignedWritesLabel    : UILabel!
    @IBOutlet var propertyExtendedPropertiesLabel           : UILabel!
    @IBOutlet var propertyNotifyEncryptionRequiredLabel     : UILabel!
    @IBOutlet var propertyIndicateEncryptionRequiredLabel   : UILabel!
    
    init(coder aDecoder:NSCoder!) {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad()  {
        if let characteristic = self.characteristic {
            self.navigationItem.title = characteristic.name

            if !characteristic.propertyEnabled(.Read) || !characteristic.propertyEnabled(.Notify) {
                self.valuesLabel.textColor = UIColor.lightGrayColor()
            }
            
            if characteristic.propertyEnabled(.Notify) {
                self.notifiyButton.enabled = true
                self.setNotifyButtonLabel()
            } else {
                self.notifiyButton.enabled = false
            }
            
            self.uuidLabel.text = characteristic.uuid.UUIDString
            self.notifyingLabel.text = self.booleanStringValue(characteristic.isNotifying)
            self.broadcastingLabel.text = self.booleanStringValue(characteristic.isBroadcasted)
            
            self.propertyBroadcastLabel.text = self.booleanStringValue(characteristic.propertyEnabled(.Broadcast))
            self.propertyReadLabel.text = self.booleanStringValue(characteristic.propertyEnabled(.Read))
            self.propertyWriteWithoutResponseLabel.text = self.booleanStringValue(characteristic.propertyEnabled(.WriteWithoutResponse))
            self.propertyWriteLabel.text = self.booleanStringValue(characteristic.propertyEnabled(.Write))
            self.propertyNotifyLabel.text = self.booleanStringValue(characteristic.propertyEnabled(.Notify))
            self.propertyIndicateLabel.text = self.booleanStringValue(characteristic.propertyEnabled(.Indicate))
            self.propertyAuthenticatedSignedWritesLabel.text = self.booleanStringValue(characteristic.propertyEnabled(.AuthenticatedSignedWrites))
            self.propertyExtendedPropertiesLabel.text = self.booleanStringValue(characteristic.propertyEnabled(.ExtendedProperties))
            self.propertyNotifyEncryptionRequiredLabel.text = self.booleanStringValue(characteristic.propertyEnabled(.NotifyEncryptionRequired))
            self.propertyIndicateEncryptionRequiredLabel.text = self.booleanStringValue(characteristic.propertyEnabled(.IndicateEncryptionRequired))
        }
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.Bordered, target:nil, action:nil)
    }
    
    override func prepareForSegue(segue:UIStoryboardSegue!, sender:AnyObject!) {
        if segue.identifier == MainStoryboard.peripheralServiceCharacteristicValueSegue {
            let viewController = segue.destinationViewController as PeripheralServiceCharacteristicValuesViewController
            viewController.characteristic = self.characteristic
        }
    }
    
    override func shouldPerformSegueWithIdentifier(identifier:String!, sender:AnyObject!) -> Bool {
        if let characteristic = self.characteristic {
            return characteristic.propertyEnabled(.Read)
        } else {
            return false
        }
    }
    
    @IBAction func toggleNotificatons() {
        if let characteristic = self.characteristic {
            self.notifiyButton.enabled = false
            self.notifiyButton.setTitleColor(UIColor(red:0.7, green:0.7, blue:0.7, alpha:1.0), forState:.Normal)
            if characteristic.isNotifying {
                self.notifiyButton.setTitle("Stopping Notifications", forState:.Normal)
                characteristic.stopNotifying({
                        characteristic.stopUpdates()
                        self.setNotifyButtonLabel()
                    },
                    notificationStateChangedFailedCallback: {(error) in
                        self.presentViewController(UIAlertController.alertOnError(error), animated:true, completion:nil)
                        self.setNotifyButtonLabel()
                    })
            } else {
                self.notifiyButton.setTitle("Starting Notifications", forState:.Normal)
                characteristic.startNotifying({
                    characteristic.startUpdates({
                            self.setNotifyButtonLabel()
                        }, afterUpdateFailedCallback:{(error) in
                            self.presentViewController(UIAlertController.alertOnError(error), animated:true, completion:nil)
                        })
                    },
                    notificationStateChangedFailedCallback:{(error) in
                        self.presentViewController(UIAlertController.alertOnError(error), animated:true, completion:nil)
                        self.setNotifyButtonLabel()
                    })
            }
        }
    }
    
    func setNotifyButtonLabel() {
        if let characteristic = self.characteristic {
            self.notifiyButton.enabled = true
            if characteristic.isNotifying {
                self.notifiyButton.setTitle("Stop Notifications", forState:.Normal)
                self.notifiyButton.setTitleColor(UIColor(red:0.7, green:0.1, blue:0.1, alpha:1.0), forState:.Normal)
            } else {
                self.notifiyButton.setTitle("Start Notifications", forState:.Normal)
                self.notifiyButton.setTitleColor(UIColor(red:0.1, green:0.7, blue:0.1, alpha:1.0), forState:.Normal)
            }
        }
    }
    
    func booleanStringValue(value:Bool) -> String {
        return value ? "YES" : "NO"
    }
}
