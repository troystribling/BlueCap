//
//  PeripheralManagerAddAdvertisedServiceViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 10/2/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import UIKit
import BlueCapKit

class PeripheralManagerAddAdvertisedServiceViewController: UITableViewController {

    struct MainStoryboard {
        static let peripheralManagerAddAdverstisedServiceCell = "PeripheralManagerAddAdverstisedServiceCell"
    }
    
    var peripheral: String?
    var peripheralManagerViewController : PeripheralManagerViewController?


    var services: [MutableService] {
        if let peripheral = self.peripheral {
            let serviceUUIDs = PeripheralStore.getAdvertisedPeripheralServicesForPeripheral(peripheral)
            return Singletons.peripheralManager.services.filter{!serviceUUIDs.contains( $0.uuid) }
        } else {
            return []
        }
    }
    

    required init?(coder aDecoder:NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.reloadData()
        NotificationCenter.default.addObserver(self, selector: #selector(PeripheralManagerAddAdvertisedServiceViewController.didEnterBackground), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
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
    
    override func tableView(_:UITableView, numberOfRowsInSection section:  Int) -> Int {
        return self.services.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MainStoryboard.peripheralManagerAddAdverstisedServiceCell, for: indexPath) as! NameUUIDCell
        if let _ = self.peripheral {
            let service = self.services[indexPath.row]
            cell.nameLabel.text = service.name
            cell.uuidLabel.text = service.uuid.uuidString
        } else {
            cell.nameLabel.text = "Unknown"
            cell.uuidLabel.text = "Unknown"
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let peripheral = self.peripheral {
            let service = self.services[indexPath.row]
            PeripheralStore.addAdvertisedPeripheralService(peripheral, service:service.uuid)
        }
        _ = self.navigationController?.popViewController(animated: true)
    }
}
