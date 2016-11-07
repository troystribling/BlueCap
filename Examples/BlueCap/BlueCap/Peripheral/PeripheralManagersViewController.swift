//
//  PeripheralManagersViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/10/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import UIKit
import BlueCapKit

class PeripheralManagersViewController : UITableViewController {
   
    struct MainStoryboard {
        static let peripheralManagerCell        = "PeripheralManagerCell"
        static let peripheralManagerViewSegue   = "PeripheralManagerView"
        static let peripheralManagerAddSegue    = "PeripheralManagerAdd"
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        styleNavigationBar()
        navigationItem.leftBarButtonItem = self.editButtonItem
        navigationItem.leftBarButtonItem?.tintColor = UIColor.black
    }
    
    override func viewWillAppear(_ animated:Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
        navigationItem.title = "Peripherals"
    }
    
    override func viewWillDisappear(_ animated:Bool) {
        super.viewWillDisappear(animated)
        navigationItem.title = ""
    }
    
    override func prepare(for segue:UIStoryboardSegue, sender:Any!) {
        if segue.identifier == MainStoryboard.peripheralManagerViewSegue {
            if let selectedIndex = tableView.indexPath(for: sender as! UITableViewCell) {
                let viewController = segue.destination as! PeripheralManagerViewController
                let peripherals = PeripheralStore.getPeripheralNames()
                viewController.peripheral = peripherals[(selectedIndex as NSIndexPath).row]
            }
        } else if segue.identifier == MainStoryboard.peripheralManagerAddSegue {
            let viewController = segue.destination as! PeripheralManagerViewController
            viewController.peripheral = nil
        }
    }
    
    // UITableViewDataSource
    override func numberOfSections(in tableView:UITableView) -> Int {
        return 1
    }
    
    override func tableView(_:UITableView, numberOfRowsInSection section:Int) -> Int {
        return PeripheralStore.getPeripheralNames().count
    }
    
    override func tableView(_ tableView:UITableView, editingStyleForRowAt indexPath:IndexPath) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.delete
    }
    
    override func tableView(_ tableView:UITableView, commit editingStyle:UITableViewCellEditingStyle, forRowAt indexPath:IndexPath) {
        if editingStyle == UITableViewCellEditingStyle.delete {
            let peripherals = PeripheralStore.getPeripheralNames()
            PeripheralStore.removePeripheral(peripherals[(indexPath as NSIndexPath).row])
            tableView.deleteRows(at: [indexPath], with:UITableViewRowAnimation.fade)
        }
    }
    
    override func tableView(_ tableView:UITableView, cellForRowAt indexPath:IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MainStoryboard.peripheralManagerCell, for: indexPath) as! SimpleCell
        let peripherals = PeripheralStore.getPeripheralNames()
        cell.nameLabel.text = peripherals[(indexPath as NSIndexPath).row]
        return cell
    }

    // UITableViewDelegate
    
}
