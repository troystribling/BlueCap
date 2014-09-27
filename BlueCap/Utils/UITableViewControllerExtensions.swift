//
//  UITableViewControllerExtensions.swift
//  BlueCap
//
//  Created by Troy Stribling on 9/27/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import UIKit

extension UITableViewController {
    func updateWhenActive() {
        if UIApplication.sharedApplication().applicationState == .Active {
            self.tableView.reloadData()
        }
    }
}
