//
//  NameUUIDCell.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/22/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import UIKit
import BlueCapKit

class NameUUIDCell : UITableViewCell {
    
    @IBOutlet var nameLabel : UILabel!
    @IBOutlet var uuidLabel : UILabel!
    var nameLableFrame      : CGRect?
    var uuidLabelFrame      : CGRect?
    var accessoryTypeShown  = true

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
                    if self.accessoryTypeShown {
                        self.accessoryType = UITableViewCellAccessoryType.DetailButton
                    }
                }
            }
        } else {
            self.nameLableFrame = self.nameLabel.frame
            self.uuidLabelFrame = self.uuidLabel.frame
            self.accessoryTypeShown = self.accessoryType != UITableViewCellAccessoryType.None
        }
        super.layoutSubviews()
    }

}
