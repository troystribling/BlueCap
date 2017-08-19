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
    var peripheralDiscoveryFuture: FutureStream<[Void]>?

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
        guard  let characteristic = characteristic, peripheralDiscoveryFuture != nil else {
            _ = self.navigationController?.popViewController(animated: true)
            return
        }
        self.navigationItem.title = characteristic.name
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(PeripheralServiceCharacteristicEditDiscreteValuesViewController.didEnterBackground), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        guard  let characteristic = characteristic, let peripheralDiscoveryFuture = peripheralDiscoveryFuture, let peripheral = peripheral, peripheral.state == .connected else {
                _ = self.navigationController?.popViewController(animated: true)
                return
        }

        peripheralDiscoveryFuture.onFailure(cancelToken: cancelToken) { [weak self] error -> Void in
            guard let strongSelf = self else {
                return
            }
            strongSelf.progressView.remove().onSuccess { _ in
                strongSelf.presentAlertIngoringForcedDisconnect(title: "Connection Error", error: error)
                strongSelf.updateWhenActive()
            }
        }

        guard characteristic.canRead else {
            return
        }
        progressView.show()
        let readFuture = characteristic.read(timeout: Double(ConfigStore.getCharacteristicReadWriteTimeout()))
        readFuture.onSuccess { [weak self] _ in
            self?.updateWhenActive()
            _ = self?.progressView.remove()
        }
        readFuture.onFailure { [weak self] error in
            self?.progressView.remove().onSuccess { _ in
                self?.present(UIAlertController.alert(title: "Charcteristic read error", error: error) { _ in
                    _ = self?.navigationController?.popViewController(animated: true)
                    return
                }, animated:true, completion:nil)
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
        _ = peripheralDiscoveryFuture?.cancel(cancelToken)
    }

    @objc func didEnterBackground() {
        peripheral?.disconnect()
        _ = navigationController?.popToRootViewController(animated: false)
    }

    func writeCharacteristic(_ stringValue: [String : String]) {
        guard  let characteristic = characteristic,
            let peripheral = peripheral,
            let peripheralDiscoveryFuture = peripheralDiscoveryFuture,
            peripheral.state == .connected else {
                _ = self.navigationController?.popViewController(animated: true)
                return
        }
        progressView.show()
        let writeFuture = peripheralDiscoveryFuture.flatMap { _ -> Future<Void> in
            characteristic.write(string: stringValue, timeout: (Double(ConfigStore.getCharacteristicReadWriteTimeout())))
        }
        writeFuture.onSuccess { [weak self] _ in
            self?.progressView.remove().onSuccess { _ in
                _ = self?.navigationController?.popViewController(animated: true)
            }
        }
        writeFuture.onFailure { [weak self] error in
            self?.progressView.remove().onSuccess { _ in
                self?.present(UIAlertController.alert(title: "Charcteristic write error", error: error) { _ in
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
        guard let characteristic = characteristic,
              let peripheral = peripheral,
              peripheral.state == .connected
        else {
            _ = self.navigationController?.popViewController(animated: true)
            return 0
        }
        return characteristic.stringValues.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MainStoryboard.peripheralServiceCharacteristicDiscreteValueCell, for: indexPath) as UITableViewCell
        guard  let characteristic = characteristic,
            let peripheral = peripheral,
            peripheral.state == .connected else {
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
        guard let characteristic = characteristic,
              let peripheral = peripheral,
              peripheral.state == .connected
        else {
            _ = self.navigationController?.popViewController(animated: true)
            return
        }
        guard let valueName = characteristic.stringValue?.keys.first else {
            return
        }
        writeCharacteristic([valueName : characteristic.stringValues[indexPath.row]])
    }
    
}
