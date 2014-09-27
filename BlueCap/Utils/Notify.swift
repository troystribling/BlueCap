//
//  Notify.swift
//  BlueCap
//
//  Created by Troy Stribling on 9/24/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import UIKit

class Notify {
    
    class func resetEventCount() {
        eventCount = 0;
        UIApplication.sharedApplication().applicationIconBadgeNumber = 0
    }
    
    class func withMessage(message:String) {
        if UIApplication.sharedApplication().applicationState != .Active && self.getEnabled(){
            eventCount += 1
            let localNotification = UILocalNotification()
            localNotification.alertBody = message
            localNotification.soundName = UILocalNotificationDefaultSoundName
            localNotification.applicationIconBadgeNumber = eventCount
            UIApplication.sharedApplication().presentLocalNotificationNow(localNotification)
        }

    }
    
    class func setEnable(enabled:Bool = true) {
        NSUserDefaults.standardUserDefaults().setBool(enabled, forKey:"notifications")
    }
    
    class func getEnabled() -> Bool {
        return NSUserDefaults.standardUserDefaults().boolForKey("notifications")
    }
    
}

var eventCount = 0
