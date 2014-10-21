//
//  ProgressView.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/20/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import UIkit

class ProgressView : UIView {
    
    let BACKGROUND_ALPHA        : CGFloat           = 0.6
    let DISPLAY_REMOVE_DURATION : NSTimeInterval    = 0.5
    
    var activityIndicator   : UIActivityIndicatorView!
    var backgroundView      : UIView!
    
    var displayed = false
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
    }
    
    override init(frame:CGRect) {
        super.init(frame:frame)
        self.activityIndicator = UIActivityIndicatorView(activityIndicatorStyle:UIActivityIndicatorViewStyle.WhiteLarge)
        self.activityIndicator.center = self.center
        self.backgroundView = UIView(frame:frame)
        self.backgroundView.backgroundColor = UIColor.blackColor()
        self.backgroundView.alpha = BACKGROUND_ALPHA
        self.addSubview(self.backgroundView)
        self.addSubview(self.activityIndicator)
    }
    
    override convenience init() {
        self.init(frame:UIScreen.mainScreen().bounds)
    }
    
    func show() {
        if let keyWindow =  UIApplication.sharedApplication().keyWindow {
            self.show(keyWindow)
        }
    }
    
    func show(view:UIView) {
        if !self.displayed {
            self.displayed = true
            self.activityIndicator.startAnimating()
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
