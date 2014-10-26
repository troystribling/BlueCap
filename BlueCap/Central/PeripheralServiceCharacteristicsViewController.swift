//
//  PeripheralServiceCharacteristicsViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/23/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import UIKit
import BlueCapKit

class PeripheralServiceCharacteristicsViewController : UITableViewController {
 
    weak var service    : Service?
    var progressView    = ProgressView()
    var hasDisconnected = false
    var hasUpdated      = false
    
    struct MainStoryboard {
        static let peripheralServiceCharacteristicCell  = "PeripheralServiceCharacteristicCell"
        static let peripheralServiceCharacteristicSegue = "PeripheralServiceCharacteristic"
    }
    
    required init(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
    }
 
    override func viewDidLoad() {
        super.viewDidLoad()
        if let service = self.service {
            self.hasUpdated = false
            self.hasDisconnected = false
            self.navigationItem.title = service.name
            self.progressView.show()
            service.discoverAllCharacteristics({
                    self.hasUpdated = true
                    self.tableView.reloadData()
                    self.progressView.remove()},
                characteristicDiscoveryFailedCallback:{(error) in
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
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"peripheralDisconnected", name:BlueCapNotification.peripheralDisconnected, object:self.service?.peripheral)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"didBecomeActive", name:BlueCapNotification.didBecomeActive, object:nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"didResignActive", name:BlueCapNotification.didResignActive, object:nil)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    override func prepareForSegue(segue:UIStoryboardSegue, sender:AnyObject!) {
        if segue.identifier == MainStoryboard.peripheralServiceCharacteristicSegue {
            if let service = self.service {
                if let selectedIndex = self.tableView.indexPathForCell(sender as UITableViewCell) {
                    let viewController = segue.destinationViewController as PeripheralServiceCharacteristicViewController
                    viewController.characteristic = service.characteristics[selectedIndex.row]
                }
            }
        }
    }

    override func shouldPerformSegueWithIdentifier(identifier:String?, sender:AnyObject?) -> Bool {
        return !self.hasDisconnected
    }
    
    func peripheralDisconnected() {
        if self.hasDisconnected == false {
            self.hasDisconnected = true
            Logger.debug("PeripheralServiceCharacteristicsViewController#peripheralDisconnected")
            if self.hasUpdated == false {
                self.progressView.remove()
                self.presentViewController(UIAlertController.alertWithMessage("Peripheral disconnected") {(action) in
                    if self.hasUpdated == false {
                        self.navigationController?.popViewControllerAnimated(true)
                        return
                    }
                    }, animated:true, completion:nil)
            }
        }
    }
    
    func didResignActive() {
        self.navigationController?.popToRootViewControllerAnimated(false)
        Logger.debug("PeripheralServiceCharacteristicsViewController#didResignActive")
    }
    
    func didBecomeActive() {
        Logger.debug("PeripheralServiceCharacteristicsViewController#didBecomeActive")
    }

    // UITableViewDataSource
    override func numberOfSectionsInTableView(tableView:UITableView) -> Int {
        return 1
    }
    
    override func tableView(_:UITableView, numberOfRowsInSection section:Int) -> Int {
        if let service = self.service {
            return service.characteristics.count
        } else {
            return 0;
        }
    }
    
    override func tableView(tableView:UITableView, cellForRowAtIndexPath indexPath:NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(MainStoryboard.peripheralServiceCharacteristicCell, forIndexPath: indexPath) as NameUUIDCell
        if let service = self.service {
            let characteristic = service.characteristics[indexPath.row]
            cell.nameLabel.text = characteristic.name
            cell.uuidLabel.text = characteristic.uuid.UUIDString
        }
        return cell
    }
    
    override func tableView(tableView:UITableView, didSelectRowAtIndexPath indexPath:NSIndexPath) {
    }

    // UITableViewDelegate

}
