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
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.scanModes.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MainStoryboard.configureScanModeCell, for: indexPath) as UITableViewCell
        let scanModeString = scanModes[(indexPath as NSIndexPath).row]
        cell.textLabel?.text = scanModeString
        if let scanMode = ServiceScanMode(scanModeString) , scanMode == ConfigStore.getScanMode() {
            cell.accessoryType = UITableViewCellAccessoryType.checkmark
        } else {
            cell.accessoryType = UITableViewCellAccessoryType.none
        }
        return cell
    }
    
    // UITableViewDelegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let scanMode = self.scanModes[(indexPath as NSIndexPath).row]
        ConfigStore.setScanMode(ServiceScanMode(scanMode)!)
        _ = self.navigationController?.popViewController(animated: true)
    }

}
