//
//  ConfigureScanServiceProfilesViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/29/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import UIKit
import CoreBluetooth

class ConfigureScanServiceProfilesViewController :  ServiceProfilesTableViewController {
    
    struct MainStoryboard {
        static let configureScanServiceProfileCell = "ConfigureScanServiceProfileCell"
    }
    
    override var excludedServices : Array<CBUUID> {
        return ConfigStore.getScannedServices()
    }

    override var serviceProfileCell : String {
        return MainStoryboard.configureScanServiceProfileCell
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
    }
    
    override func viewWillAppear(animated:Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(animated: Bool) {
    }
        
    // UITableViewDelegate
    override func tableView(tableView:UITableView, didSelectRowAtIndexPath indexPath:NSIndexPath) {
        let tags = self.serviceProfiles.keys.array
        if let profiles = self.serviceProfiles[tags[indexPath.section]] {
            let serviceProfile = profiles[indexPath.row]
            ConfigStore.addScannedService(serviceProfile.uuid)
            self.navigationController!.popViewControllerAnimated(true)
        }
    }
    
}
