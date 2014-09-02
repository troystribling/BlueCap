//
//  ConfigureScanServicesViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/29/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import UIKit
import BlueCapKit
import CoreBluetooth

class ConfigureScanServicesViewController : UITableViewController {
   
    struct MainStoryboard {
        static let configureScanServicesCell            = "ConfigureScanServicesCell"
        static let configureScanServiceProfilesSegue    = "ConfigureScanServiceProfiles"
    }

    required init(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        self.navigationItem.title = "Scanned Services"
        super.viewWillAppear(animated)
        self.tableView.reloadData()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationItem.title = ""
    }

    // UITableViewDataSource
    override func numberOfSectionsInTableView(tableView:UITableView!) -> Int {
        return 1
    }
    
    override func tableView(_:UITableView!, numberOfRowsInSection section:Int) -> Int {
        return ConfigStore.getScannedServices().count
    }
    
    override func tableView(tableView: UITableView!, editingStyleForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.Delete
    }
    
    override func tableView(tableView:UITableView!, commitEditingStyle editingStyle:UITableViewCellEditingStyle, forRowAtIndexPath indexPath:NSIndexPath!) {
        if editingStyle == UITableViewCellEditingStyle.Delete {
            let services = ConfigStore.getScannedServices()
            ConfigStore.removeScannedService(services[indexPath.row])
            self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation:UITableViewRowAnimation.Fade)
        }
    }
    
    override func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath:NSIndexPath!) -> UITableViewCell! {
        let cell = tableView.dequeueReusableCellWithIdentifier(MainStoryboard.configureScanServicesCell, forIndexPath: indexPath) as NameUUIDCell
        let serviceUUID = ConfigStore.getScannedServices()[indexPath.row]
        if let uuidString = serviceUUID.UUIDString {
            cell.uuidLabel.text = uuidString
        } else {
            cell.uuidLabel.text = "Unknown"
        }
        if let serviceProfile = ProfileManager.sharedInstance().service(serviceUUID) {
            cell.nameLabel.text = serviceProfile.name
        } else {
            cell.nameLabel.text = "Unknown"
        }
        return cell
    }
    
    // UITableViewDelegate

}