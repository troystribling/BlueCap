//
//  ServiceCharacteristicProfileValuesViewController.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/5/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import Foundation
import CoreBluetooth
import BlueCapKit

class ServiceCharacteristicProfileValuesViewController : UITableViewController {
    
    var characteristicProfile : CharacteristicProfile?
    
    var  values : [String:String]? {
        if let characteristicProfile = self.characteristicProfile {
            if let initialValue = characteristicProfile.initialValue {
                return characteristicProfile.stringValue(initialValue)
            } else {
                return nil
            }
        } else {
            return nil
        }
    }

    struct MainStoryboard {
        static let serviceCharacteristicProfileValueCell = "ServiceCharacteristicProfileValueCell"
    }
    
    required init?(coder aDecoder:NSCoder) {
        super.init(coder:aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let characteristicProfile = self.characteristicProfile {
            self.navigationItem.title = characteristicProfile.name
            self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.plain, target:nil, action:nil)
        }
    }
    
    override func viewWillAppear(_ animated:Bool) {
        self.tableView.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func prepare(for segue:UIStoryboardSegue, sender:Any!) {
    }
    
    // UITableViewDataSource
    override func numberOfSections(in tableView:UITableView) -> Int {
        return 1
    }
    
    override func tableView(_:UITableView, numberOfRowsInSection section:Int) -> Int {
        if let values = self.values {
            return values.count
        } else {
            return 0
        }
    }
    
    override func tableView(_ tableView:UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MainStoryboard.serviceCharacteristicProfileValueCell, for: indexPath) as! CharacteristicValueCell
        if let values = self.values {
            let characteristicValueNames = Array(values.keys)
            let characteristicValues = Array(values.values)
            cell.valueNameLabel.text = characteristicValueNames[indexPath.row]
            cell.valueLable.text = characteristicValues[indexPath.row]
        }
        return cell
    }
    
}
