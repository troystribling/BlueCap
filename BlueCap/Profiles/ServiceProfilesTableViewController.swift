//
//  ServiceProfilesTableViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/12/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import UIKit
import BlueCapKit
import CoreBluetooth

class ServiceProfilesTableViewController : UITableViewController {
    
    var serviceProfiles : Dictionary<String, [ServiceProfile]> = [:]

    var excludedServices : Array<CBUUID> {
        return []
    }
    
    var serviceProfileCell : String {
        return ""
    }
    
    required init(coder aDecoder:NSCoder)  {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.sortServiceProfiles()
    }
    
    override func viewWillAppear(animated:Bool) {
        super.viewWillAppear(animated)
    }
    
    func sortServiceProfiles() {
        for profile in ProfileManager.sharedInstance.services {
            if !contains(self.excludedServices, profile.uuid) {
                if let profiles = self.serviceProfiles[profile.tag] {
                    self.serviceProfiles[profile.tag] = profiles + [profile]
                } else {
                    self.serviceProfiles[profile.tag] = [profile]
                }
            }
        }
    }
    
    // UITableViewDataSource
    override func numberOfSectionsInTableView(tableView:UITableView) -> Int {
        return self.serviceProfiles.count
    }
    
    override func tableView(_:UITableView, numberOfRowsInSection section:Int) -> Int {
        let tags = self.serviceProfiles.keys.array
        if let profiles = self.serviceProfiles[tags[section]] {
            return profiles.count
        } else {
            return 0
        }
    }
    
    override func tableView(tableView:UITableView, titleForHeaderInSection section:Int) -> String? {
        let tags = self.serviceProfiles.keys.array
        return tags[section]
    }
    
    override func tableView(tableView:UITableView, cellForRowAtIndexPath indexPath:NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(self.serviceProfileCell, forIndexPath: indexPath) as NameUUIDCell
        let tags = self.serviceProfiles.keys.array
        if let profiles = self.serviceProfiles[tags[indexPath.section]] {
            let profile = profiles[indexPath.row]
            cell.nameLabel.text = profile.name
            cell.uuidLabel.text = profile.uuid.UUIDString
        } else {
            cell.nameLabel.text = "Unknown"
            cell.uuidLabel.text = "Unknown"
        }
        return cell
    }
    
}
