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
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.sortOrders.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MainStoryboard.configureScanModeCell, for: indexPath) as UITableViewCell
        let sortOrderString = sortOrders[(indexPath as NSIndexPath).row]
        cell.textLabel?.text = sortOrderString
        if let sortOrder = PeripheralSortOrder(sortOrderString) , sortOrder == ConfigStore.getPeripheralSortOrder() {
            cell.accessoryType = UITableViewCellAccessoryType.checkmark
        } else {
            cell.accessoryType = UITableViewCellAccessoryType.none
        }
        return cell
    }

    // UITableViewDelegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let sortOrder = self.sortOrders[(indexPath as NSIndexPath).row]
        ConfigStore.setPeripheralSortOrder(PeripheralSortOrder(sortOrder)!)
        _ = self.navigationController?.popViewController(animated: true)
    }
    
}
