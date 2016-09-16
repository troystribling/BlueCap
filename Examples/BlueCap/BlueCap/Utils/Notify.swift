//
//  Notify.swift
//  BlueCap
//
//  Created by Troy Stribling on 9/24/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import UIKit

class Notify {
    
    class func resetEventCount() {
        eventCount = 0;
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    
    class func withMessage(_ message:String) {
        if UIApplication.shared.applicationState != .active && self.getEnabled(){
            eventCount += 1
            let localNotification = UILocalNotification()
            localNotification.alertBody = message
            localNotification.soundName = UILocalNotificationDefaultSoundName
            localNotification.applicationIconBadgeNumber = eventCount
            UIApplication.shared.presentLocalNotificationNow(localNotification)
        }

    }
    
    class func setEnable(_ enabled:Bool = true) {
        UserDefaults.standard.set(enabled, forKey:"notifications")
    }
    
    class func getEnabled() -> Bool {
        return UserDefaults.standard.bool(forKey: "notifications")
    }
    
}

var eventCount = 0
