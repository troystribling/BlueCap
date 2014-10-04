//
//  PeripheralManagerAdvertisedServicesViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 10/2/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import UIKit

class PeripheralManagerAdvertisedServicesViewController: UITableViewController {

    struct MainStoryboard {
        static let peripheralManagerAddAdvertisedServiceSegue   = "PeripheralManagerAddAdvertisedService"
        static let peripheralManagerAdvertisedServiceCell       = "PeripheralManagerAdvertisedServiceCell"
    }
    
    var peripheral : String?
    
    required init(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationItem.title = "Advertised Services"
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationItem.title = ""
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == MainStoryboard.peripheralManagerAddAdvertisedServiceSegue {            
        }
    }
    
    override func numberOfSectionsInTableView(tableView:UITableView) -> Int {
        return 1
    }

    override func tableView(tableView:UITableView, numberOfRowsInSection section:Int) -> Int {
        return 0
    }

    override func tableView(tableView:UITableView, cellForRowAtIndexPath indexPath:NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(MainStoryboard.peripheralManagerAdvertisedServiceCell, forIndexPath: indexPath) as NameUUIDCell
        return cell
    }

    override func tableView(tableView:UITableView, canEditRowAtIndexPath indexPath:NSIndexPath) -> Bool {
        return true
    }

    override func tableView(tableView:UITableView, commitEditingStyle editingStyle:UITableViewCellEditingStyle, forRowAtIndexPath indexPath:NSIndexPath) {
        if editingStyle == .Delete {
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        }
    }

}
