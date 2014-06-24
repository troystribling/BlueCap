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

    weak var characteristic                                 : Characteristic?
    
    @IBOutlet var notifiyButton                             : UIButton
    @IBOutlet var uuidLabel                                 : UILabel
    @IBOutlet var broadcastingLabel                         : UILabel
    @IBOutlet var notifyingLabel                            : UILabel
    
    @IBOutlet var propertyBroadcastLabel                    : UILabel
    @IBOutlet var propertyReadLabel                         : UILabel
    @IBOutlet var propertyWriteWithoutResponseLabel         : UILabel
    @IBOutlet var propertyWriteLabel                        : UILabel
    @IBOutlet var propertyNotifyLabel                       : UILabel
    @IBOutlet var propertyIndicateLabel                     : UILabel
    @IBOutlet var propertyAuthenticatedSignedWritesLabel    : UILabel
    @IBOutlet var propertyExtendedPropertiesLabel           : UILabel
    @IBOutlet var propertyNotifyEncryptionRequiredLabel     : UILabel
    @IBOutlet var propertyIndicateEncryptionRequiredLabel   : UILabel
    
    init(coder aDecoder:NSCoder!) {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad()  {
        if let characteristic = self.characteristic {
            self.navigationItem.title = characteristic.name
            if characteristic.propertyEnabled(.Notify) {
                self.notifiyButton.enabled = true
                self.toggleNotificaton()
            } else {
                self.notifiyButton.enabled = false
            }

            self.uuidLabel.text = characteristic.uuid.UUIDString
            self.notifyingLabel.text = self.booleanStringValue(characteristic.isNotifying)
            self.broadcastingLabel.text = self.booleanStringValue(characteristic.isBroadcasted)
        }
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.Bordered, target:nil, action:nil)
    }
    
    @IBAction func toggleNotificaton() {
        if let characteristic = self.characteristic {
        }
    }
    
    func setNotifyButtonLabel() {
        if let characteristic = self.characteristic {
            if characteristic.isNotifying {
                self.notifiyButton.setTitle("Stop Notifications", forState:.Normal)
                self.notifiyButton.setTitleColor(UIColor.redColor(), forState:.Normal)
            } else {
                self.notifiyButton.setTitle("Start Notifications", forState:.Normal)
                self.notifiyButton.setTitleColor(UIColor.greenColor(), forState:.Normal)
            }
        }
    }
    
    func booleanStringValue(value:Bool) -> String {
        return value ? "YES" : "NO"
    }
}
