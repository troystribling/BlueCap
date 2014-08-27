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
   
    var progressView    : ProgressView!
    var peripheral      : String?
    
    struct MainStoryboard {
        static let peripheralManagerServiceCell = "PeripheralManagerServiceProfileCell"
    }
    
    override var serviceProfileCell : String {
        return MainStoryboard.peripheralManagerServiceCell
    }

    required init(coder aDecoder: NSCoder) {
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
    
    func updatePripheralStore() {
        if let peripheral = self.peripheral {
            let manager = PeripheralManager.sharedInstance()
            let serviceUUIDs = manager.services.reduce([String]()){(uuids, service) in
                if let uuid = service.uuid.UUIDString {
                    return uuids + [uuid]
                } else {
                    return uuids
                }
            }
            PeripheralStore.addPeripheralServices(peripheral, services:serviceUUIDs)
        }
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
                    self.updatePripheralStore()
                }, afterServiceAddFailed: {(error) in
                    self.presentViewController(UIAlertController.alertOnError(error), animated:true, completion:nil)
                    self.addServiceComplete()
                })
        } else {
            self.navigationController.popViewControllerAnimated(true)
        }
    }

}
