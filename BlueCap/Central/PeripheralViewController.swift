//
//  PeripheralViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/16/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import UIKit
import BlueCapKit

class PeripheralViewController : UITableViewController {
    
    weak var peripheral             : Peripheral!
    var progressView                = ProgressView()
    var peripehealConnected         = true
    var hasData                     = false
    
    @IBOutlet var uuidLabel         : UILabel!
    @IBOutlet var rssiLabel         : UILabel!
    @IBOutlet var stateLabel        : UILabel!
    @IBOutlet var serviceLabel      : UILabel!
    
    struct MainStoryBoard {
        static let peripheralServicesSegue          = "PeripheralServices"
        static let peripehralAdvertisementsSegue    = "PeripheralAdvertisements"
    }
    
    required init(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hasData = false
        self.setStateLabel()
        self.progressView.show()
        self.navigationItem.title = peripheral.name
        if let identifier = peripheral.identifier {
            self.uuidLabel.text = identifier.UUIDString
        } else {
            self.uuidLabel.text = "Unknown"
        }
        self.peripehealConnected = (peripheral.state == .Connected)
        self.rssiLabel.text = "\(self.peripheral.rssi)"
        let future = self.peripheral.discoverAllPeripheralServices()
        future.onSuccess {_ in
            self.hasData = true
            self.setStateLabel()
            self.progressView.remove()
        }
        future.onFailure {(error) in
            self.progressView.remove()
            self.serviceLabel.textColor = UIColor.lightGrayColor()
            if self.peripehealConnected {
                self.peripehealConnected = false
                self.presentViewController(UIAlertController.alertOnError(error, handler:{(action) in
                    self.setStateLabel()
                }), animated: true, completion:nil)
            }
        }
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.Plain, target:nil, action:nil)
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.setStateLabel()
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"peripheralDisconnected", name:BlueCapNotification.peripheralDisconnected, object:self.peripheral!)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"didBecomeActive", name:BlueCapNotification.didBecomeActive, object:nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"didResignActive", name:BlueCapNotification.didResignActive, object:nil)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func prepareForSegue(segue:UIStoryboardSegue, sender:AnyObject!) {
        if segue.identifier == MainStoryBoard.peripheralServicesSegue {
            let viewController = segue.destinationViewController as! PeripheralServicesViewController
            viewController.peripheral = self.peripheral
            viewController.peripheralViewController = self
        } else if segue.identifier == MainStoryBoard.peripehralAdvertisementsSegue {
            let viewController = segue.destinationViewController as! PeripheralAdvertisementsViewController
            viewController.peripheral = self.peripheral
        }
    }
    
    override func shouldPerformSegueWithIdentifier(identifier: String?, sender: AnyObject?) -> Bool {
        if let identifier = identifier {
            if identifier == MainStoryBoard.peripheralServicesSegue {
                return self.hasData
            } else {
                return true
            }
        } else {
            return true
        }
    }
    
    func peripheralDisconnected() {        
        Logger.debug("PeripheralViewController#peripheralDisconnected")
        self.progressView.remove()
        if self.peripehealConnected {
            self.peripehealConnected = false
            self.presentViewController(UIAlertController.alertWithMessage("Peripheral disconnected", handler:{(action) in
                self.setStateLabel()
            }), animated:true, completion:nil)
        }
    }
    
    func didResignActive() {
        Logger.debug("PeripheralViewController#didResignActive")
        self.navigationController?.popToRootViewControllerAnimated(false)
    }
    
    func didBecomeActive() {
        Logger.debug("PeripheralViewController#didBecomeActive")
    }
    
    func setStateLabel() {
        if self.peripehealConnected {
            self.stateLabel.text = "Connected"
            self.stateLabel.textColor = UIColor(red:0.1, green:0.7, blue:0.1, alpha:1.0)
            self.serviceLabel.textColor = UIColor.blackColor()
        } else {
            self.stateLabel.text = "Disconnected"
            self.stateLabel.textColor = UIColor(red:0.7, green:0.1, blue:0.1, alpha:1.0)
            self.serviceLabel.textColor = UIColor.lightGrayColor()
        }
    }
    
}