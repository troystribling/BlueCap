//
//  ConfigureScanServicesViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/29/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import UIKit
import BlueCapKit
import CoreBluetooth

class ConfigureScanServicesViewController : UITableViewController {
   
    struct MainStoryboard {
        static let configureScanServicesCell            = "ConfigureScanServicesCell"
        static let configureAddScanServiceSegue         = "ConfigureAddScanService"
        static let configureEditScanServiceSegue        = "ConfigureEditScanService"
    }

    required init?(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationItem.title = "Scanned Services"
        super.viewWillAppear(animated)
        self.tableView.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationItem.title = ""
    }
    
    override func prepare(for segue:UIStoryboardSegue, sender:Any?) {
        if segue.identifier == MainStoryboard.configureAddScanServiceSegue {
        } else if segue.identifier == MainStoryboard.configureEditScanServiceSegue {
            if let selectedIndexPath = self.tableView.indexPath(for: sender as! UITableViewCell) {
                let names = ConfigStore.getScannedServiceNames()
                let viewController = segue.destination as! ConfigureScanServiceViewController
                viewController.serviceName = names[(selectedIndexPath as NSIndexPath).row]
            }
        }
    }

    // UITableViewDataSource
    override func numberOfSections(in tableView:UITableView) -> Int {
        return 1
    }
    
    override func tableView(_:UITableView, numberOfRowsInSection section:Int) -> Int {
        return ConfigStore.getScannedServices().count
    }
    
    override func tableView(_ tableView:UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.delete
    }
    
    override func tableView(_ tableView:UITableView, commit editingStyle:UITableViewCellEditingStyle, forRowAt indexPath:IndexPath) {
        if editingStyle == UITableViewCellEditingStyle.delete {
            let names = ConfigStore.getScannedServiceNames()
            ConfigStore.removeScannedService(names[(indexPath as NSIndexPath).row])
            self.tableView.deleteRows(at: [indexPath], with:UITableViewRowAnimation.fade)
        }
    }
    
    override func tableView(_ tableView:UITableView, cellForRowAt indexPath:IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MainStoryboard.configureScanServicesCell, for: indexPath) as! NameUUIDCell
        let names = ConfigStore.getScannedServiceNames()
        if let serviceUUID = ConfigStore.getScannedServiceUUID(names[(indexPath as NSIndexPath).row]) {
            cell.uuidLabel.text = serviceUUID.uuidString
        } else {
            cell.uuidLabel.text = "Unknown"
        }
        cell.nameLabel.text = names[(indexPath as NSIndexPath).row]
        return cell
    }
    
    // UITableViewDelegate

}
