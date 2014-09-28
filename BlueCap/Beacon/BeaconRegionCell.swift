//
//  BeaconRegionCell.swift
//  BlueCap
//
//  Created by Troy Stribling on 9/17/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import UIKit

class BeaconRegionCell: UITableViewCell {

    @IBOutlet var nameLabel                     : UILabel!
    @IBOutlet var uuidLabel                     : UILabel!
    @IBOutlet var rangingActivityIndicator      : UIActivityIndicatorView!
    var nameLableFrame                          : CGRect?
    var uuidLabelFrame                          : CGRect?
    var configuredAccessoryType                 : UITableViewCellAccessoryType?
    
    override func layoutSubviews() {
        if let nameLableFrame = self.nameLableFrame {
            if let uuidLabelFrame = self.uuidLabelFrame {
                if self.showingDeleteConfirmation {
                    self.accessoryType = UITableViewCellAccessoryType.None
                    self.nameLabel.frame = CGRectMake(nameLableFrame.origin.x+80.0, nameLableFrame.origin.y, nameLableFrame.size.width-80.0, nameLableFrame.size.height)
                    self.uuidLabel.frame = CGRectMake(uuidLabelFrame.origin.x+80.0, uuidLabelFrame.origin.y, uuidLabelFrame.size.width-80.0, uuidLabelFrame.size.height)
                } else {
                    self.nameLabel.frame = nameLableFrame
                    self.uuidLabel.frame = uuidLabelFrame
                    if let configuredAccessoryType = self.configuredAccessoryType {
                        self.accessoryType = configuredAccessoryType
                    }
                }
            }
        } else {
            self.nameLableFrame = self.nameLabel.frame
            self.uuidLabelFrame = self.uuidLabel.frame
        }
        super.layoutSubviews()
    }
    
    func updateAccessoryType(accessory:UITableViewCellAccessoryType) {
        self.accessoryType = accessory
        self.configuredAccessoryType = accessory
    }

}
