//
//  PeripheralServiceCharacteristicValuesViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/5/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import UIKit
import BlueCapKit
import CoreBluetooth

class PeripheralServiceCharacteristicValuesViewController : UITableViewController {

    private static var BCPeripheralStateKVOContext = UInt8()

    weak var characteristic: BCCharacteristic?
    let progressView: ProgressView!
    var peripheralViewController: PeripheralViewController?

    
    @IBOutlet var refreshButton:UIButton!
    
    struct MainStoryboard {
        static let peripheralServiceCharactertisticValueCell                = "PeripheralServiceCharacteristicValueCell"
        static let peripheralServiceCharacteristicEditDiscreteValuesSegue   = "PeripheralServiceCharacteristicEditDiscreteValues"
        static let peripheralServiceCharacteristicEditValueSeque            = "PeripheralServiceCharacteristicEditValue"
    }
    
    required init?(coder aDecoder:NSCoder) {
        self.progressView = ProgressView()
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let characteristic = self.characteristic {
            self.navigationItem.title = characteristic.name
            if characteristic.isNotifying {
                self.refreshButton.enabled = false
            } else {
                self.refreshButton.enabled = true
            }
        }
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
    }
    
    override func viewDidAppear(animated:Bool)  {
        let options = NSKeyValueObservingOptions([.New])
        self.characteristic?.service?.peripheral?.addObserver(self, forKeyPath: "state", options: options, context: &PeripheralServiceCharacteristicValuesViewController.BCPeripheralStateKVOContext)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(PeripheralServiceCharacteristicValuesViewController.didEnterBackground), name: UIApplicationDidEnterBackgroundNotification, object: nil)
        self.updateValues()
    }
    
    override func viewDidDisappear(animated: Bool) {
        if let characteristic = self.characteristic {
            if characteristic.isNotifying {
                characteristic.stopNotificationUpdates()
            }
        }
        self.characteristic?.service?.peripheral?.removeObserver(self, forKeyPath: "state", context: &PeripheralServiceCharacteristicValuesViewController.BCPeripheralStateKVOContext)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if segue.identifier == MainStoryboard.peripheralServiceCharacteristicEditDiscreteValuesSegue {
            let viewController = segue.destinationViewController as! PeripheralServiceCharacteristicEditDiscreteValuesViewController
            viewController.characteristic = self.characteristic
        } else if segue.identifier == MainStoryboard.peripheralServiceCharacteristicEditValueSeque {
            let viewController = segue.destinationViewController as! PeripheralServiceCharacteristicEditValueViewController
            viewController.characteristic = self.characteristic
            if let stringValues = self.characteristic?.stringValue {
                let selectedIndex = sender as! NSIndexPath
                let names = Array(stringValues.keys)
                viewController.valueName = names[selectedIndex.row]
            }
        }
    }
    
    @IBAction func updateValues() {
        if let characteristic = self.characteristic {
            if characteristic.isNotifying {
                let future = characteristic.receiveNotificationUpdates(10)
                future.onSuccess { _ in
                    self.updateWhenActive()
                }
                future.onFailure{ error in
                    self.presentViewController(UIAlertController.alertOnError("Characteristic Notification Error", error: error), animated: true, completion: nil)
                }
            } else if characteristic.propertyEnabled(.Read) {
                self.progressView.show()
                let future = characteristic.read(Double(ConfigStore.getCharacteristicReadWriteTimeout()))
                future.onSuccess { _ in
                    self.updateWhenActive()
                    self.progressView.remove()
                }
                future.onFailure { error in
                    self.progressView.remove()
                    self.presentViewController(UIAlertController.alertOnError("Charcteristic Read Error", error: error) { action in
                        self.navigationController?.popViewControllerAnimated(true)
                        return
                    }, animated:true, completion:nil)
                }
            }
        }
    }
    
    func peripheralDisconnected() {
        BCLogger.debug()
        if let peripheralViewController = self.peripheralViewController {
            if peripheralViewController.peripheralConnected {
                self.progressView.remove()
                self.presentViewController(UIAlertController.alertWithMessage("Peripheral disconnected") { action in
                        peripheralViewController.peripheralConnected = false
                }, animated: true, completion: nil)
            }
        }
    }

    func didEnterBackground() {
        self.navigationController?.popToRootViewControllerAnimated(false)
        BCLogger.debug()
    }

    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String: AnyObject]?, context: UnsafeMutablePointer<Void>) {
        guard keyPath != nil else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
            return
        }
        switch (keyPath!, context) {
        case("state", &PeripheralServiceCharacteristicValuesViewController.BCPeripheralStateKVOContext):
            if let change = change, newValue = change[NSKeyValueChangeNewKey], newRawState = newValue as? Int, newState = CBPeripheralState(rawValue: newRawState) {
                if newState == .Disconnected {
                    dispatch_async(dispatch_get_main_queue()) { self.peripheralDisconnected() }
                }
            }
        default:
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }

    // UITableViewDataSource
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_: UITableView, numberOfRowsInSection section :Int) -> Int {
        if let values = self.characteristic?.stringValue {
            return values.count
        } else {
            return 0;
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(MainStoryboard.peripheralServiceCharactertisticValueCell, forIndexPath: indexPath) as! CharacteristicValueCell
        if let characteristic = self.characteristic {
            if let stringValues = characteristic.stringValue {
                let names = Array(stringValues.keys)
                let values = Array(stringValues.values)
                cell.valueNameLabel.text = names[indexPath.row]
                cell.valueLable.text = values[indexPath.row]
            }
            if characteristic.propertyEnabled(.Write) || characteristic.propertyEnabled(.WriteWithoutResponse) {
                cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
            } else {
                cell.accessoryType = UITableViewCellAccessoryType.None
            }
        }
        return cell
    }
    
    // UITableViewDelegate
    override func tableView(tableView:UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let characteristic = self.characteristic {
            if characteristic.propertyEnabled(.Write) || characteristic.propertyEnabled(.WriteWithoutResponse) {
                if characteristic.stringValues.isEmpty {
                    self.performSegueWithIdentifier(MainStoryboard.peripheralServiceCharacteristicEditValueSeque, sender: indexPath)
                } else {
                    self.performSegueWithIdentifier(MainStoryboard.peripheralServiceCharacteristicEditDiscreteValuesSegue, sender: indexPath)
                }
            }
        }
    }
}
