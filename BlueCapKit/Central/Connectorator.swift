//
//  Connector.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/14/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation

public class Connectorator {

    private var timeoutCount    = 0
    private var disconnectCount = 0
    
    private let promise : StreamPromise<Void>

    public var timeoutRetries           = -1
    public var disconnectRetries        = -1
    public var connectionTimeout        = 10.0
    public var characteristicTimeout    = 10.0

    public init () {
        self.promise = StreamPromise<Void>()
    }

    public init (capacity:Int) {
        self.promise = StreamPromise<Void>(capacity:capacity)
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

    public func onConnect() -> FutureStream<Void> {
        return self.promise.future
    }
    
    internal func didTimeout() {
        Logger.debug()
        if self.timeoutRetries > 0 {
            if self.timeoutCount < self.timeoutRetries {
                self.callDidTimeout()
                ++self.timeoutCount
            } else {
                self.callDidGiveUp()
                self.timeoutCount = 0
            }
        } else {
            self.callDidTimeout()
        }
    }

    internal func didDisconnect() {
        Logger.debug()
        if self.disconnectRetries > 0 {
            if self.disconnectCount < self.disconnectRetries {
                ++self.disconnectCount
                self.callDidDisconnect()
            } else {
                self.disconnectCount = 0
                self.callDidGiveUp()
            }
        } else {
            self.callDidDisconnect()
        }
    }
    
    internal func didForceDisconnect() {
        Logger.debug()
        self.promise.failure(BCError.connectoratorForcedDisconnect)
    }
    
    internal func didConnect() {
        Logger.debug()
        self.promise.success()
    }
    
    internal func didFailConnect(error:NSError?) {
        Logger.debug()
        if let error = error {
            self.promise.failure(error)
        } else {
            self.promise.failure(BCError.connectoratorFailed)
        }
    }
    
    internal func callDidTimeout() {
        self.promise.failure(BCError.connectoratorTimeout)
    }
    
    internal func callDidDisconnect() {
        self.promise.failure(BCError.connectoratorDisconnect)
    }
    
    internal func callDidGiveUp() {
        self.promise.failure(BCError.connectoratorGiveUp)
    }
}