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
    var peripheralManagerViewController: PeripheralManagerViewController?

    
    struct MainStoryboard {
        static let peripheralManagerServiceCell = "PeripheralManagerServiceProfileCell"
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
    
    @objc func didEnterBackground() {
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
            future.onSuccess { _ in
                PeripheralStore.addSupportedPeripheralService(service.uuid)
                _ = self.navigationController?.popViewController(animated: true)
                _ = self.progressView.remove()
            }
            future.onFailure { error -> Void in
                self.progressView.remove().onSuccess { _ in
                    self.present(UIAlertController.alert(title: "Add Service Error", error: error), animated: true) {
                        _ = self.navigationController?.popViewController(animated: true)
                    }
                }
            }
        } else {
            _ = self.navigationController?.popViewController(animated: true)
        }
    }

}
