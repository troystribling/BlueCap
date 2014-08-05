//
//  ServiceCharacteristicProfilesView.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/4/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import UIKit
import BlueCapKit

class ServiceCharacteristicProfilesView : UITableViewController {

    var serviceProfile : ServiceProfile?
    
    struct MainStoryboard {
        static let serviceCharacteristicProfileCell = "ServiceCharacteristicProfileCell"
    }
    
    init(coder aDecoder:NSCoder!)  {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    

    // UITableViewDataSource
    override func numberOfSectionsInTableView(tableView:UITableView!) -> Int {
        return 1
    }
    
    override func tableView(_:UITableView!, numberOfRowsInSection section:Int) -> Int {
        if let serviceProfile = self.serviceProfile {
            return serviceProfile.characteristics.count
        } else {
            return 0
        }
    }
    
    override func tableView(tableView:UITableView!, cellForRowAtIndexPath indexPath:NSIndexPath!) -> UITableViewCell! {
        let cell = tableView.dequeueReusableCellWithIdentifier(MainStoryboard.serviceCharacteristicProfileCell, forIndexPath: indexPath) as NameUUIDCell
        return cell
    }

}