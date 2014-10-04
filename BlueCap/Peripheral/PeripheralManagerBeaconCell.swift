//
//  PeripheralManagerBeaconCell.swift
//  BlueCap
//
//  Created by Troy Stribling on 10/4/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import UIKit

class PeripheralManagerBeaconCell: UITableViewCell {

    @IBOutlet var UUIDLabel             : UILabel!
    @IBOutlet var majorLabel            : UILabel!
    @IBOutlet var minorLabel            : UILabel!
    @IBOutlet var nameLabel             : UILabel!

    var nameLableFrame                  : CGRect?
    var uuidLabelFrame                  : CGRect?
    var configuredAccessoryType         : UITableViewCellAccessoryType?
    
}
