//
//  PeripheralManagerCell.swift
//  BlueCap
//
//  Created by Troy Stribling on 8/11/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import UIKit

class PeripheralManagerCell : UITableViewCell {

    @IBOutlet var nameLable : UILabel!
    var nameLableFrame      : CGRect?
    
    override func layoutSubviews() {
        if let nameLableFrame = self.nameLableFrame {
            if self.showingDeleteConfirmation {
                self.accessoryType = UITableViewCellAccessoryType.None
                self.nameLable.frame = CGRectMake(nameLableFrame.origin.x+80.0, nameLableFrame.origin.y, nameLableFrame.size.width-80.0, nameLableFrame.size.height)
            } else {
                self.nameLable.frame = nameLableFrame
                self.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
            }
        } else {
            self.nameLableFrame = self.nameLable.frame
        }
        super.layoutSubviews()
    }
}
