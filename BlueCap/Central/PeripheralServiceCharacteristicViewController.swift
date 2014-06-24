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
            self.uuidLabel.text = characteristic.uuid.UUIDString
        }
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.Bordered, target:nil, action:nil)
    }
}
