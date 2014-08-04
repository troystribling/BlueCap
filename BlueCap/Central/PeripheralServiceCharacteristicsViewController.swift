//
//  PeripheralServiceCharacteristicsViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/23/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import UIKit
import BlueCapKit

class PeripheralServiceCharacteristicsViewController : UITableViewController {
 
    weak var service : Service?
    
    struct MainStoryboard {
        static let peripheralServiceCharacteristicCell  = "PeripheralServiceCharacteristicCell"
        static let peripheralServiceCharacteristicSegue = "PeripheralServiceCharacteristic"
    }
    
    init(coder aDecoder:NSCoder!) {
        super.init(coder:aDecoder)
    }
 
    override func viewDidLoad() {
        super.viewDidLoad()
        if let service = self.service {
            self.navigationItem.title = service.name
            service.discoverAllCharacteristics(){self.tableView.reloadData()}
        }
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.Bordered, target:nil, action:nil)
    }
    
    override func prepareForSegue(segue:UIStoryboardSegue!, sender:AnyObject!) {
        if segue.identifier == MainStoryboard.peripheralServiceCharacteristicSegue {
            if let service = self.service {
                let selectedIndex = self.tableView.indexPathForCell(sender as UITableViewCell)
                let viewController = segue.destinationViewController as PeripheralServiceCharacteristicViewController
                viewController.characteristic = service.characteristics[selectedIndex.row]
            }
        }
    }
    
    // UITableViewDataSource
    override func numberOfSectionsInTableView(tableView:UITableView!) -> Int {
        return 1
    }
    
    override func tableView(_:UITableView!, numberOfRowsInSection section:Int) -> Int {
        if let service = self.service {
            return service.characteristics.count
        } else {
            return 0;
        }
    }
    
    override func tableView(tableView:UITableView!, cellForRowAtIndexPath indexPath:NSIndexPath!) -> UITableViewCell! {
        let cell = tableView.dequeueReusableCellWithIdentifier(MainStoryboard.peripheralServiceCharacteristicCell, forIndexPath: indexPath) as NameUUIDCell
        if let service = self.service {
            let characteristic = service.characteristics[indexPath.row]
            cell.nameLabel.text = characteristic.name
            cell.uuidLabel.text = characteristic.uuid.UUIDString
        }
        return cell
    }
    
    // UITableViewDelegate

}
