//
//  ConfigurePeripheralSortOrderViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 2/19/16.
//  Copyright © 2016 Troy Stribling. All rights reserved.
//

import UIKit
import BlueCapKit

class ConfigurePeripheralSortOrderViewController: UITableViewController {

    let sortOrders = ["Discovery Date", "RSSI"]

    struct MainStoryboard {
        static let configureScanModeCell = "ConfigureScanModeCell"
    }

    // UITableViewDataSource
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.sortOrders.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(MainStoryboard.configureScanModeCell, forIndexPath: indexPath) as UITableViewCell
        let sortOrderString = sortOrders[indexPath.row]
        cell.textLabel?.text = sortOrderString
        if let sortOrder = PeripheralSortOrder(sortOrderString) where sortOrder == ConfigStore.getPeripheralSortOrder() {
            cell.accessoryType = UITableViewCellAccessoryType.Checkmark
        } else {
            cell.accessoryType = UITableViewCellAccessoryType.None
        }
        return cell
    }

    // UITableViewDelegate
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let sortOrder = self.sortOrders[indexPath.row]
        ConfigStore.setPeripheralSortOrder(PeripheralSortOrder(sortOrder)!)
        self.navigationController?.popViewControllerAnimated(true)
    }
    
}