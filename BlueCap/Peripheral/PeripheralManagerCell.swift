//
//  PeripheralManagerCell.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/11/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import UIKit

class PeripheralManagerCell : UITableViewCell {

    @IBOutlet var nameLabel : UILabel!
    var nameLabelFrame      : CGRect?
    
    override func layoutSubviews() {
        if let nameLabelFrame = self.nameLabelFrame {
            if self.showingDeleteConfirmation {
                self.accessoryType = UITableViewCellAccessoryType.None
                self.nameLabel.frame = CGRectMake(nameLabelFrame.origin.x+80.0, nameLabelFrame.origin.y, nameLabelFrame.size.width-80.0, nameLabelFrame.size.height)
            } else {
                self.nameLabel.frame = nameLabelFrame
                self.accessoryType = UITableViewCellAccessoryType.DetailButton
            }
        } else {
            self.nameLabelFrame = self.nameLabel.frame
        }
        super.layoutSubviews()
    }
}
