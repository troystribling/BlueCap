//
//  ServiceCharacteristicProfilesViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/4/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import UIKit
import BlueCapKit

class ServiceCharacteristicProfilesViewController : UITableViewController {

    var serviceProfile: BCServiceProfile?
    
    struct MainStoryboard {
        static let serviceCharacteristicProfileCell = "ServiceCharacteristicProfileCell"
        static let serviceCharacteristicProfileSegue = "ServiceCharacteristicProfile"
    }
    
    required init?(coder aDecoder:NSCoder)  {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let serviceProfile = self.serviceProfile {
            self.navigationItem.title = serviceProfile.name
            self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func prepareForSegue(segue:UIStoryboardSegue, sender:AnyObject!) {
        if let serviceProfile = self.serviceProfile {
            if segue.identifier == MainStoryboard.serviceCharacteristicProfileSegue {
                if let selectedIndexPath = self.tableView.indexPathForCell(sender as! UITableViewCell) {
                    let viewController = segue.destinationViewController as! ServiceCharacteristicProfileViewController
                    viewController.characteristicProfile = serviceProfile.characteristics[selectedIndexPath.row]
                }
            }
        }
    }

    // UITableViewDataSource
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let serviceProfile = self.serviceProfile {
            return serviceProfile.characteristics.count
        } else {
            return 0
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(MainStoryboard.serviceCharacteristicProfileCell, forIndexPath: indexPath) as! NameUUIDCell
        if let serviceProfile = self.serviceProfile {
            let characteristicProfile = serviceProfile.characteristics[indexPath.row]
            cell.nameLabel.text = characteristicProfile.name
            cell.uuidLabel.text = characteristicProfile.UUID.UUIDString
        }
        return cell
    }

}