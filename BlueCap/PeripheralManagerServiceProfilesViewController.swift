//
//  PeripheralManagerServiceProfilesViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/12/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import UIKit
import BlueCapKit

class PeripheralManagerServiceProfilesViewController : ServiceProfilesTableViewController {
   
    var progressView : ProgressView!
    
    struct MainStoryboard {
        static let peripheralManagerServiceCell = "PeripheralManagerServiceProfileCell"
    }
    
    override var serviceProfileCell : String {
        return MainStoryboard.peripheralManagerServiceCell
    }

    required init(coder aDecoder: NSCoder!) {
        super.init(coder:aDecoder)
        self.progressView = ProgressView()
    }
    
    override func viewWillAppear(animated:Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(animated: Bool) {
    }
    
    func addServiceComplete() {
        self.navigationController.popViewControllerAnimated(true)
        self.progressView.remove()
    }
            
    // UITableViewDelegate
    override func tableView(tableView:UITableView!, didSelectRowAtIndexPath indexPath:NSIndexPath!) {
        let tags = Array(self.serviceProfiles.keys)
        if let profiles = self.serviceProfiles[tags[indexPath.section]] {
            let serviceProfile = profiles[indexPath.row]
            let service = MutableService(profile:serviceProfile)
            service.characteristicsFromProfiles(serviceProfile.characteristics)
            self.progressView.show()
            PeripheralManager.sharedInstance().addService(service, afterServiceAddSuccess:{
                    self.addServiceComplete()
                }, afterServiceAddFailed: {(error) in
                    self.presentViewController(UIAlertController.alertOnError(error), animated:true, completion:nil)
                    self.addServiceComplete()
                })
        } else {
            self.navigationController.popViewControllerAnimated(true)
        }
    }

}
