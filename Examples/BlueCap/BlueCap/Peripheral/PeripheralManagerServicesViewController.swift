//
//  PeripheralManagerServicesViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/12/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import UIKit
import CoreBluetooth
import BlueCapKit

class PeripheralManagerServicesViewController : UITableViewController {
    
    var peripheralManagerViewController: PeripheralManagerViewController?
    
    struct MainStoryboard {
        static let peripheralManagerServiceCell = "PeripheralManagerServiceCell"
        static let peripheralManagerServiceProfilesSegue = "PeripheralManagerServiceProfiles"
        static let peripheralManagerServiceCharacteristicsSegue = "PeripheralManagerServiceCharacteristics"
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated:Bool) {
        super.viewWillAppear(animated)
        self.tableView.reloadData()
        if Singletons.peripheralManager.isAdvertising {
            self.navigationItem.rightBarButtonItem!.isEnabled = false
        } else {
            self.navigationItem.rightBarButtonItem!.isEnabled = true
        }
        NotificationCenter.default.addObserver(self, selector:#selector(PeripheralManagerServicesViewController.didEnterBackground), name: NSNotification.Name.UIApplicationDidEnterBackground, object:nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func prepare(for segue:UIStoryboardSegue, sender:Any!) {
        if segue.identifier == MainStoryboard.peripheralManagerServiceProfilesSegue {
            let viewController = segue.destination as! PeripheralManagerServiceProfilesViewController
            if let peripheralManagerViewController = self.peripheralManagerViewController {
                viewController.peripheralManagerViewController = peripheralManagerViewController
            }
        } else if segue.identifier == MainStoryboard.peripheralManagerServiceCharacteristicsSegue {
            if let selectedIndexPath = self.tableView.indexPath(for: sender as! UITableViewCell) {
                let viewController = segue.destination as! PeripheralManagerServiceCharacteristicsViewController
                viewController.service = Singletons.peripheralManager.services[selectedIndexPath.row]
                if let peripheralManagerViewController = self.peripheralManagerViewController {
                    viewController.peripheralManagerViewController = peripheralManagerViewController
                }
            }
        }
    }
    
    @objc func didEnterBackground() {
        Logger.debug()
        if let peripheralManagerViewController = self.peripheralManagerViewController {
            _ = self.navigationController?.popToViewController(peripheralManagerViewController, animated:false)
        }
    }
    
    // UITableViewDataSource
    override func numberOfSections(in tableView:UITableView) -> Int {
        return 1
    }
    
    override func tableView(_:UITableView, numberOfRowsInSection section:Int) -> Int {
        return Singletons.peripheralManager.services.count
    }
    
    override func tableView(_ tableView:UITableView, cellForRowAt indexPath:IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MainStoryboard.peripheralManagerServiceCell, for:indexPath) as! NameUUIDCell
        let service = Singletons.peripheralManager.services[indexPath.row]
        cell.nameLabel.text = service.name
        cell.uuidLabel.text = service.uuid.uuidString
        return cell
    }
    
    override func tableView(_ tableView:UITableView, canEditRowAt indexPath:IndexPath) -> Bool {
        return !Singletons.peripheralManager.isAdvertising
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.delete
    }
    
    override func tableView(_ tableView:UITableView, commit editingStyle:UITableViewCellEditingStyle, forRowAt indexPath:IndexPath) {
        if editingStyle == UITableViewCellEditingStyle.delete {
            let service = Singletons.peripheralManager.services[indexPath.row]
            Singletons.peripheralManager.remove(service)
            PeripheralStore.removeSupportedPeripheralService(service.uuid)
            if PeripheralStore.getSupportedPeripheralServices().count == 0 {
                PeripheralStore.removeAdvertisedPeripheralService(service.uuid)
            }
            self.tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.fade)
        }
    }

    // UITableViewDelegate

}
