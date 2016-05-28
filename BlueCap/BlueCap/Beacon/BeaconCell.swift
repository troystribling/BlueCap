//
//  BeaconCell.swift
//  BlueCap
//
//  Created by Troy Stribling on 9/17/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import UIKit

class BeaconCell: UITableViewCell {
    @IBOutlet var proximityUUIDLabel    : UILabel!
    @IBOutlet var majorLabel            : UILabel!
    @IBOutlet var minorLabel            : UILabel!
    @IBOutlet var proximityLabel        : UILabel!
    @IBOutlet var accuracyLabel         : UILabel!
    @IBOutlet var rssiLabel             : UILabel!
}
