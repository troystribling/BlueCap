//
//  ConfigureScanModeServiceProfilesViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/29/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import UIKit
import BlueCapKit

class ConfigureScanModeServiceProfilesViewController :  ServiceProfilesTableViewController {
    
    struct MainStoryboard {
        static let configureScanModeServiceProfiles = "ConfigureScanModeServiceProfiles"
    }
    
    override var serviceProfileCell : String {
        return MainStoryboard.configureScanModeServiceProfiles
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
    override func tableView(tableView:UITableView!, didSelectRowAtIndexPath indexPath:NSIndexPath!) {
        let tags = Array(self.serviceProfiles.keys)
        if let profiles = self.serviceProfiles[tags[indexPath.section]] {
            let serviceProfile = profiles[indexPath.row]
            let service = MutableService(profile:serviceProfile)
            service.characteristicsFromProfiles(serviceProfile.characteristics)
        } else {
            self.navigationController.popViewControllerAnimated(true)
        }
    }
    
}
