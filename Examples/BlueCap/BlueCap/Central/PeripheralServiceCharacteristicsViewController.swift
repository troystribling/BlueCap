//
//  PeripheralServiceCharacteristicsViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/23/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import UIKit
import BlueCapKit
import CoreBluetooth

class PeripheralServiceCharacteristicsViewController : UITableViewController {

    weak var service: Service?
    weak var peripheral: Peripheral?
    var peripheralDiscoveryFuture: FutureStream<[Void]>?

    let cancelToken = CancelToken()

    var dataValid = false

    struct MainStoryboard {
        static let peripheralServiceCharacteristicCell = "PeripheralServiceCharacteristicCell"
        static let peripheralServiceCharacteristicSegue = "PeripheralServiceCharacteristic"
    }
    
    required init?(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
    }
 
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(PeripheralServiceCharacteristicsViewController.didEnterBackground), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        guard let peripheralDiscoveryFuture = peripheralDiscoveryFuture,
            let peripheral = peripheral,
            service != nil,
            peripheral.state == .connected
        else {
            _ = self.navigationController?.popToRootViewController(animated: false)
            return
        }
        updateWhenActive()
        peripheralDiscoveryFuture.onSuccess(cancelToken: cancelToken)  { [weak self] _ in
            self?.updateWhenActive()
        }
        peripheralDiscoveryFuture.onFailure { [weak self] error in
            self?.presentAlertIngoringForcedDisconnect(title: "Connection Error", error: error)
            self?.updateWhenActive()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
        _ = peripheralDiscoveryFuture?.cancel(cancelToken)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        if segue.identifier == MainStoryboard.peripheralServiceCharacteristicSegue {
            if let service = service,
               let peripheral = peripheral,
               let selectedIndex = self.tableView.indexPath(for: sender as! UITableViewCell)
            {
                let viewController = segue.destination as! PeripheralServiceCharacteristicViewController
                viewController.characteristic = service.characteristics[selectedIndex.row]
                viewController.peripheral = peripheral
                viewController.peripheralDiscoveryFuture = peripheralDiscoveryFuture
            }
        }
    }

    override func shouldPerformSegue(withIdentifier identifier: String?, sender: Any?) -> Bool {
        return true
    }

   @objc func didEnterBackground() {
        peripheral?.stopPollingRSSI()
        peripheral?.disconnect()
        _ = self.navigationController?.popToRootViewController(animated: false)
    }

    // UITableViewDataSource
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let service = service {
            return service.characteristics.count
        } else {
            return 0;
        }
    }
    
    override func tableView(_ tableView:UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MainStoryboard.peripheralServiceCharacteristicCell, for: indexPath) as! NameUUIDCell
        if let service = service, let peripheral = peripheral {
            let characteristic = service.characteristics[indexPath.row]
            cell.nameLabel.text = characteristic.name
            cell.uuidLabel.text = characteristic.uuid.uuidString
            cell.nameLabel.textColor = peripheral.state == .connected ? UIColor.black : UIColor.lightGray
        }
        return cell
    }
    
    // UITableViewDelegate

}
