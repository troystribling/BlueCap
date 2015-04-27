//
//  Connector.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/14/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation

public enum ConnectionEvent {
    case Connect, Timeout, Disconnect, ForceDisconnect, Failed, GiveUp
}

public class Connectorator<T:PeripheralWrappable> {

    private var timeoutCount    = 0
    private var disconnectCount = 0
    
    private let promise : StreamPromise<(T, ConnectionEvent)>

    public var timeoutRetries           = -1
    public var disconnectRetries        = -1
    public var connectionTimeout        = 10.0
    public var characteristicTimeout    = 10.0

    public init (capacity:Int?=nil) {
        self.promise = StreamPromise<(T, ConnectionEvent)>(capacity:capacity)
    }
    
    convenience public init(initializer:((connectorator:Connectorator) -> Void)?) {
        self.init()
        if let initializer = initializer {
            initializer(connectorator:self)
        }
    }

    convenience public init(capacity:Int, initializer:((connectorator:Connectorator) -> Void)?) {
        self.init(capacity:capacity)
        if let initializer = initializer {
            initializer(connectorator:self)
        }
    }

    public func connect() -> FutureStream<(T, ConnectionEvent)> {
        return self.promise.future
    }
    
    internal func didTimeout(peripheral:T) {
        Logger.debug()
        if self.timeoutRetries > 0 {
            if self.timeoutCount < self.timeoutRetries {
                self.callDidTimeout(peripheral)
                ++self.timeoutCount
            } else {
                self.callDidGiveUp(peripheral)
                self.timeoutCount = 0
            }
        } else {
            self.callDidTimeout(peripheral)
        }
    }

    internal func didDisconnect(peripheral:T) {
        Logger.debug()
        if self.disconnectRetries > 0 {
            if self.disconnectCount < self.disconnectRetries {
                ++self.disconnectCount
                self.callDidDisconnect(peripheral)
            } else {
                self.disconnectCount = 0
                self.callDidGiveUp(peripheral)
            }
        } else {
            self.callDidDisconnect(peripheral)
        }
    }
    
    internal func didForceDisconnect(peripheral:T) {
        Logger.debug()
        self.promise.success((peripheral, ConnectionEvent.ForceDisconnect))
    }
    
    internal func didConnect(peripheral:T) {
        Logger.debug()
        self.promise.success((peripheral, ConnectionEvent.Connect))
    }
    
    internal func didFailConnect(peripheral:T) {
        Logger.debug()
        self.promise.success((peripheral, ConnectionEvent.Failed))
    }

    internal func callDidTimeout(peripheral:T) {
        self.promise.success((peripheral, ConnectionEvent.Timeout))
    }
    
    internal func callDidDisconnect(peripheral:T) {
        self.promise.success((peripheral, ConnectionEvent.Disconnect))
    }
    
    internal func callDidGiveUp(peripheral:T) {
        self.promise.success((peripheral, ConnectionEvent.GiveUp))
    }
    
    internal func didHaveConnectError(error:NSError) {
        Logger.debug()
        self.promise.failure(error)
    }

}