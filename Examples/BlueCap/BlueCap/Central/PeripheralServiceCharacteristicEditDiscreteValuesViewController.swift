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
    weak var connectionFuture: FutureStream<(peripheral: Peripheral, connectionEvent: ConnectionEvent)>?

    let cancelToken = CancelToken()
    let progressView = ProgressView()

    struct MainStoryboard {
        static let peripheralServiceCharacteristicDiscreteValueCell = "PeripheraServiceCharacteristicEditDiscreteValueCell"
    }

    required init?(coder aDecoder:NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard  let characteristic = characteristic, peripheral != nil, connectionFuture != nil else {
            _ = self.navigationController?.popViewController(animated: true)
            return
        }
        self.navigationItem.title = characteristic.name
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(PeripheralServiceCharacteristicEditDiscreteValuesViewController.didEnterBackground), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        guard  let connectionFuture = connectionFuture, peripheral != nil, characteristic != nil else {
            _ = navigationController?.popViewController(animated: true)
            return
        }
        connectionFuture.onSuccess(cancelToken: cancelToken)  { (peripheral, connectionEvent) in
        }
        connectionFuture.onFailure { error in
        }
        readCharacteristic()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
        _ = connectionFuture?.cancel(cancelToken)
    }

    func didEnterBackground() {
        peripheral?.disconnect()
        _ = navigationController?.popToRootViewController(animated: false)
    }

    func writeCharacteristic(_ stringValue: [String : String]) {
        guard let characteristic = characteristic, let peripheral = peripheral, connectionFuture != nil, peripheral.state == .connected  else {
            present(UIAlertController.alert(message: "Connection error") { _ in
                _ = self.navigationController?.popToRootViewController(animated: false)
            }, animated: true, completion: nil)
            return
        }
        progressView.show()
        let writeFuture = characteristic.write(string: stringValue, timeout: (Double(ConfigStore.getCharacteristicReadWriteTimeout())))
        writeFuture.onSuccess { [weak self] _ in
            self?.progressView.remove().onSuccess {
                _ = self?.navigationController?.popViewController(animated: true)
            }
        }
        writeFuture.onFailure { [weak self] error in
            self?.progressView.remove().onSuccess {
                self?.present(UIAlertController.alert(title: "Charcteristic write error", error: error) { _ in
                    _ = self?.navigationController?.popViewController(animated: true)
                    return
                }, animated:true, completion:nil)
            }
        }
    }

    func readCharacteristic() {
        guard let characteristic = characteristic, let peripheral = peripheral, connectionFuture != nil, peripheral.state == .connected  else {
            present(UIAlertController.alert(message: "Connection error") { _ in
                _ = self.navigationController?.popToRootViewController(animated: false)
            }, animated: true, completion: nil)
            return
        }
        progressView.show()
        let readFuture = characteristic.read(timeout: Double(ConfigStore.getCharacteristicReadWriteTimeout()))
        readFuture.onSuccess { [weak self] _ in
            self?.updateWhenActive()
            _ = self?.progressView.remove()
        }
        readFuture.onFailure { [weak self] error in
            self?.progressView.remove().onSuccess {
                self?.present(UIAlertController.alert(title: "Charcteristic read error", error: error) { _ in
                    _ = self?.navigationController?.popViewController(animated: true)
                    return
                }, animated:true, completion:nil)
            }
        }
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
        cell.textLabel?.text = stringValue

        if let value = characteristic.stringValue?.values.first {
            if value == stringValue {
                cell.accessoryType = UITableViewCellAccessoryType.checkmark
            } else {
                cell.accessoryType = UITableViewCellAccessoryType.none
            }
        }

        return cell
    }
    
    // UITableViewDelegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let characteristic = characteristic, let valueName = characteristic.stringValue?.keys.first else {
            return
        }
        writeCharacteristic([valueName : characteristic.stringValues[indexPath.row]])
    }
    
}
