//
//  ExecutionContext.swift
//  BlueCapKit
//
//  Created by Troy Stribling on 12/3/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import Foundation

public protocol ExecutionContext {
    
    func execute(task:Void->Void)
}

public class QueueContext : ExecutionContext {
    
    public class var main : QueueContext {
        struct Static {
            static let instance = QueueContext(queue:Queue.main)
        }
        return Static.instance
    }
    
    public class var global: QueueContext {
        struct Static {
            static let instance : QueueContext = QueueContext(queue:Queue.global)
        }
        return Static.instance
    }
    
    let queue:Queue
    
    public init(queue:Queue) {
        self.queue = queue
    }
    
    public func execute(task:Void -> Void) {
        queue.async(task)
    }
}

public struct Queue {
    
    public static let main              = Queue(dispatch_get_main_queue());
    public static let global            = Queue(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0))

    internal static let simpleFutures       = Queue("us.gnos.simpleFutures")
    internal static let simpleFutureStreams = Queue("us.gnos.simpleFutureStreams")
    
    var queue: dispatch_queue_t
    
    
    public init(_ queueName:String) {
        self.queue = dispatch_queue_create(queueName, DISPATCH_QUEUE_SERIAL)
    }
    
    public init(_ queue:dispatch_queue_t) {
        self.queue = queue
    }
    
    public func sync(block:Void -> Void) {
        dispatch_sync(self.queue, block)
    }
    
    public func sync<T>(block:Void -> T) -> T {
        var result:T!
        dispatch_sync(self.queue, {
            result = block();
        });
        return result;
    }
    
    public func async(block:dispatch_block_t) {
        dispatch_async(self.queue, block);
    }
    
}



