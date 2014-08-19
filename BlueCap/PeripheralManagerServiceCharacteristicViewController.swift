//
//  PeripheralManagerServiceCharacteristicViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/19/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import UIkit
import BlueCapKit

class PeripheralManagerServiceCharacteristicViewController : UITableViewController {
    
    var characteristic : MutableCharacteristic?
    
    struct MainStoryboard {
        
    }
    
    required init(coder aDecoder: NSCoder!) {
        super.init(coder:aDecoder)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func performSegueWithIdentifier(identifier: String!, sender: AnyObject!) {
    }
    
}
