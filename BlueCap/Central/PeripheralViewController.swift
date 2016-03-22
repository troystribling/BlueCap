//
//  PeripheralViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/16/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import UIKit
import CoreBluetooth
import BlueCapKit

var BCPeripheralStateKVOContext = UInt8()

class PeripheralViewController : UITableViewController {
    
    weak var peripheral: BCPeripheral!
    var progressView = ProgressView()
    var peripheralConnected = true
    var hasData = false
    var peripheralDiscovered = false

    let dateFormatter = NSDateFormatter()

    @IBOutlet var uuidLabel: UILabel!
    @IBOutlet var rssiLabel: UILabel!
    @IBOutlet var stateLabel: UILabel!
    @IBOutlet var serviceLabel: UILabel!

    @IBOutlet var discoveredAtLabel: UILabel!
    @IBOutlet var connectedAtLabel: UILabel!
    @IBOutlet var connectionsLabel: UILabel!
    @IBOutlet var secondsConnectedLabel: UILabel!
    @IBOutlet var avgSecondsConnected: UILabel!
    
    struct MainStoryBoard {
        static let peripheralServicesSegue  = "PeripheralServices"
        static let peripehralAdvertisementsSegue = "PeripheralAdvertisements"
    }
    
    required init?(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
        self.dateFormatter.dateStyle = .ShortStyle
        self.dateFormatter.timeStyle = .ShortStyle
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hasData = false
        self.navigationItem.title = self.peripheral.name
        self.discoveredAtLabel.text = dateFormatter.stringFromDate(self.peripheral.discoveredAt)
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.Plain, target:nil, action:nil)
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.setConnectionStateLabel()
        self.peripheralConnected = (self.peripheral.state == .Connected)
        self.discoverPeripheral()
        self.setConnectionStateLabel()
        self.toggleRSSIUpdates()
        let options = NSKeyValueObservingOptions([.New])
        self.peripheral.addObserver(self, forKeyPath: "state", options: options, context: &BCPeripheralStateKVOContext)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(PeripheralViewController.willResignActive), name: UIApplicationWillResignActiveNotification, object :nil)
    }
    
    override func viewDidDisappear(animated: Bool) {
        self.peripheral.stopPollingRSSI()
        super.viewDidDisappear(animated)
        self.peripheral.removeObserver(self, forKeyPath: "state", context: &BCPeripheralStateKVOContext)
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

    func willResignActive() {
        self.navigationController?.popToRootViewControllerAnimated(false)
    }

    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String: AnyObject]?, context: UnsafeMutablePointer<Void>) {
        guard keyPath != nil else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
            return
        }
        switch (keyPath!, context) {
        case("state", &BCPeripheralStateKVOContext):
            if let change = change, newValue = change[NSKeyValueChangeNewKey], newRawState = newValue as? Int, newState = CBPeripheralState(rawValue: newRawState) {
                dispatch_async(dispatch_get_main_queue()) {
                    self.peripheralConnected = (newState == .Connected)
                    self.setConnectionStateLabel()
                    self.toggleRSSIUpdates()
                    self.discoverPeripheral()
                    self.updatePeripheralProperties()
                }
            }
        default:
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }

    func updatePeripheralProperties() {
        if let connectedAt = self.peripheral.connectedAt {
            self.connectedAtLabel.text = dateFormatter.stringFromDate(connectedAt)
        }
        self.rssiLabel.text = "\(self.peripheral.RSSI)"
        self.connectionsLabel.text = "\(self.peripheral.numberOfConnections)"
        self.secondsConnectedLabel.text = "\(Int(self.peripheral.cumlativeSecondsConnected))"
        if self.peripheral.numberOfConnections > 0 {
            self.avgSecondsConnected.text = "\(Int(self.peripheral.cumlativeSecondsConnected) / self.peripheral.numberOfConnections)"
        } else {
            self.avgSecondsConnected.text = "0"
        }
    }

    func toggleRSSIUpdates() {
        if self.peripheralConnected {
            let rssiFuture = self.peripheral.startPollingRSSI(Params.peripheralViewRSSIPollingInterval, capacity: Params.peripheralRSSIFutureCapacity)
            rssiFuture.onSuccess { [unowned self] _ in
                self.updatePeripheralProperties()
            }
        } else {
            self.peripheral.stopPollingRSSI()
        }

    }

    func discoverPeripheral() {
        guard self.peripheralConnected && !self.peripheralDiscovered else {
            return
        }
        self.progressView.show()
        let peripheralDiscoveryFuture = self.peripheral.discoverAllPeripheralServices()
        peripheralDiscoveryFuture.onSuccess { _ in
            self.hasData = true
            self.setConnectionStateLabel()
            self.progressView.remove()
            self.peripheralDiscovered = true
        }
        peripheralDiscoveryFuture.onFailure { error in
            self.progressView.remove()
            self.serviceLabel.textColor = UIColor.lightGrayColor()
            self.presentViewController(UIAlertController.alertOnError("Peripheral Discovery Error", error: error, handler: { action in
                self.setConnectionStateLabel()
            }), animated: true, completion:nil)
        }
    }

    func setConnectionStateLabel() {
        if self.peripheralConnected {
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