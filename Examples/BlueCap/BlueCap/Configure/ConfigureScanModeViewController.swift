//
//  ConfigureScanModeViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/29/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import UIKit
import BlueCapKit

class ConfigureScanModeViewController: UITableViewController {
    
    let scanModes = ["Promiscuous", "Service"]
    
    struct MainStoryboard {
        static let configureScanModeCell = "ConfigureScanModeCell"
    }

    // UITableViewDataSource
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.scanModes.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(MainStoryboard.configureScanModeCell, forIndexPath: indexPath) as UITableViewCell
        let scanModeString = scanModes[indexPath.row]
        cell.textLabel?.text = scanModeString
        if let scanMode = ServiceScanMode(scanModeString) where scanMode == ConfigStore.getScanMode() {
            cell.accessoryType = UITableViewCellAccessoryType.Checkmark
        } else {
            cell.accessoryType = UITableViewCellAccessoryType.None
        }
        return cell
    }
    
    // UITableViewDelegate
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let scanMode = self.scanModes[indexPath.row]
        ConfigStore.setScanMode(ServiceScanMode(scanMode)!)
        self.navigationController?.popViewControllerAnimated(true)
    }

}