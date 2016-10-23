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

    weak var characteristic: Characteristic?
    weak var peripheral: Peripheral?

    var progressView = ProgressView()
    
    struct MainStoryboard {
        static let peripheralServiceCharacteristicDiscreteValueCell = "PeripheraServiceCharacteristicEditDiscreteValueCell"
    }

    required init?(coder aDecoder:NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard peripheral != nil, let characteristic = characteristic else {
            return
        }
        self.navigationItem.title = characteristic.name
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(PeripheralServiceCharacteristicEditDiscreteValuesViewController.didEnterBackground), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
    }

    func didEnterBackground() {
        peripheral?.stopPollingRSSI()
        peripheral?.disconnect()
        _ = self.navigationController?.popToRootViewController(animated: false)
    }

    // UITableViewDataSource
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let characteristic = characteristic else {
            return 0
        }
        return characteristic.stringValues.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MainStoryboard.peripheralServiceCharacteristicDiscreteValueCell, for: indexPath) as UITableViewCell
        guard let characteristic = characteristic else {
            cell.textLabel?.text = "Unknown"
            return cell
        }
        let stringValue = characteristic.stringValues[indexPath.row]
        if let valueName = characteristic.stringValue?.keys.first {
            if let value = characteristic.stringValue?[valueName] {
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
                let write = characteristic.write(string: stringValue, timeout: (Double(ConfigStore.getCharacteristicReadWriteTimeout())))
                write.onSuccess {characteristic in
                    self.progressView.remove()
                    _ = self.navigationController?.popViewController(animated: true)
                    return
                }
                write.onFailure {error in
                    self.present(UIAlertController.alertOnError("Charactertistic Write Error", error: error), animated: true, completion: nil)
                    self.progressView.remove()
                    _ = self.navigationController?.popViewController(animated: true)
                    return
                }
            }
        }
    }
    
}
