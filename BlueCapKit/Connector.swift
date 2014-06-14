//
//  Connector.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/14/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation

class Connector {

    let timoutRetries : Int?
    let disconnectRetries : Int?
    
    var timeoutCount = 0
    var disconnectCount = 0
    
    init(initConnector:(connector:Connector) -> ()) {
        initConnector(connector:self)
    }
    
    convenience init(timeoutRetries timoutRetries:Int, disconnectRetries:Int, initConnector:(connector:Connector) -> ()) {
        self.init(initConnector)
        self.timoutRetries = timoutRetries
        self.disconnectRetries = disconnectRetries
    }
    
    func onTimeout(peripheral:Peripheral) {
    }
    
    func onDisconnect(peripheral:Peripheral) {
    }
    
    func didTimeout(peripheral:Peripheral) {
    }
    
    func didDisconnect(peripheral:Peripheral) {
    }
}