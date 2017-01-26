//
//  Miscellaneous.swift
//  Pods
//
//  Created by Troy Stribling on 1/25/17.
//
//

import Foundation

func weak<T: AnyObject>(_ value: T, sreamPromise: StreamPromise<T?>?) {
    { [ weak value] in sreamPromise?.success(value) }()
}
