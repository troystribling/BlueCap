//
//  PeripheralManagerServiceProfilesViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/12/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import UIKit
import BlueCapKit
import CoreBluetooth

class PeripheralManagerServiceProfilesViewController : UITableViewController {
   
    struct MainStoryboard {
        static let peripheralManagerServiceCell = "PeripheralManagerServiceProfileCell"
    }
    
    var service : MutableService?
    
    required init(coder aDecoder: NSCoder!) {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.Bordered, target:nil, action:nil)
    }
    
    override func viewWillAppear(animated:Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(animated: Bool) {
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
        let service = ProfileManager.sharedInstance().services[indexPath.row]
        cell.nameLabel.text = service.name
        cell.uuidLabel.text = service.uuid.UUIDString
        return cell
    }
    
    // UITableViewDelegate
    override func tableView(tableView:UITableView!, didSelectRowAtIndexPath indexPath:NSIndexPath!) {
        if let service = self.service {
            self.navigationController.popViewControllerAnimated(true)
        }
    }

}
