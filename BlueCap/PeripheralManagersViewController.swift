//
//  PeripheralManagersViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/10/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import UIKit
import BlueCapKit

class PeripheralManagersViewController : UITableViewController {
   
    struct MainStoryboard {
        static let peripheralManagerCell    = "PeripheralManagerCell"
        static let peripheralManagerView    = "PeripheralManagerView"
        static let peripheralManagerAdd     = "PeripheralManagerAdd"
    }
    
    required init(coder aDecoder: NSCoder!) {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated:Bool) {
        super.viewWillAppear(animated)
    }
    
    override func prepareForSegue(segue:UIStoryboardSegue!, sender:AnyObject!) {
        if segue.identifier == MainStoryboard.peripheralManagerView {
            let selectedIndex = self.tableView.indexPathForCell(sender as UITableViewCell)
            let viewController = segue.destinationViewController as PeripheralManagerViewController
            let peripherals = PeripheralStore.getPeripherals()
            viewController.peripheral = peripherals[selectedIndex.row]
        } else if segue.identifier == MainStoryboard.peripheralManagerAdd {            
        }
    }
    
    // UITableViewDataSource
    override func numberOfSectionsInTableView(tableView:UITableView!) -> Int {
        return 1
    }
    
    override func tableView(_:UITableView!, numberOfRowsInSection section:Int) -> Int {
        return PeripheralStore.getPeripherals().count
    }
    
    override func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath:NSIndexPath!) -> UITableViewCell! {
        let cell = tableView.dequeueReusableCellWithIdentifier(MainStoryboard.peripheralManagerCell, forIndexPath: indexPath) as UITableViewCell
        let peripherals = PeripheralStore.getPeripherals()
        cell.textLabel.text = peripherals[indexPath.row]
        return cell
    }

}
