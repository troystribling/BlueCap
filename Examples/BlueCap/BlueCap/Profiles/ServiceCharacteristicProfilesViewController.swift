//
//  ServiceCharacteristicProfilesViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/4/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import UIKit
import BlueCapKit

class ServiceCharacteristicProfilesViewController : UITableViewController {

    var serviceProfile: ServiceProfile?
    
    struct MainStoryboard {
        static let serviceCharacteristicProfileCell = "ServiceCharacteristicProfileCell"
        static let serviceCharacteristicProfileSegue = "ServiceCharacteristicProfile"
    }
    
    required init?(coder aDecoder:NSCoder)  {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let serviceProfile = self.serviceProfile {
            self.navigationItem.title = serviceProfile.name
            self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func prepare(for segue:UIStoryboardSegue, sender:Any!) {
        if let serviceProfile = self.serviceProfile {
            if segue.identifier == MainStoryboard.serviceCharacteristicProfileSegue {
                if let selectedIndexPath = self.tableView.indexPath(for: sender as! UITableViewCell) {
                    let viewController = segue.destination as! ServiceCharacteristicProfileViewController
                    viewController.characteristicProfile = serviceProfile.characteristics[selectedIndexPath.row]
                }
            }
        }
    }

    // UITableViewDataSource
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let serviceProfile = self.serviceProfile {
            return serviceProfile.characteristics.count
        } else {
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MainStoryboard.serviceCharacteristicProfileCell, for: indexPath) as! NameUUIDCell
        if let serviceProfile = self.serviceProfile {
            let characteristicProfile = serviceProfile.characteristics[indexPath.row]
            cell.nameLabel.text = characteristicProfile.name
            cell.uuidLabel.text = characteristicProfile.uuid.uuidString
        }
        return cell
    }

}
