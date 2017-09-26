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
    
    var peripheralManagerViewController : PeripheralManagerViewController?

    var services: [MutableService] {
        let serviceUUIDs = PeripheralStore.getAdvertisedPeripheralServices()
        return Singletons.peripheralManager.services.reduce([]) { (services, service) in
            let avaiableServiceUUIDS = services.map { $0.uuid }
            return !serviceUUIDs.contains(service.uuid) && !avaiableServiceUUIDS.contains(service.uuid) ? (services + [service]) : services
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
    
    @objc func didEnterBackground() {
        Logger.debug()
        guard let peripheralManagerViewController = peripheralManagerViewController else {
            return
        }
        _ = navigationController?.popToViewController(peripheralManagerViewController, animated: false)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_:UITableView, numberOfRowsInSection section:  Int) -> Int {
        return self.services.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MainStoryboard.peripheralManagerAddAdverstisedServiceCell, for: indexPath) as! NameUUIDCell
        let service = services[indexPath.row]
        cell.nameLabel.text = service.name
        cell.uuidLabel.text = service.uuid.uuidString
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let peripheralManagerViewController = peripheralManagerViewController else {
            return
        }
        let service = services[indexPath.row]
        PeripheralStore.addAdvertisedPeripheralService(service.uuid)
        _ = navigationController?.popToViewController(peripheralManagerViewController, animated: false)
    }
}
