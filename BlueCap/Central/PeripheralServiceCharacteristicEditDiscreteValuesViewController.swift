//
//  PeripheralServiceCharacteristicEditDiscreteValuesViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/20/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import UIKit
import BlueCapKit
import CoreBluetooth

class PeripheralServiceCharacteristicEditDiscreteValuesViewController : UITableViewController {

    private static var BCPeripheralStateKVOContext = UInt8()

    weak var characteristic: BCCharacteristic!
    var peripheralViewController: PeripheralViewController?

    var progressView = ProgressView()
    
    struct MainStoryboard {
        static let peripheralServiceCharacteristicDiscreteValueCell = "PeripheraServiceCharacteristicEditDiscreteValueCell"
    }

    required init?(coder aDecoder:NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = self.characteristic.name
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        let options = NSKeyValueObservingOptions([.New])
        self.characteristic?.service?.peripheral?.addObserver(self, forKeyPath: "state", options: options, context: &PeripheralServiceCharacteristicEditDiscreteValuesViewController.BCPeripheralStateKVOContext)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(PeripheralServiceCharacteristicEditDiscreteValuesViewController.didEnterBackground), name: UIApplicationDidEnterBackgroundNotification, object: nil)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        self.characteristic?.service?.peripheral?.removeObserver(self, forKeyPath: "state", context: &PeripheralServiceCharacteristicEditDiscreteValuesViewController.BCPeripheralStateKVOContext)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
    }

    func peripheralDisconnected() {
        BCLogger.debug()
        if let peripheralViewController = self.peripheralViewController {
            if peripheralViewController.peripheralConnected {
                self.presentViewController(UIAlertController.alertWithMessage("Peripheral disconnected") {(action) in
                        peripheralViewController.peripheralConnected = false
                        self.navigationController?.popViewControllerAnimated(true)
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
        case("state", &PeripheralServiceCharacteristicEditDiscreteValuesViewController.BCPeripheralStateKVOContext):
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
    
    override func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.characteristic.stringValues.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(MainStoryboard.peripheralServiceCharacteristicDiscreteValueCell, forIndexPath: indexPath) as UITableViewCell
        let stringValue = self.characteristic.stringValues[indexPath.row]
        cell.textLabel?.text = stringValue
        if let valueName = characteristic.stringValue?.keys.first {
            if let value = self.characteristic.stringValue?[valueName] {
                if value == stringValue {
                    cell.accessoryType = UITableViewCellAccessoryType.Checkmark
                } else {
                    cell.accessoryType = UITableViewCellAccessoryType.None
                }
            }
        }
        return cell
    }
    
    // UITableViewDelegate
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.progressView.show()
        if let characteristic = self.characteristic {
            if let valueName = characteristic.stringValue?.keys.first {
                let stringValue = [valueName:characteristic.stringValues[indexPath.row]]
                let write = characteristic.writeString(stringValue, timeout:Double(ConfigStore.getCharacteristicReadWriteTimeout()))
                write.onSuccess {characteristic in
                    self.progressView.remove()
                    self.navigationController?.popViewControllerAnimated(true)
                    return
                }
                write.onFailure {error in
                    self.presentViewController(UIAlertController.alertOnError("Charactertistic Write Error", error: error), animated: true, completion: nil)
                    self.progressView.remove()
                    self.navigationController?.popViewControllerAnimated(true)
                    return
                }
            }
        }
    }
    
}
