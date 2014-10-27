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
    
    weak var peripheral             : Peripheral?
    var progressView                = ProgressView()
    var peripehealConnected         = true
    
    @IBOutlet var uuidLabel         : UILabel!
    @IBOutlet var rssiLabel         : UILabel!
    @IBOutlet var stateLabel        : UILabel!
    
    struct MainStoryBoard {
        static let peripheralServicesSegue          = "PeripheralServices"
        static let peripehralAdvertisementsSegue    = "PeripheralAdvertisements"
    }
    
    required init(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let peripheral = self.peripheral {
            self.progressView.show()
            self.navigationItem.title = peripheral.name
            self.rssiLabel.text = "\(peripheral.rssi)"
            if let identifier = peripheral.identifier {
                self.uuidLabel.text = identifier.UUIDString
            } else {
                self.uuidLabel.text = "Unknown"
            }
            self.peripehealConnected = (peripheral.state == .Connected)
            peripheral.discoverAllPeripheralServices({
                    self.progressView.remove()
                },
                peripheralDiscoveryFailedCallback:{(error) in
                    self.progressView.remove()
                    self.presentViewController(UIAlertController.alertOnError(error) {(action) in
                            self.navigationController?.popViewControllerAnimated(true)
                            return
                        }, animated:true, completion:nil)
                }
            )
        }
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.Bordered, target:nil, action:nil)
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.setStateLabel()
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"peripheralDisconnected", name:BlueCapNotification.peripheralDisconnected, object:nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"didBecomeActive", name:BlueCapNotification.didBecomeActive, object:nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"didResignActive", name:BlueCapNotification.didResignActive, object:nil)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func prepareForSegue(segue:UIStoryboardSegue, sender:AnyObject!) {
        if segue.identifier == MainStoryBoard.peripheralServicesSegue {
            let viewController = segue.destinationViewController as PeripheralServicesViewController
            viewController.peripheral = self.peripheral
            viewController.peripheralViewController = self
        } else if segue.identifier == MainStoryBoard.peripehralAdvertisementsSegue {
            let viewController = segue.destinationViewController as PeripheralAdvertisementsViewController
            viewController.peripheral = self.peripheral
        }
    }
    
    func peripheralDisconnected() {        
        Logger.debug("PeripheralViewController#peripheralDisconnected")
        self.peripehealConnected = false
        self.progressView.remove()
        self.setStateLabel()
    }
    
    func didResignActive() {
        Logger.debug("PeripheralViewController#didResignActive")
        self.navigationController?.popToRootViewControllerAnimated(false)
    }
    
    func didBecomeActive() {
        Logger.debug("PeripheralViewController#didBecomeActive")
    }
    
    func setStateLabel() {
        if let peripheral = self.peripheral {
            if self.peripehealConnected {
                self.stateLabel.text = "Connected"
                self.stateLabel.textColor = UIColor(red:0.1, green:0.7, blue:0.1, alpha:1.0)
            } else {
                self.stateLabel.text = "Disconnected"
                self.stateLabel.textColor = UIColor(red:0.7, green:0.1, blue:0.1, alpha:1.0)
            }
        }
    }

}