//
//  Logger.swift
//  FutureLocation
//
//  Created by Troy Stribling on 2/22/15.
//  Copyright (c) 2015 gnos.us. All rights reserved.
//
import Foundation

public class Logger {
    public class func debug(message:String) {
        #if DEBUG
            println("\(message)")
        #endif
    }
    
}
