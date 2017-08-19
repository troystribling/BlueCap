//
//  PeripheralManagerServiceCharacteristicsViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/19/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import UIKit
import BlueCapKit

class PeripheralManagerServiceCharacteristicsViewController : UITableViewController {
 
    var service: MutableService?
    var peripheralManagerViewController : PeripheralManagerViewController?

    
    struct MainStoryboard {
        static let peripheralManagerServiceChracteristicCell = "PeripheralManagerServiceChracteristicCell"
        static let peripheralManagerServiceCharacteristicSegue = "PeripheralManagerServiceCharacteristic"
    }
    
    required init?(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let service = self.service {
            self.navigationItem.title = service.name
        }
        NotificationCenter.default.addObserver(self, selector: #selector(PeripheralManagerServiceCharacteristicsViewController.didEnterBackground), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationItem.title = ""
        NotificationCenter.default.removeObserver(self)
    }
    
    override func prepare(for segue:UIStoryboardSegue, sender: Any!) {
        if segue.identifier == MainStoryboard.peripheralManagerServiceCharacteristicSegue {
            guard let service = self.service  else {
                return
            }
            if let selectedIndex = self.tableView.indexPath(for: sender as! UITableViewCell) {
                let viewController = segue.destination as! PeripheralManagerServiceCharacteristicViewController
                viewController.characteristic = service.characteristics[selectedIndex.row]
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
        if let service = self.service {
            return service.characteristics.count
        } else {
            return 0;
        }
    }
    
    override func tableView(_ tableView:UITableView, cellForRowAt indexPath:IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MainStoryboard.peripheralManagerServiceChracteristicCell, for: indexPath) as! NameUUIDCell
        if let service = self.service {
            let characteristic = service.characteristics[indexPath.row]
            cell.nameLabel.text = characteristic.name
            cell.uuidLabel.text = characteristic.uuid.uuidString
        }
        return cell
    }

}
