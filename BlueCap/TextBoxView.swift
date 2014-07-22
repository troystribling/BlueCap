//
//  TextBoxView.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/20/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import UIKit
import BlueCapKit

class TextBoxView : UIView {
    
    let TEXTBOX_FONT_SIZE       : CGFloat = 21.0
    let TEXTBOX_ALPHA           : CGFloat = 0.5
    let TEXTBOX_BORDER_WIDTH    : CGFloat = 0.0
    let DISPLAY_MESSAGE_XOFFEST : CGFloat = 15.0
    let DISPLAY_MESSAGE_YOFFEST : CGFloat = 10.0
    
    let textLabel       : UILabel!
    let backgroundView  : UIView!
    
    init(text:String, width:Float) {
        let size = (text as NSString).sizeWithAttributes([NSFontAttributeName: UIFont.systemFontOfSize(TEXTBOX_FONT_SIZE)])
        Logger.debug("SIZE:\(size)")
        let textRect = CGRectMake(DISPLAY_MESSAGE_XOFFEST, DISPLAY_MESSAGE_YOFFEST, size.width, size.height)
        let viewRect = CGRectMake(0.0, 0.0, size.width + 2.0 * DISPLAY_MESSAGE_XOFFEST, size.height + 2.0 * DISPLAY_MESSAGE_YOFFEST)
        super.init(frame:viewRect)
        self.textLabel = UILabel(frame:textRect)
        self.backgroundView = UIView(frame:self.frame)
    }
    
    // PRIVATE
    func addViewsWithText(text:String) {
        self.textLabel.text = text
        self.textLabel.textColor = UIColor.whiteColor()
        self.textLabel.font = UIFont.systemFontOfSize(TEXTBOX_FONT_SIZE)
        self.textLabel.backgroundColor = UIColor.clearColor()
        self.textLabel.alpha = 1.0
        self.textLabel.numberOfLines = 0
        self.textLabel.textAlignment = NSTextAlignment.Center
        self.textLabel.lineBreakMode = NSLineBreakMode.ByWordWrapping
        
        self.backgroundView.alpha = TEXTBOX_ALPHA
        self.backgroundView.backgroundColor = UIColor.blackColor()
        self.backgroundView.layer.borderWidth = TEXTBOX_BORDER_WIDTH
        self.backgroundView.layer.borderColor = UIColor.whiteColor().CGColor
        
        self.addSubview(self.backgroundView)
        self.addSubview(self.textLabel)
    }
}
