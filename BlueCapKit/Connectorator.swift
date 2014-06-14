//
//  Connector.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/14/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation

class Connectorator {

    let timeoutRetries : Int?
    let disconnectRetries : Int?
    
    var onTimeout       : ((peripheral:Peripheral) -> ())?
    var onDisconnect    : ((peripheral:Peripheral) -> ())?
    var onConnect       : ((peripheral:Peripheral) -> ())?
    var onFailConnect   : ((peripheral:Peripheral, error:NSError!) -> ())?
    var onGiveup        : ((peripheral:Peripheral) -> ())?
    
    var timeoutCount = 0
    var disconnectCount = 0
    
    // application interface
    init () {
    }
    
    init(initConnector:(connector:Connectorator) -> ()) {
        initConnector(connector:self)
    }
    
    convenience init(timeoutRetries:Int, disconnectRetries:Int, initConnector:(connector:Connectorator) -> ()) {
        self.init(initConnector)
        self.timeoutRetries = timeoutRetries
        self.disconnectRetries = disconnectRetries
    }
    
    func onTimeout(onTimeout:(peripheral:Peripheral)->()) {
        self.onTimeout = onTimeout
    }
    
    func onDisconnect(onDisconnect:(peripheral:Peripheral)->()) {
        self.onDisconnect = onDisconnect
    }
    
    func onConnect(onConnect:(peripheral:Peripheral) -> ()) {
        self.onConnect = onConnect
    }

    func onFailConnect(onFailConnect:(peripheral:Peripheral, error:NSError!) -> ()) {
        self.onFailConnect = onFailConnect
    }

    func onGiveup(onGiveup:(peripheral:Peripheral) -> ()) {
        self.onGiveup = onGiveup
    }
    
    // internal interface
    func didTimeout(peripheral:Peripheral) {
        if let onTimeout = self.onTimeout {
        }
    }
    
    func didDisconnect(peripheral:Peripheral) {
        if let onDisconnect = self.onDisconnect {
        }
    }
    
    func didConnect(peripheral:Peripheral) {
        if let onConnect = self.onConnect {
        }
    }
    
    func didFailConnect(peripheral:Peripheral, error:NSError!) {
        if let onFailConnect = self.onFailConnect {
            
        }
    }
}