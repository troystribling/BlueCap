//
//  PeripheralManagerServiceCharacteristicsViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/19/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import UIKit
import BlueCapKit

class PeripheralManagerServiceCharacteristicsViewController : UITableViewController {
 
    var service : MutableService?
    
    struct MainStoryboard {
        static let peripheralManagerServiceChracteristicCell    = "PeripheralManagerServiceChracteristicCell"
        static let peripheralManagerServiceCharacteristicSegue  = "PeripheralManagerServiceCharacteristic"
    }
    
    required init(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if let service = self.service {
            self.navigationItem.title = service.name
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationItem.title = ""
    }
    
    override func prepareForSegue(segue:UIStoryboardSegue!, sender: AnyObject!) {
        if segue.identifier == MainStoryboard.peripheralManagerServiceCharacteristicSegue {
            if let service = self.service {
                let selectedIntex = self.tableView.indexPathForCell(sender as UITableViewCell)
                let viewController = segue.destinationViewController as PeripheralManagerServiceCharacteristicViewController
                viewController.characteristic = service.characteristics[selectedIntex.row]
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
        let cell = tableView.dequeueReusableCellWithIdentifier(MainStoryboard.peripheralManagerServiceChracteristicCell, forIndexPath: indexPath) as NameUUIDCell
        if let service = self.service {
            let characteristic = service.characteristics[indexPath.row]
            cell.nameLabel.text = characteristic.name
            cell.uuidLabel.text = characteristic.uuid.UUIDString
        }
        return cell
    }

}
