//
//  Miscellaneous.swift
//  Pods
//
//  Created by Troy Stribling on 1/25/17.
//
//

import Foundation

func weakSuccess<T: AnyObject>(_ value: T, sreamPromise: StreamPromise<T?>?) {
    { [ weak value] in sreamPromise?.success(value) }()
}

func weakSuccess<T: AnyObject>(_ value: T, sreamPromise: StreamPromise<T?>) {
    { [ weak value] in sreamPromise.success(value) }()
}

func weakSuccess<T: AnyObject>(_ value: T, promise: Promise<T?>?) {
    { [ weak value] in promise?.success(value) }()
}

func weakSuccess<T: AnyObject>(_ value: T, promise: Promise<T?>) {
    { [ weak value] in promise.success(value) }()
}
