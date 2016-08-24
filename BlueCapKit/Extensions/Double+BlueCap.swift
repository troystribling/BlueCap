//
//  Double+BlueCap.swift
//  BlueCapKit
//
//  Created by Troy Stribling on 11/10/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import Foundation

public extension Double {
    public func format(f: String) -> String {
        return NSString(format: "%\(f)f" as NSString , self) as String
    }
}
