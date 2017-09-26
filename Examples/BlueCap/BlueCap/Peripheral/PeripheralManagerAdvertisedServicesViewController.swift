//
//  PeripheralManagerAdvertisedServicesViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 10/2/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import UIKit
import BlueCapKit

class PeripheralManagerAdvertisedServicesViewController: UITableViewController {

    struct MainStoryboard {
        static let peripheralManagerAddAdvertisedServiceSegue   = "PeripheralManagerAddAdvertisedService"
        static let peripheralManagerAdvertisedServiceCell       = "PeripheralManagerAdvertisedServiceCell"
    }
    
    var peripheralManagerViewController: PeripheralManagerViewController?
    
    required init?(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationItem.title = "Advertised Services"
        NotificationCenter.default.addObserver(self, selector:#selector(PeripheralManagerAdvertisedServicesViewController.didEnterBackground), name: NSNotification.Name.UIApplicationDidEnterBackground, object:nil)
        self.tableView.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationItem.title = ""
        NotificationCenter.default.removeObserver(self)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == MainStoryboard.peripheralManagerAddAdvertisedServiceSegue {
            let viewController = segue.destination as! PeripheralManagerAddAdvertisedServiceViewController
            if let peripheralManagerViewController = self.peripheralManagerViewController {
                viewController.peripheralManagerViewController = peripheralManagerViewController
            }
        }
    }
    
    @objc func didEnterBackground() {
        Logger.debug()
        guard let peripheralManagerViewController = self.peripheralManagerViewController else {
            return
        }
        _ = self.navigationController?.popToViewController(peripheralManagerViewController, animated:false)
    }
    
    override func numberOfSections(in tableView:UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView:UITableView, numberOfRowsInSection section:Int) -> Int {
        return PeripheralStore.getAdvertisedPeripheralServices().count
    }

    override func tableView(_ tableView:UITableView, cellForRowAt indexPath:IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MainStoryboard.peripheralManagerAdvertisedServiceCell, for: indexPath) as! NameUUIDCell
        let serviceUUID = PeripheralStore.getAdvertisedPeripheralServices()[(indexPath as NSIndexPath).row]
        cell.uuidLabel.text = serviceUUID.uuidString
        if let service = Singletons.peripheralManager.service(withUUID: serviceUUID)?.first {
            cell.nameLabel.text = service.name
        } else {
            cell.nameLabel.text = "Unknown"
        }
        return cell
    }

    override func tableView(_ tableView:UITableView, canEditRowAt indexPath:IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView:UITableView, commit editingStyle:UITableViewCellEditingStyle, forRowAt indexPath:IndexPath) {
        if editingStyle == .delete {
            let serviceUUIDs = PeripheralStore.getAdvertisedPeripheralServices()
            PeripheralStore.removeAdvertisedPeripheralService(serviceUUIDs[(indexPath as NSIndexPath).row])
            tableView.deleteRows(at: [indexPath], with:.fade)
        }
    }

}
