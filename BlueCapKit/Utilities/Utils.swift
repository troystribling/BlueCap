//
//  Utils.swift
//  BlueCap
//
//  Created by Troy Stribling on 9/3/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation

func applyOption(function:(()->())?) {
    if let function = function {
        function()
    }
}
