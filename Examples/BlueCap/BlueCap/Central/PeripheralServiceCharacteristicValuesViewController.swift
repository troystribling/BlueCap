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

    weak var characteristic: Characteristic?
    weak var peripheral: Peripheral?
    weak var connectionFuture: FutureStream<(peripheral: Peripheral, connectionEvent: ConnectionEvent)>?

    let cancelToken = CancelToken()
    let progressView = ProgressView()

    @IBOutlet var refreshButton:UIButton!
    
    struct MainStoryboard {
        static let peripheralServiceCharactertisticValueCell = "PeripheralServiceCharacteristicValueCell"
        static let peripheralServiceCharacteristicEditDiscreteValuesSegue = "PeripheralServiceCharacteristicEditDiscreteValues"
        static let peripheralServiceCharacteristicEditValueSeque = "PeripheralServiceCharacteristicEditValue"
    }
    
    required init?(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        guard  let characteristic = characteristic, peripheral != nil, connectionFuture != nil else {
            _ = self.navigationController?.popViewController(animated: true)
            return
        }
        self.navigationItem.title = characteristic.name
        refreshButton.isEnabled  = !characteristic.isNotifying
        navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.plain, target:nil, action:nil)
    }
    
    override func viewDidAppear(_ animated:Bool)  {
        NotificationCenter.default.addObserver(self, selector: #selector(PeripheralServiceCharacteristicValuesViewController.didEnterBackground), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        guard  let connectionFuture = connectionFuture, peripheral != nil, characteristic != nil else {
            _ = navigationController?.popViewController(animated: true)
            return
        }
        connectionFuture.onSuccess(cancelToken: cancelToken)  { [weak self] (peripheral, connectionEvent) in
            self?.updateWhenActive()
        }
        connectionFuture.onFailure { [weak self] error in
            self?.updateWhenActive()
        }
        updateValues()
        recieveNotificationsIfNotifying()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
        stopReceivingNotificationIfNotifying()
        _ = connectionFuture?.cancel(cancelToken)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        if segue.identifier == MainStoryboard.peripheralServiceCharacteristicEditDiscreteValuesSegue {
            let viewController = segue.destination as! PeripheralServiceCharacteristicEditDiscreteValuesViewController
            viewController.characteristic = characteristic
            viewController.peripheral = peripheral
            viewController.connectionFuture = connectionFuture
        } else if segue.identifier == MainStoryboard.peripheralServiceCharacteristicEditValueSeque {
            let viewController = segue.destination as! PeripheralServiceCharacteristicEditValueViewController
            viewController.characteristic = characteristic
            viewController.peripheral = peripheral
            viewController.connectionFuture = connectionFuture
            if let stringValues = self.characteristic?.stringValue {
                let selectedIndex = sender as! IndexPath
                let names = Array(stringValues.keys)
                viewController.valueName = names[selectedIndex.row]
            }
        }
    }
    
    @IBAction func updateValues() {
        guard  let characteristic = characteristic, let peripheral = peripheral, connectionFuture != nil, peripheral.state == .connected else {
            present(UIAlertController.alertOnErrorWithMessage("Not connected"), animated:true, completion:nil)
            return
        }

        progressView.show()
        let readFuture = characteristic.read(timeout: Double(ConfigStore.getCharacteristicReadWriteTimeout()))

        readFuture.onSuccess { [weak self] _ in
            _ = self?.progressView.remove()
            self?.updateWhenActive()
        }
        readFuture.onFailure { [weak self] error in
            self?.progressView.remove().onSuccess {
                self?.present(UIAlertController.alert(title: "Charcteristic read error", error: error) { [weak self] _ in
                    _ = self?.navigationController?.popViewController(animated: true)
                    return
                }, animated:true, completion:nil)
            }
        }
    }

    func recieveNotificationsIfNotifying() {
        guard let characteristic = characteristic, characteristic.isNotifying, let peripheral = peripheral, connectionFuture != nil, peripheral.state == .connected else {
            return
        }
        characteristic.receiveNotificationUpdates().onSuccess { [weak self] _ in
            self?.updateWhenActive()
        }
    }

    func stopReceivingNotificationIfNotifying() {
        guard let characteristic = characteristic, characteristic.isNotifying, let peripheral = peripheral, connectionFuture != nil, peripheral.state == .connected else {
            return
        }
        characteristic.stopNotificationUpdates()
    }

    func didEnterBackground() {
        peripheral?.disconnect()
        _ = navigationController?.popToRootViewController(animated: false)
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
