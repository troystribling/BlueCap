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

    fileprivate static var BCPeripheralStateKVOContext = UInt8()

    weak var characteristic: Characteristic!
    weak var connectionFuture: FutureStream<(peripheral: Peripheral, connectionEvent: ConnectionEvent)>!

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
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let options = NSKeyValueObservingOptions([.new])
        // TODO: Use Future Callback
        self.characteristic?.service?.peripheral?.addObserver(self, forKeyPath: "state", options: options, context: &PeripheralServiceCharacteristicEditDiscreteValuesViewController.BCPeripheralStateKVOContext)
        NotificationCenter.default.addObserver(self, selector: #selector(PeripheralServiceCharacteristicEditDiscreteValuesViewController.didEnterBackground), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.characteristic?.service?.peripheral?.removeObserver(self, forKeyPath: "state", context: &PeripheralServiceCharacteristicEditDiscreteValuesViewController.BCPeripheralStateKVOContext)
        NotificationCenter.default.removeObserver(self)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
    }

    func peripheralDisconnected() {
        Logger.debug()
        if let peripheralViewController = self.peripheralViewController {
            if peripheralViewController.peripheralConnected {
                self.present(UIAlertController.alertWithMessage("Peripheral disconnected") {(action) in
                        peripheralViewController.peripheralConnected = false
                        _ = self.navigationController?.popViewController(animated: true)
                    }, animated: true, completion: nil)
            }
        }
    }

    func didEnterBackground() {
        _ = self.navigationController?.popToRootViewController(animated: false)
        Logger.debug()
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        guard keyPath != nil else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        switch (keyPath!, context) {
        case("state", PeripheralServiceCharacteristicEditDiscreteValuesViewController.BCPeripheralStateKVOContext):
            if let change = change, let newValue = change[NSKeyValueChangeKey.newKey], let newRawState = newValue as? Int, let newState = CBPeripheralState(rawValue: newRawState) {
                if newState == .disconnected {
                    DispatchQueue.main.async { self.peripheralDisconnected() }
                }
            }
        default:
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }

    // UITableViewDataSource
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.characteristic.stringValues.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MainStoryboard.peripheralServiceCharacteristicDiscreteValueCell, for: indexPath) as UITableViewCell
        let stringValue = self.characteristic.stringValues[indexPath.row]
        cell.textLabel?.text = stringValue
        if let valueName = characteristic.stringValue?.keys.first {
            if let value = self.characteristic.stringValue?[valueName] {
                if value == stringValue {
                    cell.accessoryType = UITableViewCellAccessoryType.checkmark
                } else {
                    cell.accessoryType = UITableViewCellAccessoryType.none
                }
            }
        }
        return cell
    }
    
    // UITableViewDelegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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
