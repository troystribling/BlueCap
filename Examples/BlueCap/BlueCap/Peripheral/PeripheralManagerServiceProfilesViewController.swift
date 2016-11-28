//
//  PeripheralManagerServiceProfilesViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/12/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import UIKit
import BlueCapKit
import CoreBluetooth

class PeripheralManagerServiceProfilesViewController : ServiceProfilesTableViewController {
   
    var progressView: ProgressView!
    var peripheral: String?
    var peripheralManagerViewController: PeripheralManagerViewController?

    
    struct MainStoryboard {
        static let peripheralManagerServiceCell = "PeripheralManagerServiceProfileCell"
    }
    
    override var excludedServices : Array<CBUUID> {
        return Singletons.peripheralManager.services.map{ $0.uuid }
    }
    
    override var serviceProfileCell : String {
        return MainStoryboard.peripheralManagerServiceCell
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
        self.progressView = ProgressView()
    }
    
    override func viewWillAppear(_ animated:Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector:#selector(PeripheralManagerServiceProfilesViewController.didEnterBackground), name: NSNotification.Name.UIApplicationDidEnterBackground, object:nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    func didEnterBackground() {
        Logger.debug()
        if let peripheralManagerViewController = self.peripheralManagerViewController {
            _ = self.navigationController?.popToViewController(peripheralManagerViewController, animated:false)
        }
    }
    
    // UITableViewDelegate
    override func tableView(_ tableView:UITableView, didSelectRowAt indexPath:IndexPath) {
        let tags = Array(self.serviceProfiles.keys)
        if let profiles = self.serviceProfiles[tags[indexPath.section]] {
            let serviceProfile = profiles[indexPath.row]
            let service = MutableService(profile:serviceProfile)
            service.characteristicsFromProfiles()
            self.progressView.show()
            let future = Singletons.peripheralManager.add(service)
            future.onSuccess {
                if let peripheral = self.peripheral {
                    PeripheralStore.addPeripheralService(peripheral, service:service.uuid)
                }
                _ = self.navigationController?.popViewController(animated: true)
                self.progressView.remove()
            }
            future.onFailure { error in
                self.present(UIAlertController.alert(title: "Add Service Error", error: error), animated: true, completion: nil)
                _ = self.navigationController?.popViewController(animated: true)
                self.progressView.remove()
            }
        } else {
            _ = self.navigationController?.popViewController(animated: true)
        }
    }

}
