//
//  PeripheralManagerServicesCharacteristicValuesViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/20/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import UIKit
import BlueCapKit
import CoreBluetooth

class PeripheralManagerServicesCharacteristicValuesViewController : UITableViewController {
    
    var characteristic: MutableCharacteristic!
    var peripheralManagerViewController: PeripheralManagerViewController?

    
    struct MainStoryboard {
        static let peripheralManagerServiceCharacteristicEditValueSegue = "PeripheralManagerServiceCharacteristicEditValue"
        static let peripheralManagerServiceCharacteristicEditDiscreteValuesSegue = "PeripheralManagerServiceCharacteristicEditDiscreteValues"
        static let peripheralManagerServicesCharacteristicValueCell = "PeripheralManagerServicesCharacteristicValueCell"
    }
    
    required init?(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated:Bool) {
        super.viewWillAppear(animated)
        self.tableView.reloadData()
        if let characteristic = self.characteristic {
            self.navigationItem.title = characteristic.name
        }
        let future = self.characteristic.startRespondingToWriteRequests(capacity: 10)
        future.onSuccess {(request, _) in
            if let value = request.value , value.count > 0 {
                self.characteristic.value = request.value
                self.characteristic.respondToRequest(request, withResult: CBATTError.success)
                self.updateWhenActive()
            } else {
                self.characteristic.respondToRequest(request, withResult :CBATTError.invalidAttributeValueLength)
            }
        }
        NotificationCenter.default.addObserver(self, selector: #selector(PeripheralManagerServicesCharacteristicValuesViewController.didEnterBackground), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationItem.title = ""
        NotificationCenter.default.removeObserver(self)
        self.characteristic.stopRespondingToWriteRequests()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        if segue.identifier == MainStoryboard.peripheralManagerServiceCharacteristicEditValueSegue {
            let viewController = segue.destination as! PeripheralManagerServiceCharacteristicEditValueViewController
            viewController.characteristic = self.characteristic
            let selectedIndex = sender as! IndexPath
            if let stringValues = self.characteristic?.stringValue {
                let values = Array(stringValues.keys)
                viewController.valueName = values[selectedIndex.row]
            }
            if let peripheralManagerViewController = self.peripheralManagerViewController {
                viewController.peripheralManagerViewController = peripheralManagerViewController
            }
        } else if segue.identifier == MainStoryboard.peripheralManagerServiceCharacteristicEditDiscreteValuesSegue {
            let viewController = segue.destination as! PeripheralManagerServiceCharacteristicEditDiscreteValuesViewController
            viewController.characteristic = self.characteristic
            if let peripheralManagerViewController = self.peripheralManagerViewController {
                viewController.peripheralManagerViewController = peripheralManagerViewController
            }
        }
    }
    
    func didEnterBackground() {
        Logger.debug()
        if let peripheralManagerViewController = self.peripheralManagerViewController {
            _ = self.navigationController?.popToViewController(peripheralManagerViewController, animated: false)
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let values = self.characteristic?.stringValue {
            return values.count
        } else {
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MainStoryboard.peripheralManagerServicesCharacteristicValueCell, for: indexPath) as! CharacteristicValueCell
        if let values = self.characteristic?.stringValue {
            let characteristicValueNames = Array(values.keys)
            let characteristicValues = Array(values.values)
            cell.valueNameLabel.text = characteristicValueNames[indexPath.row]
            cell.valueLable.text = characteristicValues[indexPath.row]
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.characteristic.stringValues.isEmpty {
            self.performSegue(withIdentifier: MainStoryboard.peripheralManagerServiceCharacteristicEditValueSegue, sender:indexPath)
        } else {
            self.performSegue(withIdentifier: MainStoryboard.peripheralManagerServiceCharacteristicEditDiscreteValuesSegue, sender:indexPath)
        }
    }

}
