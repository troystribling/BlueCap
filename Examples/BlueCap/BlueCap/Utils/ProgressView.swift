//
//  ProgressView.swift
//  BlueCap
//
//  Created by Troy Stribling on 7/20/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import UIKit
import BlueCapKit

class ProgressView : UIView {
    
    let BACKGROUND_ALPHA: CGFloat = 0.6
    let DISPLAY_REMOVE_DURATION: TimeInterval = 0.5
    
    var activityIndicator: UIActivityIndicatorView!
    var backgroundView: UIView!

    var displayed = false
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
    }
    
    override init(frame:CGRect) {
        super.init(frame:frame)
        self.activityIndicator = UIActivityIndicatorView(activityIndicatorStyle:UIActivityIndicatorViewStyle.whiteLarge)
        self.activityIndicator.center = self.center
        self.backgroundView = UIView(frame:frame)
        self.backgroundView.backgroundColor = UIColor.black
        self.backgroundView.alpha = BACKGROUND_ALPHA
        self.addSubview(self.backgroundView)
        self.addSubview(self.activityIndicator)
    }
    
    convenience init() {
        self.init(frame:UIScreen.main.bounds)
    }
    
    func show() {
        if let keyWindow =  UIApplication.shared.keyWindow {
            self.show(keyWindow)
        }
    }
    
    func show(_ view:UIView) {
        guard !displayed else {
            return
        }
        self.displayed = true
        self.activityIndicator.startAnimating()
        view.addSubview(self)
    }
    
    func remove() -> Future<Void> {
        guard displayed else {
            return Future(value: ())
        }
        let promise = Promise<Void>()
        self.displayed = false
        UIView.animate(withDuration: DISPLAY_REMOVE_DURATION, animations: { [weak self] in
            self?.alpha = 0.0
        }, completion:{ [weak self] finished in
            promise.success(())
            self?.removeFromSuperview()
            self?.alpha = 1.0
        })
        return promise.future
    }
}
