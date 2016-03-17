//
//  PeripheralViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/16/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import UIKit
import BlueCapKit

class PeripheralViewController : UITableViewController {
    
    weak var peripheral: BCPeripheral!
    var progressView = ProgressView()
    var peripehealConnected = true
    var hasData = false
    var rssiFuture: FutureStream<Int>?
    
    @IBOutlet var uuidLabel: UILabel!
    @IBOutlet var rssiLabel: UILabel!
    @IBOutlet var stateLabel: UILabel!
    @IBOutlet var serviceLabel: UILabel!

    @IBOutlet var discoveredAtLabel: UILabel!
    @IBOutlet var connectedAtLabel: UILabel!
    @IBOutlet var connectionsLabel: UILabel!
    @IBOutlet var secondsConnectedLabel: UILabel!
    @IBOutlet var avdSecondsConnected: UILabel!
    
    struct MainStoryBoard {
        static let peripheralServicesSegue  = "PeripheralServices"
        static let peripehralAdvertisementsSegue = "PeripheralAdvertisements"
    }
    
    required init?(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hasData = false
        self.setConnectionStateLabel()
        self.progressView.show()
        self.navigationItem.title = self.peripheral.name
        self.discoveredAtLabel.text = "\(self.peripheral.discoveredAt)"
        if let connectedAt = self.peripheral.connectedAt {
            self.connectedAtLabel.text = "\(connectedAt)"
        }
        self.connectionsLabel.text = "\(self.peripheral.numberOfConnections)"
        self.secondsConnectedLabel.text = "\(Int(self.peripheral.totalSecondsConnected))"
        if self.peripheral.numberOfConnections > 0 {
            self.avdSecondsConnected.text = "\(Int(self.peripheral.totalSecondsConnected) / self.peripheral.numberOfConnections)"
        } else {
            self.avdSecondsConnected.text = "0"
        }
        self.peripehealConnected = (self.peripheral.state == .Connected)
        self.rssiFuture = self.peripheral.startPollingRSSI(Params.peripheralRSSIPollingInterval, capacity: Params.peripheralRSSIFutureCapacity)
        self.rssiLabel.text = "\(self.peripheral.RSSI)"
        self.rssiFuture?.onSuccess { [unowned self] rssi in
            self.rssiLabel.text = "\(rssi)"
        }
        let peripheralDiscoveryFuture = self.peripheral.discoverAllPeripheralServices()
        peripheralDiscoveryFuture.onSuccess {_ in
            self.hasData = true
            self.setConnectionStateLabel()
            self.progressView.remove()
        }
        peripheralDiscoveryFuture.onFailure {(error) in
            self.progressView.remove()
            self.serviceLabel.textColor = UIColor.lightGrayColor()
            if self.peripehealConnected {
                self.peripehealConnected = false
                self.presentViewController(UIAlertController.alertOnError("Peripheral Discovery Error", error: error, handler: { action in
                    self.setConnectionStateLabel()
                }), animated: true, completion:nil)
            }
        }
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.Plain, target:nil, action:nil)
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.setConnectionStateLabel()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "peripheralDisconnected", name: BlueCapNotification.peripheralDisconnected, object: self.peripheral!)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didEnterBackground", name: UIApplicationDidEnterBackgroundNotification, object :nil)
    }
    
    override func viewDidDisappear(animated: Bool) {
        self.peripheral.stopPollingRSSI()
        self.rssiFuture = nil
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
        BCLogger.debug()
        self.progressView.remove()
        if self.peripehealConnected {
            self.peripehealConnected = false
            self.presentViewController(UIAlertController.alertWithMessage("Peripheral disconnected", handler:{ action in
                self.setConnectionStateLabel()
            }), animated:true, completion:nil)
        }
    }
    
    func didEnterBackground() {
        BCLogger.debug()
        self.navigationController?.popToRootViewControllerAnimated(false)
    }
    
    func setConnectionStateLabel() {
        if self.peripehealConnected {
            self.stateLabel.text = "Connected"
            self.stateLabel.textColor = UIColor(red: 0.1, green: 0.7, blue: 0.1, alpha: 1.0)
            self.serviceLabel.textColor = UIColor.blackColor()
        } else {
            self.stateLabel.text = "Disconnected"
            self.stateLabel.textColor = UIColor(red: 0.7, green: 0.1, blue: 0.1, alpha: 1.0)
            self.serviceLabel.textColor = UIColor.lightGrayColor()
        }
    }
    
}