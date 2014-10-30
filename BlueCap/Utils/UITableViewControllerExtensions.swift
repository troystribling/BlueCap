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
    func styleNavigationBar() {
        if var titleAttributes = UINavigationBar.appearance().titleTextAttributes {
            titleAttributes[NSFontAttributeName] = UIFont(name:"Thonburi", size:21.0)
            self.navigationController?.navigationBar.titleTextAttributes = titleAttributes
        } else {
            var titleAttributes = [NSObject:AnyObject]()
            titleAttributes[NSFontAttributeName] = UIFont(name:"Thonburi", size:21.0)
            self.navigationController?.navigationBar.titleTextAttributes = titleAttributes
        }
    }
}
