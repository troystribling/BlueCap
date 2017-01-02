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

    weak var characteristicUUID: CBUUID?
    weak var peripheral: Peripheral?
    var peripheralDiscoveryFuture: FutureStream<[Service]>?

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

    var characteristic: Characteristic? {
        guard  let characteristicUUID = characteristicUUID,
            let peripheral = peripheral,
            let characteristic = peripheral.characteristic(characteristicUUID) else {
                return nil
        }
        return characteristic
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
        
        peripheralDiscoveryFuture.onSuccess(cancelToken: cancelToken)  { [weak self] _ in
            self?.updateWhenActive()
        }
        peripheralDiscoveryFuture.onFailure(cancelToken: cancelToken) { [weak self] error in
            self?.presentAlertIngoringForcedDisconnect(title: "Connection Error", error: error)
            self?.updateWhenActive()
        }
        
        updateValues()
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
        stopReceivingNotificationIfNotifying()
        _ = peripheralDiscoveryFuture?.cancel(cancelToken)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        if segue.identifier == MainStoryboard.peripheralServiceCharacteristicEditDiscreteValuesSegue {
            let viewController = segue.destination as! PeripheralServiceCharacteristicEditDiscreteValuesViewController
            viewController.characteristicUUID = characteristicUUID
            viewController.peripheral = peripheral
            viewController.peripheralDiscoveryFuture = peripheralDiscoveryFuture
        } else if segue.identifier == MainStoryboard.peripheralServiceCharacteristicEditValueSeque {
            let viewController = segue.destination as! PeripheralServiceCharacteristicEditValueViewController
            viewController.characteristicUUID = characteristicUUID
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
            let peripheralDiscoveryFuture = peripheralDiscoveryFuture,
            characteristic.canRead,
            peripheral.state == .connected else {
            return
        }

        progressView.show()
        
        let readFuture = peripheralDiscoveryFuture.flatMap { [weak self] _ -> Future<Characteristic> in
            guard let strongSelf = self else {
                throw AppError.unlikelyFailure
            }
            guard let characteristic = strongSelf.characteristic else {
                throw AppError.characteristicNotFound
            }
            return characteristic.read(timeout: Double(ConfigStore.getCharacteristicReadWriteTimeout()))
            }.flatMap { [weak self] _ -> Future<Void> in
                guard let strongSelf = self else {
                    throw AppError.unlikelyFailure
                }
                return strongSelf.progressView.remove()
        }
        
        readFuture.onSuccess { [weak self] _ in
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

    func recieveNotificationsIfEnabled() {
        guard  let characteristic = characteristic,
            let peripheral = peripheral,
            let peripheralDiscoveryFuture = peripheralDiscoveryFuture,
            characteristic.isNotifying,
            peripheral.state == .connected else {
            return
        }
        
        let resvieveNotificationUpdatesFutureStream = peripheralDiscoveryFuture.flatMap { [weak self] _ -> FutureStream<(characteristic: Characteristic, data: Data?)> in
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
            self?.present(UIAlertController.alert(title: "Charcteristic notification update", error: error) { [weak self] _ in
                _ = self?.navigationController?.popViewController(animated: true)
                return
            }, animated:true, completion:nil)
        }
    }

    func stopReceivingNotificationIfNotifying() {
        guard let characteristic = characteristic, characteristic.isNotifying else {
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
