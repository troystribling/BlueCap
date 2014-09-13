//
//  PeripheralViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/16/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import UIKit
import BlueCapKit

class PeripheralViewController : UITableViewController {
    
    weak var peripheral             : Peripheral?
    @IBOutlet var uuidLabel         : UILabel!
    @IBOutlet var rssiLabel         : UILabel!
    
    struct MainStoryBoard {
        static let peripheralServicesSegue          = "PeripheralServices"
        static let peripehralAdvertisementsSegue    = "PeripheralAdvertisements"
    }
    
    required init(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let peripheral = self.peripheral {
            self.navigationItem.title = peripheral.name
            self.rssiLabel.text = "\(peripheral.rssi)"
            if let identifier = peripheral.identifier {
                self.uuidLabel.text = identifier.UUIDString
            } else {
                self.uuidLabel.text = "Unknown"
            }
        }
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.Bordered, target:nil, action:nil)
    }
        
    override func prepareForSegue(segue:UIStoryboardSegue, sender:AnyObject!) {
        if segue.identifier == MainStoryBoard.peripheralServicesSegue {
            let viewController = segue.destinationViewController as PeripheralServicesViewController
            viewController.peripheral = self.peripheral
        } else if segue.identifier == MainStoryBoard.peripehralAdvertisementsSegue {
            let viewController = segue.destinationViewController as PeripheralAdvertisementsViewController
            viewController.peripheral = self.peripheral
        }
    }
    
    // PRIVATE INTERFACE
    
}