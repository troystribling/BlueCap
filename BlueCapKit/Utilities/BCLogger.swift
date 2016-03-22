//
//  BCLogger.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/8/14.
//  Copyright (c) 2014 Troy Stribling. The MIT License (MIT).
//

import Foundation

// MARK: - StderrOutputStream -
public struct StderrOutputStream: OutputStreamType {

    // Support for file redirection back to console
    private static var fpos : fpos_t = 0
    private static var fd = dup(fileno(stderr))
    private static var isRedirected_ = false
    public static var isRedirected : Bool {return isRedirected_}

    // When false, the output file is rewritten and not appended
    private static var appendToFile = true

    // When true, output is echoed to stdout
    public static var echo = false

    // When non-nil, output is redirected to the specified file path
    public static func redirectOutputToPath(path: String?) {
        if let path = path {
            if !isRedirected {
                // Set up if this is new redirection
                fflush(stderr)
                let pos = UnsafeMutablePointer<fpos_t>.alloc(1)
                fgetpos(stderr, pos)
                fpos = pos.memory
                free(pos)
                fd = dup(fileno(stderr))
            }
            if appendToFile {
                freopen(path, "a", stderr)
            } else {
                freopen(path, "w", stderr)
            }
            isRedirected_ = true
        } else {
            if !isRedirected {
                return
            }
            fflush(stderr)
            dup2(fd, fileno(stderr))
            close(fd)
            clearerr(stderr)
            fsetpos(stderr, &fpos)
            isRedirected_ = false
        }
    }

    public func write(string: String) {
        fputs(string, stderr)
        if StderrOutputStream.echo && StderrOutputStream.isRedirected {fputs(string, stdout)}
    }
}

func amIBeingDebugged() -> Bool {
    var info = kinfo_proc()
    var mib : [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
    var size = strideofValue(info)
    let junk = sysctl(&mib, UInt32(mib.count), &info, &size, nil, 0)
    assert(junk == 0, "sysctl failed")
    return (info.kp_proc.p_flag & P_TRACED) != 0
}

public class BCLogger {
    private static let stream = StderrOutputStream()

    public class func debug(message:String? = nil, function: String = #function, file: String = #file, line: Int = #line) {
#if DEBUG
        if !amIBeingDebugged() && !StderrOutputStream.isRedirected {
            let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
            StderrOutputStream.appendToFile = false
            StderrOutputStream.redirectOutputToPath("\(documentsPath)/stderr.log")
            if let message = message {
                self.stream.write("\(NSDate()):\(file):\(function):\(line): \(message)\n")
            } else {
                self.stream.write("\(NSDate()):\(file):\(function):\(line)\n")
            }
        } else {
            if let message = message {
                print("\(file):\(function):\(line): \(message)")
            } else {
                print("\(file):\(function):\(line)")
            }
        }
#endif
    }

}
