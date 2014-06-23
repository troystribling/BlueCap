//
//  PeripheralServicesViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/22/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import UIKit
import BlueCapKit

class PeripheralServicesViewController : UITableViewController {
    
    weak var peripheral : Peripheral?
    
    struct MainStoryboard {
        static let peripheralServiceCell = "PeripheralServiceCell"
    }
    
    init(coder aDecoder:NSCoder!) {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad()  {
        super.viewDidLoad()
    }
    
    override func prepareForSegue(segue:UIStoryboardSegue!, sender:AnyObject!) {        
    }
    
    // UITableViewDataSource
    override func numberOfSectionsInTableView(tableView:UITableView!) -> Int {
        return 1
    }
    
    override func tableView(_:UITableView!, numberOfRowsInSection section:Int) -> Int {
        if let peripheral = self.peripheral {
            return peripheral.services.count
        } else {
            return 0;
        }
    }
    
    override func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell! {
        let cell = tableView.dequeueReusableCellWithIdentifier(MainStoryboard.peripheralServiceCell, forIndexPath: indexPath) as PeripheralServiceCell
        if let peripheral = self.peripheral {
            let service = peripheral.services[indexPath.row]
            cell.nameLabel.text = service.name
            cell.uuidLabel.text = service.uuid.UUIDString
        }
        return cell
    }
    
    // UITableViewDelegate
    

}
