//
//  PeripheralAdvertisementsServiceDataViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 10/18/15.
//  Copyright © 2015 Troy Stribling. All rights reserved.
//

import UIKit
import CoreBluetooth
import BlueCapKit

class PeripheralAdvertisementsServiceDataViewController: UITableViewController {

    weak var peripheral: BCPeripheral?
    
    struct MainStoryboard {
        static let peripheralAdvertisementsServiceDataCell = "PeripheralAdvertisementsServiceDataCell"
    }
    
    required init?(coder aDecoder: NSCoder)  {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(PeripheralAdvertisementsServiceDataViewController.didEnterBackground), name: UIApplicationDidEnterBackgroundNotification, object: nil)
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
    
    override func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let services = self.peripheral?.advertisements?.serviceData {
            return services.count
        } else {
            return 0;
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(MainStoryboard.peripheralAdvertisementsServiceDataCell, forIndexPath: indexPath) as! NameUUIDCell
        if let serviceData = self.peripheral?.advertisements?.serviceData {
            let uuids = [CBUUID](serviceData.keys)
            let uuid = uuids[indexPath.row]
            let data = serviceData[uuid]
            cell.uuidLabel.text = uuid.UUIDString
            cell.nameLabel.text = data?.hexStringValue()
        }
        return cell
    }

}
