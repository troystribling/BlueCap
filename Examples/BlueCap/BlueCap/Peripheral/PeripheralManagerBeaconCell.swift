//
//  PeripheralManagerBeaconCell.swift
//  BlueCap
//
//  Created by Troy Stribling on 10/4/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import UIKit

class PeripheralManagerBeaconCell: UITableViewCell {

    @IBOutlet var uuidLabel             : UILabel!
    @IBOutlet var majorLabel            : UILabel!
    @IBOutlet var minorLabel            : UILabel!
    @IBOutlet var nameLabel             : UILabel!

    var nameLableFrame                  : CGRect?
    var uuidLabelFrame                  : CGRect?
    var configuredAccessoryType         : UITableViewCellAccessoryType?
    
}
