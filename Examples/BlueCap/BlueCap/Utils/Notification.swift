//
//  Notification.swift
//  BlueCap
//
//  Created by Troy Stribling on 9/24/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import UIKit
import UserNotifications

class Notification {
    
    static var eventCount = 0

    class func resetEventCount() {
        eventCount = 0;
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    
    class func send(_ message: String) {
        if UIApplication.shared.applicationState != .active && self.getEnabled(){
            eventCount += 1
            if #available(iOS 10.0, *) {
                let content = UNMutableNotificationContent()
                content.title = ""
                content.body = message
                content.sound = UNNotificationSound.default()
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.0, repeats: false)
                let request = UNNotificationRequest(identifier: "Immediate", content: content, trigger: trigger)
                let center = UNUserNotificationCenter.current()
                center.add(request)
            } else {
                let localNotification = UILocalNotification()
                localNotification.alertBody = message
                localNotification.soundName = UILocalNotificationDefaultSoundName
                localNotification.applicationIconBadgeNumber = eventCount
                UIApplication.shared.presentLocalNotificationNow(localNotification)
            }
        }

    }
    
    class func setEnable(_ enabled: Bool = true) {
        UserDefaults.standard.set(enabled, forKey: "notifications")
    }
    
    class func getEnabled() -> Bool {
        guard !getPermissionGranted() else {
            return false
        }
        return UserDefaults.standard.bool(forKey: "notifications")
    }

    class func setPermissionGranted(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: "permissionGranted")
    }

    class func getPermissionGranted() -> Bool {
        return UserDefaults.standard.bool(forKey: "permissionGranted")
    }

}
