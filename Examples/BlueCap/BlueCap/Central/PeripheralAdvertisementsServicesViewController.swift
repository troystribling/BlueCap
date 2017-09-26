//
//  PeripheralAdvertisementsServicesViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 10/18/15.
//  Copyright © 2015 Troy Stribling. All rights reserved.
//

import UIKit
import BlueCapKit

class PeripheralAdvertisementsServicesViewController : UITableViewController {
    
    var peripheralAdvertisements: PeripheralAdvertisements?

    struct MainStoryboard {
        static let peripheralAdvertisementsServiceCell = "PeripheralAdvertisementsServiceCell"
    }
    
    required init?(coder aDecoder:NSCoder)  {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(PeripheralAdvertisementsServicesViewController.didEnterBackground), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func didEnterBackground() {
        _ = self.navigationController?.popToRootViewController(animated: false)
        Logger.debug()
    }
    
    // UITableViewDataSource
    override func numberOfSections(in tableView:UITableView) -> Int {
        return 1
    }
    
    override func tableView(_:UITableView, numberOfRowsInSection section:Int) -> Int {
        if let services = peripheralAdvertisements?.serviceUUIDs {
            return services.count
        } else {
            return 0;
        }
    }
    
    override func tableView(_ tableView:UITableView, cellForRowAt indexPath:IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MainStoryboard.peripheralAdvertisementsServiceCell, for: indexPath)
        if let services = peripheralAdvertisements?.serviceUUIDs {
            let service = services[indexPath.row]
            cell.textLabel?.text = service.uuidString
        }
        return cell
    }

}
