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
            self.navigationItem.title = service.name
            self.progressView.show()
            self.hasUpdated = false
            service.discoverAllCharacteristics({
                    self.tableView.reloadData()
                    self.hasUpdated = true
                    self.progressView.remove()},
                characteristicDiscoveryFailedCallback:{(error) in
                    self.progressView.remove()
                    self.hasUpdated = true
                    self.presentViewController(UIAlertController.alertOnError(error) {(action) in
                            self.updateDidFail()
                        }, animated:true, completion:nil)
                })
        }
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.Bordered, target:nil, action:nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.hasDisconnected = false
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

    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        return self.service?.characteristics.count > 0 && !self.hasDisconnected
    }
    
    func peripheralDisconnected() {
        if self.hasDisconnected == false {
            self.hasDisconnected = true
            Logger.debug("PeripheralServiceCharacteristicsViewController#peripheralDisconnected")
            if self.hasUpdated == false {
                self.disconnectAlert()
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

    func disconnectAlert() {
        self.progressView.remove()
        self.presentViewController(UIAlertController.alertOnErrorWithMessage("Peripheral disconnected") {(action) in
            self.updateDidFail()
            }, animated:true, completion:nil)
    }

    func updateDidFail() {
        self.navigationController?.popToRootViewControllerAnimated(true)
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
        if self.hasDisconnected {
            self.progressView.remove()
            self.presentViewController(UIAlertController.alertOnErrorWithMessage("Peripheral disconnected") {(action) in
                    self.updateDidFail()
                }, animated:true, completion:nil)
        }
    }

    // UITableViewDelegate

}
