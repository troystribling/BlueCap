//
//  PeripheralServicesViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/22/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import UIKit
import BlueCapKit
import CoreBluetooth


class PeripheralServicesViewController : UITableViewController {

    weak var peripheral: Peripheral?
    weak var peripheralDiscoveryFuture: FutureStream<[Void]>?

    let cancelToken = CancelToken()

    struct MainStoryboard {
        static let peripheralServiceCell = "PeripheralServiceCell"
        static let peripheralServicesCharacteritics = "PeripheralServicesCharacteritics"
    }
    
    required init?(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad()  {
        super.viewDidLoad()
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(PeripheralServicesViewController.didEnterBackground), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        guard let peripheralDiscoveryFuture = peripheralDiscoveryFuture,
              let peripheral = peripheral,
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
        if segue.identifier == MainStoryboard.peripheralServicesCharacteritics {
            if let peripheral = peripheral, let selectedIndex = self.tableView.indexPath(for: sender as! UITableViewCell) {
                let viewController = segue.destination as! PeripheralServiceCharacteristicsViewController
                viewController.service = peripheral.services[selectedIndex.row]
                viewController.peripheral = peripheral
                viewController.peripheralDiscoveryFuture = peripheralDiscoveryFuture
            }
        }
    }
    
    @objc func didEnterBackground() {
        peripheral?.disconnect()
        _ = navigationController?.popToRootViewController(animated: false)
    }
    
    // UITableViewDataSource
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let peripheral = self.peripheral {
            return peripheral.services.count
        } else {
            return 0;
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MainStoryboard.peripheralServiceCell, for: indexPath) as! NameUUIDCell
        if let peripheral = peripheral {
            let service = peripheral.services[indexPath.row]
            cell.nameLabel.text = service.name
            cell.uuidLabel.text = service.uuid.uuidString
            cell.nameLabel.textColor = peripheral.state == .connected ? UIColor.black : UIColor.lightGray
        } else {
            cell.nameLabel.text = "Unknown"
            cell.uuidLabel.text = "Unknown"
        }
        return cell
    }

}
