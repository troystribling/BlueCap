//
//  ServiceProfilesTableViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/12/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import UIKit
import BlueCapKit
import CoreBluetooth

class ServiceProfilesTableViewController : UITableViewController {
    
    var serviceProfiles = [String: [ServiceProfile]]()

    var serviceProfileCell : String {
        return ""
    }
    
    required init?(coder aDecoder:NSCoder)  {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.sortServiceProfiles()
    }
    
    override func viewWillAppear(_ animated:Bool) {
        super.viewWillAppear(animated)
    }
    
    func sortServiceProfiles() {
        for (_, profile) in Singletons.profileManager.services {
            if let profiles = self.serviceProfiles[profile.tag] {
                self.serviceProfiles[profile.tag] = profiles + [profile]
            } else {
                self.serviceProfiles[profile.tag] = [profile]
            }
        }
    }
    
    // UITableViewDataSource
    override func numberOfSections(in tableView:UITableView) -> Int {
        return self.serviceProfiles.count
    }
    
    override func tableView(_:UITableView, numberOfRowsInSection section:Int) -> Int {
        let tags = Array(self.serviceProfiles.keys)
        if let profiles = self.serviceProfiles[tags[section]] {
            return profiles.count
        } else {
            return 0
        }
    }
    
    override func tableView(_ tableView:UITableView, titleForHeaderInSection section:Int) -> String? {
        let tags = Array(self.serviceProfiles.keys)
        return tags[section]
    }
    
    override func tableView(_ tableView:UITableView, cellForRowAt indexPath:IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: self.serviceProfileCell, for: indexPath) as! NameUUIDCell
        let tags = Array(self.serviceProfiles.keys)
        if let profiles = self.serviceProfiles[tags[indexPath.section]] {
            let profile = profiles[indexPath.row]
            cell.nameLabel.text = profile.name
            cell.uuidLabel.text = profile.uuid.uuidString
        } else {
            cell.nameLabel.text = "Unknown"
            cell.uuidLabel.text = "Unknown"
        }
        return cell
    }
    
}
