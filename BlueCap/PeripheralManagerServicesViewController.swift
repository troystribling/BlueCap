//
//  PeripheralManagerServicesViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/12/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import UIKit
import CoreBluetooth
import BlueCapKit

class PeripheralManagerServicesViewController : UITableViewController {
    
    struct MainStoryboard {
        static let peripheralManagerServiceCell             = "PeripheralManagerServiceCell"
        static let peripheralManagerServiceProfilesSegue    = "PeripheralManagerServiceProfiles"
    }
    
    required init(coder aDecoder: NSCoder!) {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated:Bool) {
        super.viewWillAppear(animated)
        self.navigationItem.title = "Services"
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.navigationItem.title = ""
    }
    
    override func prepareForSegue(segue:UIStoryboardSegue!, sender:AnyObject!) {
        if segue.identifier == MainStoryboard.peripheralManagerServiceProfilesSegue {
            let selectedIndex = self.tableView.indexPathForCell(sender as UITableViewCell)
            let viewController = segue.destinationViewController as PeripheralManagerServiceProfilesViewController
            viewController.service = PeripheralManager.sharedInstance().services[selectedIndex.row]
        }
    }
    
    // UITableViewDataSource
    override func numberOfSectionsInTableView(tableView:UITableView!) -> Int {
        return 1
    }
    
    override func tableView(_:UITableView!, numberOfRowsInSection section:Int) -> Int {
        return PeripheralManager.sharedInstance().services.count
    }
    
    override func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath:NSIndexPath!) -> UITableViewCell! {
        let cell = tableView.dequeueReusableCellWithIdentifier(MainStoryboard.peripheralManagerServiceCell, forIndexPath:indexPath) as NameUUIDCell
        let service = PeripheralManager.sharedInstance().services[indexPath.row]
        cell.nameLabel.text = service.name
        cell.uuidLabel.text = service.uuid.UUIDString
        return cell
    }
    
    // UITableViewDelegate

}
