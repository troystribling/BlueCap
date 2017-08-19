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
    var peripheralDiscoveryFuture: FutureStream<[Void]>?

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
        guard  let characteristic = characteristic else {
            _ = self.navigationController?.popViewController(animated: true)
            return
        }
        self.navigationItem.title = characteristic.name
        refreshButton.isEnabled  = !characteristic.isNotifying
        navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.plain, target:nil, action:nil)
    }
    
    override func viewDidAppear(_ animated:Bool)  {
        NotificationCenter.default.addObserver(self, selector: #selector(PeripheralServiceCharacteristicValuesViewController.didEnterBackground), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        guard  let peripheralDiscoveryFuture = peripheralDiscoveryFuture,
            let peripheral = peripheral,
            characteristic != nil,
            peripheral.state == .connected else {
                _ = navigationController?.popViewController(animated: true)
                return
        }
        
        peripheralDiscoveryFuture.onSuccess(cancelToken: cancelToken)  { [weak self] _ -> Void in
            self?.updateWhenActive()
        }
        peripheralDiscoveryFuture.onFailure(cancelToken: cancelToken) { [weak self] (error) -> Void in
            guard let strongSelf = self else {
                return
            }
            strongSelf.progressView.remove().onSuccess { _ in
                strongSelf.presentAlertIngoringForcedDisconnect(title: "Connection Error", error: error)
                strongSelf.updateWhenActive()
            }
        }
        
        updateValues()
        recieveNotificationsIfEnabled()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
        stopReceivingNotifications()
        _ = peripheralDiscoveryFuture?.cancel(cancelToken)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        if segue.identifier == MainStoryboard.peripheralServiceCharacteristicEditDiscreteValuesSegue {
            let viewController = segue.destination as! PeripheralServiceCharacteristicEditDiscreteValuesViewController
            viewController.characteristic = characteristic
            viewController.peripheral = peripheral
            viewController.peripheralDiscoveryFuture = peripheralDiscoveryFuture
        } else if segue.identifier == MainStoryboard.peripheralServiceCharacteristicEditValueSeque {
            let viewController = segue.destination as! PeripheralServiceCharacteristicEditValueViewController
            viewController.characteristic = characteristic
            viewController.peripheral = peripheral
            viewController.peripheralDiscoveryFuture = peripheralDiscoveryFuture
            if let stringValues = self.characteristic?.stringValue {
                let selectedIndex = sender as! IndexPath
                let names = Array(stringValues.keys)
                viewController.valueName = names[selectedIndex.row]
            }
        }
    }
    
    @IBAction func updateValues() {
        guard  let characteristic = characteristic,
            let peripheral = peripheral,
            characteristic.canRead,
            peripheralDiscoveryFuture != nil,
            peripheral.state == .connected else {
            return
        }

        progressView.show()
        
        let readFuture = characteristic.read(timeout: Double(ConfigStore.getCharacteristicReadWriteTimeout())).flatMap { [weak self] () -> Future<Void> in
            guard let strongSelf = self else {
                throw AppError.unlikelyFailure
            }
            return strongSelf.progressView.remove()
        }
        
        readFuture.onSuccess { [weak self] _ in
            self?.updateWhenActive()
        }
        
        readFuture.onFailure { [weak self] (error) -> Void in
            guard let `self` = self else {
                return
            }
            return self.progressView.remove().onSuccess { _ in
                self.present(UIAlertController.alert(title: "Charcteristic read error", error: error) { _ in
                    _ = self.navigationController?.popViewController(animated: true)
                    return
                }, animated:true, completion:nil)
            }
        }
        
    }

    func recieveNotificationsIfEnabled() {
        guard  let characteristic = characteristic,
            let peripheral = peripheral,
            let peripheralDiscoveryFuture = peripheralDiscoveryFuture,
            characteristic.isNotifying,
            peripheral.state == .connected else {
            return
        }
        
        let resvieveNotificationUpdatesFutureStream = peripheralDiscoveryFuture.flatMap { [weak self] _ -> FutureStream<Data?> in
            guard let strongSelf = self else {
                throw AppError.unlikelyFailure
            }
            guard let characteristic = strongSelf.characteristic else {
                throw AppError.characteristicNotFound
            }
            return characteristic.receiveNotificationUpdates()
        }
            
        resvieveNotificationUpdatesFutureStream.onSuccess { [weak self] _ in
            self?.updateWhenActive()
        }
        
        resvieveNotificationUpdatesFutureStream.onFailure { [weak self] error in
            self?.presentAlertIngoringForcedDisconnect(title: "Charcteristic notification update", error: error)
        }
    }

    func stopReceivingNotifications() {
        guard let characteristic = characteristic else {
            return
        }
        characteristic.stopNotificationUpdates()
    }

    @objc func didEnterBackground() {
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
        guard let characteristic = characteristic, let peripheral = peripheral else {
            return cell
        }
        if let stringValues = characteristic.stringValue {
            let names = Array(stringValues.keys)
            let values = Array(stringValues.values)
            cell.valueNameLabel.text = names[indexPath.row]
            cell.valueLable.text = values[indexPath.row]
            cell.valueLable.textColor = peripheral.state == .connected ? UIColor.black : UIColor.lightGray
        }
        if characteristic.propertyEnabled(.write) || characteristic.propertyEnabled(.writeWithoutResponse) {
            cell.accessoryType = UITableViewCellAccessoryType.disclosureIndicator
        } else {
            cell.accessoryType = UITableViewCellAccessoryType.none
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
