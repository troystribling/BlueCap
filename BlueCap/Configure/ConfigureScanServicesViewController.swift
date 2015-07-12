//
//  ConfigureScanServicesViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/29/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import UIKit
import BlueCapKit
import CoreBluetooth

class ConfigureScanServicesViewController : UITableViewController {
   
    struct MainStoryboard {
        static let configureScanServicesCell            = "ConfigureScanServicesCell"
        static let configureAddScanServiceSegue         = "ConfigureAddScanService"
        static let configureEditScanServiceSegue        = "ConfigureEditScanService"
    }

    required init?(coder aDecoder:NSCoder) {
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
    
    override func prepareForSegue(segue:UIStoryboardSegue, sender:AnyObject?) {
        if segue.identifier == MainStoryboard.configureAddScanServiceSegue {
        } else if segue.identifier == MainStoryboard.configureEditScanServiceSegue {
            if let selectedIndexPath = self.tableView.indexPathForCell(sender as! UITableViewCell) {
                let names = ConfigStore.getScannedServiceNames()
                let viewController = segue.destinationViewController as! ConfigureScanServiceViewController
                viewController.serviceName = names[selectedIndexPath.row]
            }
        }
    }

    // UITableViewDataSource
    override func numberOfSectionsInTableView(tableView:UITableView) -> Int {
        return 1
    }
    
    override func tableView(_:UITableView, numberOfRowsInSection section:Int) -> Int {
        return ConfigStore.getScannedServices().count
    }
    
    override func tableView(tableView:UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.Delete
    }
    
    override func tableView(tableView:UITableView, commitEditingStyle editingStyle:UITableViewCellEditingStyle, forRowAtIndexPath indexPath:NSIndexPath) {
        if editingStyle == UITableViewCellEditingStyle.Delete {
            let names = ConfigStore.getScannedServiceNames()
            ConfigStore.removeScannedService(names[indexPath.row])
            self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation:UITableViewRowAnimation.Fade)
        }
    }
    
    override func tableView(tableView:UITableView, cellForRowAtIndexPath indexPath:NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(MainStoryboard.configureScanServicesCell, forIndexPath: indexPath) as! NameUUIDCell
        let names = ConfigStore.getScannedServiceNames()
        if let serviceUUID = ConfigStore.getScannedServiceUUID(names[indexPath.row]) {
            cell.uuidLabel.text = serviceUUID.UUIDString
        } else {
            cell.uuidLabel.text = "Unknown"
        }
        cell.nameLabel.text = names[indexPath.row]
        return cell
    }
    
    // UITableViewDelegate

}