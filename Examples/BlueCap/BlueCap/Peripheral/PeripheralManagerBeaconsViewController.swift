//
//  PeripheralManagerBeaconsViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 9/28/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import UIKit
import BlueCapKit

class PeripheralManagerBeaconsViewController: UITableViewController {

    struct MainStoryboard {
        static let peripheralManagerBeaconCell      = "PeripheralManagerBeaconCell"
        static let peripheralManagerEditBeaconSegue = "PeripheralManagerEditBeacon"
        static let peripheralManagerAddBeaconSegue  = "PeripheralManagerAddBeacon"
    }
    
    var peripheral                      : String?
    var peripheralManagerViewController : PeripheralManagerViewController?

    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.reloadData()
        self.navigationItem.title = "Beacons"
        NotificationCenter.default.addObserver(self, selector:#selector(PeripheralManagerBeaconsViewController.didEnterBackground), name: NSNotification.Name.UIApplicationDidEnterBackground, object:nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationItem.title = ""
        NotificationCenter.default.removeObserver(self)
    }


    override func prepare(for segue:UIStoryboardSegue, sender:Any?) {
        if segue.identifier == MainStoryboard.peripheralManagerAddBeaconSegue {
        } else if segue.identifier == MainStoryboard.peripheralManagerEditBeaconSegue {
            if let selectedIndexPath = self.tableView.indexPath(for: sender as! UITableViewCell) {
                let viewController = segue.destination as! PeripheralManagerBeaconViewController
                let beaconNames = PeripheralStore.getBeaconNames()
                viewController.beaconName = beaconNames[(selectedIndexPath as NSIndexPath).row]
                if let peripheralManagerViewController = self.peripheralManagerViewController {
                    viewController.peripheralManagerViewController = peripheralManagerViewController
                }
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

    override func tableView(_ tableView:UITableView, numberOfRowsInSection section: Int) -> Int {
        return PeripheralStore.getBeaconNames().count
    }

    override func tableView(_ tableView:UITableView, cellForRowAt indexPath:IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MainStoryboard.peripheralManagerBeaconCell, for: indexPath) as! PeripheralManagerBeaconCell
        let name = PeripheralStore.getBeaconNames()[(indexPath as NSIndexPath).row]
        cell.nameLabel.text = name
        if let uuid = PeripheralStore.getBeacon(name) {
            let beaconConfig = PeripheralStore.getBeaconConfig(name)
            cell.uuidLabel.text = uuid.uuidString
            cell.majorLabel.text = "\(beaconConfig[1])"
            cell.minorLabel.text = "\(beaconConfig[0])"
            cell.accessoryType = .none
            if let peripheral = self.peripheral {
                if let advertisedBeacon = PeripheralStore.getAdvertisedBeacon(peripheral) {
                    if advertisedBeacon == name {
                        cell.accessoryType = .checkmark
                    }
                }
            }
        }
        return cell
    }

    override func tableView(_ tableView:UITableView, canEditRowAt indexPath:IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath:IndexPath) {
        if let peripheral = self.peripheral {
            let beaconNames = PeripheralStore.getBeaconNames()
            PeripheralStore.setAdvertisedBeacon(peripheral, beacon:beaconNames[(indexPath as NSIndexPath).row])
            _ = self.navigationController?.popViewController(animated: true)
        }
    }
    
    override func tableView(_ tableView:UITableView, commit editingStyle:UITableViewCellEditingStyle, forRowAt indexPath:IndexPath) {
        if editingStyle == .delete {
            let beaconNames = PeripheralStore.getBeaconNames()
            PeripheralStore.removeBeacon(beaconNames[(indexPath as NSIndexPath).row])
            if let peripheral = self.peripheral {
                PeripheralStore.removeAdvertisedBeacon(peripheral)
                PeripheralStore.removeBeaconEnabled(peripheral)
            }
            tableView.deleteRows(at: [indexPath], with:.fade)
        }
    }
}
