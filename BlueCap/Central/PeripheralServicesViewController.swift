//
//  PeripheralServicesViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/22/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import UIKit
import BlueCapKit

class PeripheralServicesViewController : UITableViewController {
    
    weak var peripheral : Peripheral?
    var progressView    = ProgressView()
    var hasDisconnected = false
    var hasUpdated      = false
    
    struct MainStoryboard {
        static let peripheralServiceCell            = "PeripheralServiceCell"
        static let peripheralServicesCharacteritics = "PeripheralServicesCharacteritics"
    }
    
    required init(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad()  {
        super.viewDidLoad()
        self.hasUpdated = false
        self.hasDisconnected = false
        if let peripheral = self.peripheral {
            self.progressView.show()
            peripheral.discoverAllServices({
                    self.hasUpdated = true
                    self.tableView.reloadData()
                    self.progressView.remove()},
                serviceDiscoveryFailedCallback:{(error) in
                    self.hasUpdated = true
                    self.progressView.remove()
                    self.presentViewController(UIAlertController.alertOnError(error) {(action) in
                            self.navigationController?.popViewControllerAnimated(true)
                            return
                        }, animated:true, completion:nil)
            })
        }
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.Bordered, target:nil, action:nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"peripheralDisconnected", name:BlueCapNotification.peripheralDisconnected, object:self.peripheral!)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"didBecomeActive", name:BlueCapNotification.didBecomeActive, object:nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"didResignActive", name:BlueCapNotification.didResignActive, object:nil)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func prepareForSegue(segue:UIStoryboardSegue, sender:AnyObject!) {
        if segue.identifier == MainStoryboard.peripheralServicesCharacteritics {
            if let peripheral = self.peripheral {
                if let selectedIndex = self.tableView.indexPathForCell(sender as UITableViewCell) {
                    let viewController = segue.destinationViewController as PeripheralServiceCharacteristicsViewController
                    viewController.service = peripheral.services[selectedIndex.row]
                }
            }
        }
    }
    
    override func shouldPerformSegueWithIdentifier(identifier:String?, sender:AnyObject?) -> Bool {
        return !self.hasDisconnected
    }
    
    func peripheralDisconnected() {
        if self.hasDisconnected == false {
            Logger.debug("PeripheralServicesViewController#peripheralDisconnected")
            self.hasDisconnected = true
            self.progressView.remove()
            self.presentViewController(UIAlertController.alertWithMessage("Peripheral disconnected") {(action) in
                    if self.hasUpdated == false {
                        self.navigationController?.popViewControllerAnimated(true)
                        return
                    }
                }, animated:true, completion:nil)
        }
    }

    func didResignActive() {
        Logger.debug("PeripheralServicesViewController#didResignActive")
        self.navigationController?.popToRootViewControllerAnimated(false)
    }
    
    func didBecomeActive() {
        Logger.debug("PeripheralServicesViewController#didBecomeActive")
    }

    // UITableViewDataSource
    override func numberOfSectionsInTableView(tableView:UITableView) -> Int {
        return 1
    }
    
    override func tableView(_:UITableView, numberOfRowsInSection section:Int) -> Int {
        if let peripheral = self.peripheral {
            return peripheral.services.count
        } else {
            return 0;
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(MainStoryboard.peripheralServiceCell, forIndexPath: indexPath) as NameUUIDCell
        if let peripheral = self.peripheral {
            if peripheral.services.count >= indexPath.row {
                let service = peripheral.services[indexPath.row]
                cell.nameLabel.text = service.name
                cell.uuidLabel.text = service.uuid.UUIDString
            }
        }
        return cell
    }
    
    override func tableView(tableView:UITableView, didSelectRowAtIndexPath indexPath:NSIndexPath) {
    }
    
    // UITableViewDelegate
    
}
