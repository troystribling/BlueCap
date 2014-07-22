//
//  ProgressView.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/20/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import UIkit

class ProgressView : UIView {
    
    let DISPLAY_MESSAGE_WIDTH   : Float             = 200.0
    let BACKGROUND_ALPHA        : CGFloat           = 0.4
    let TEXTBOX_OFFSET          : CGFloat           = 20.0
    let DISPLAY_REMOVE_DURATION : NSTimeInterval    = 0.5
    
    var textBoxView     : TextBoxView!
    var backgroundView  : UIView!
    
    var displayed = false
    
    init(frame:CGRect, message:String) {
        super.init(frame:frame)
        self.textBoxView = TextBoxView(text:message, width:DISPLAY_MESSAGE_WIDTH)
        self.textBoxView.center = CGPointMake(self.center.x, self.center.y - TEXTBOX_OFFSET)
        self.backgroundView = UIView(frame:frame)
        self.backgroundView.backgroundColor = UIColor.blackColor()
        self.backgroundView.alpha = BACKGROUND_ALPHA
//        self.addSubview(self.backgroundView)
        self.addSubview(self.textBoxView)
    }
    
    convenience init(message:String) {
        self.init(frame:UIScreen.mainScreen().bounds, message:message)
    }
    
    func show(view:UIView) {
        if !self.displayed {
            self.displayed = true
            view.addSubview(self)
        }
    }
    
    func remove() {
        if self.displayed {
            self.displayed = false
            UIView.animateWithDuration(DISPLAY_REMOVE_DURATION, animations:{
                    self.alpha = 0.0
                }, completion:{(finished) in
                    self.removeFromSuperview()
                    self.alpha = 1.0
                })
        }
    }
}
