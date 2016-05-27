//
//  PeripheralAdvertisementsSolicitedServicesViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 10/18/15.
//  Copyright © 2015 Troy Stribling. All rights reserved.
//

import UIKit
import BlueCapKit

class PeripheralAdvertisementsSolicitedServicesViewController: UITableViewController {

    weak var peripheral: BCPeripheral?
    
    struct MainStoryboard {
        static let peripheralAdvertisementsSolicitedServiceCell = "PeripheralAdvertisementsSolicitedServiceCell"
    }
    
    required init?(coder aDecoder:NSCoder)  {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(PeripheralAdvertisementsSolicitedServicesViewController.didEnterBackground), name: UIApplicationDidEnterBackgroundNotification, object: nil)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func didEnterBackground() {
        self.navigationController?.popToRootViewControllerAnimated(false)
        BCLogger.debug()
    }
    
    // UITableViewDataSource
    override func numberOfSectionsInTableView(tableView:UITableView) -> Int {
        return 1
    }
    
    override func tableView(_:UITableView, numberOfRowsInSection section:Int) -> Int {
        if let services = self.peripheral?.advertisements?.solicitedServiceUUIDs {
            return services.count
        } else {
            return 0;
        }
    }
    
    override func tableView(tableView:UITableView, cellForRowAtIndexPath indexPath:NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(MainStoryboard.peripheralAdvertisementsSolicitedServiceCell, forIndexPath:indexPath)
        if let services = self.peripheral?.advertisements?.solicitedServiceUUIDs {
            let service = services[indexPath.row]
            cell.textLabel?.text = service.UUIDString
        }
        return cell
    }

}
