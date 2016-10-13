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

    fileprivate static var BCPeripheralStateKVOContext = UInt8()

    weak var characteristic: Characteristic?
    weak var connectionFuture: FutureStream<(peripheral: Peripheral, connectionEvent: ConnectionEvent)>!

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
                self.refreshButton.isEnabled = false
            } else {
                self.refreshButton.isEnabled = true
            }
        }
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
    
    override func viewDidAppear(_ animated:Bool)  {
        let options = NSKeyValueObservingOptions([.new])
        // TODO: Use Future Callback
        self.characteristic?.service?.peripheral?.addObserver(self, forKeyPath: "state", options: options, context: &PeripheralServiceCharacteristicValuesViewController.BCPeripheralStateKVOContext)
        NotificationCenter.default.addObserver(self, selector: #selector(PeripheralServiceCharacteristicValuesViewController.didEnterBackground), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        self.updateValues()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        if let characteristic = self.characteristic {
            if characteristic.isNotifying {
                characteristic.stopNotificationUpdates()
            }
        }
        self.characteristic?.service?.peripheral?.removeObserver(self, forKeyPath: "state", context: &PeripheralServiceCharacteristicValuesViewController.BCPeripheralStateKVOContext)
        NotificationCenter.default.removeObserver(self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        if segue.identifier == MainStoryboard.peripheralServiceCharacteristicEditDiscreteValuesSegue {
            let viewController = segue.destination as! PeripheralServiceCharacteristicEditDiscreteValuesViewController
            viewController.characteristic = self.characteristic
        } else if segue.identifier == MainStoryboard.peripheralServiceCharacteristicEditValueSeque {
            let viewController = segue.destination as! PeripheralServiceCharacteristicEditValueViewController
            viewController.characteristic = self.characteristic
            if let stringValues = self.characteristic?.stringValue {
                let selectedIndex = sender as! IndexPath
                let names = Array(stringValues.keys)
                viewController.valueName = names[selectedIndex.row]
            }
        }
    }
    
    @IBAction func updateValues() {
        if let characteristic = self.characteristic {
            if characteristic.isNotifying {
                let future = characteristic.receiveNotificationUpdates(capacity: 10)
                future.onSuccess { _ in
                    self.updateWhenActive()
                }
                future.onFailure{ error in
                    self.present(UIAlertController.alertOnError("Characteristic Notification Error", error: error), animated: true, completion: nil)
                }
            } else if characteristic.propertyEnabled(.read) {
                self.progressView.show()
                let future = characteristic.read(timeout: Double(ConfigStore.getCharacteristicReadWriteTimeout()))
                future.onSuccess { _ in
                    self.updateWhenActive()
                    self.progressView.remove()
                }
                future.onFailure { error in
                    self.progressView.remove()
                    self.present(UIAlertController.alertOnError("Charcteristic Read Error", error: error) { action in
                        _ = self.navigationController?.popViewController(animated: true)
                        return
                    }, animated:true, completion:nil)
                }
            }
        }
    }
    
    func peripheralDisconnected() {
        Logger.debug()
//        if let peripheralViewController = self.peripheralViewController {
//            if peripheralViewController.peripheralConnected {
//                self.progressView.remove()
//                self.present(UIAlertController.alertWithMessage("Peripheral disconnected") { action in
//                        peripheralViewController.peripheralConnected = false
//                }, animated: true, completion: nil)
//            }
//        }
    }

    func didEnterBackground() {
        _ = self.navigationController?.popToRootViewController(animated: false)
        Logger.debug()
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
// TODO: Use Future Callback
//        guard keyPath != nil else {
//            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
//            return
//        }
//        switch (keyPath!, context) {
//        case("state", PeripheralServiceCharacteristicValuesViewController.BCPeripheralStateKVOContext):
//            if let change = change, let newValue = change[NSKeyValueChangeKey.newKey], let newRawState = newValue as? Int, let newState = CBPeripheralState(rawValue: newRawState) {
//                if newState == .disconnected {
//                    DispatchQueue.main.async { self.peripheralDisconnected() }
//                }
//            }
//        default:
//            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
//        }
    }

    // UITableViewDataSource
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_: UITableView, numberOfRowsInSection section :Int) -> Int {
        if let values = self.characteristic?.stringValue {
            return values.count
        } else {
            return 0;
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MainStoryboard.peripheralServiceCharactertisticValueCell, for: indexPath) as! CharacteristicValueCell
        if let characteristic = self.characteristic {
            if let stringValues = characteristic.stringValue {
                let names = Array(stringValues.keys)
                let values = Array(stringValues.values)
                cell.valueNameLabel.text = names[indexPath.row]
                cell.valueLable.text = values[indexPath.row]
            }
            if characteristic.propertyEnabled(.write) || characteristic.propertyEnabled(.writeWithoutResponse) {
                cell.accessoryType = UITableViewCellAccessoryType.disclosureIndicator
            } else {
                cell.accessoryType = UITableViewCellAccessoryType.none
            }
        }
        return cell
    }
    
    // UITableViewDelegate
    override func tableView(_ tableView:UITableView, didSelectRowAt indexPath: IndexPath) {
        if let characteristic = self.characteristic {
            if characteristic.propertyEnabled(.write) || characteristic.propertyEnabled(.writeWithoutResponse) {
                if characteristic.stringValues.isEmpty {
                    self.performSegue(withIdentifier: MainStoryboard.peripheralServiceCharacteristicEditValueSeque, sender: indexPath)
                } else {
                    self.performSegue(withIdentifier: MainStoryboard.peripheralServiceCharacteristicEditDiscreteValuesSegue, sender: indexPath)
                }
            }
        }
    }
}
