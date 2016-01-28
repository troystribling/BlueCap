//
//  FLLogger.swift
//  FutureLocation
//
//  Created by Troy Stribling on 2/22/15.
//  Copyright (c) 2015 Troy Stribling. The MIT License (MIT).
//
import Foundation

public class FLLogger {
    public class func debug(message:String? = nil, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__) {
#if DEBUG
        if let message = message {
            print("\(file):\(function):\(line): \(message)")
        } else {
            print("\(file):\(function):\(line)")
        }
#endif
    }
    
}
