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
    
    var peripheral                      : String?
    var peripheralManagerViewController : PeripheralManagerViewController?
    
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
            viewController.peripheral = self.peripheral
            if let peripheralManagerViewController = self.peripheralManagerViewController {
                viewController.peripheralManagerViewController = peripheralManagerViewController
            }
        }
    }
    
    func didEnterBackground() {
        Logger.debug()
        if let peripheralManagerViewController = self.peripheralManagerViewController {
            _ = self.navigationController?.popToViewController(peripheralManagerViewController, animated:false)
        }
    }
    
    override func numberOfSections(in tableView:UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView:UITableView, numberOfRowsInSection section:Int) -> Int {
        if let peripheral = self.peripheral {
            return PeripheralStore.getAdvertisedPeripheralServicesForPeripheral(peripheral).count
        } else {
            return 0
        }
    }

    override func tableView(_ tableView:UITableView, cellForRowAt indexPath:IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MainStoryboard.peripheralManagerAdvertisedServiceCell, for: indexPath) as! NameUUIDCell
        if let peripheral = self.peripheral {
            let serviceUUID = PeripheralStore.getAdvertisedPeripheralServicesForPeripheral(peripheral)[(indexPath as NSIndexPath).row]
            cell.uuidLabel.text = serviceUUID.uuidString
            if let service = Singletons.peripheralManager.service(withUUID: serviceUUID) {
                cell.nameLabel.text = service.name
            } else {
                cell.nameLabel.text = "Unknown"
            }
        } else {
            cell.uuidLabel.text = "Unknown"
            cell.nameLabel.text = "Unknown"
        }
        return cell
    }

    override func tableView(_ tableView:UITableView, canEditRowAt indexPath:IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView:UITableView, commit editingStyle:UITableViewCellEditingStyle, forRowAt indexPath:IndexPath) {
        if editingStyle == .delete {
            if let peripheral = self.peripheral {
                let serviceUUIDs = PeripheralStore.getAdvertisedPeripheralServicesForPeripheral(peripheral)
                PeripheralStore.removeAdvertisedPeripheralService(peripheral, service:serviceUUIDs[(indexPath as NSIndexPath).row])
                tableView.deleteRows(at: [indexPath], with:.fade)
            }
        }
    }

}
