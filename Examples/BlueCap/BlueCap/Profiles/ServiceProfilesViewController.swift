//
//  ServiceProfilesViewController.swift
//  BlueCapUI
//
//  Created by Troy Stribling on 6/5/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import UIKit
import BlueCapKit

class ServiceProfilesViewController : ServiceProfilesTableViewController {
    
    struct MainStoryboard {
        static let serviceProfileCell                   = "ServiceProfileCell"
        static let serviceCharacteristicProfilesSegue   = "ServiceCharacteristicProfiles"
    }
    
    override var serviceProfileCell : String {
        return MainStoryboard.serviceProfileCell
    }
    
    required init?(coder aDecoder:NSCoder)  {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.styleNavigationBar()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationItem.title = "Service Profiles"
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationItem.title = ""
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func prepareForSegue(segue:UIStoryboardSegue, sender:AnyObject!) {
        if segue.identifier == MainStoryboard.serviceCharacteristicProfilesSegue {
            if let selectedIndex = self.tableView.indexPathForCell(sender as! UITableViewCell) {
                let tag = Array(self.serviceProfiles.keys)
                if let profiles = self.serviceProfiles[tag[selectedIndex.section]] {
                    let viewController = segue.destinationViewController as! ServiceCharacteristicProfilesViewController
                    viewController.serviceProfile =  profiles[selectedIndex.row]
                }
            }
        }
    }

}
