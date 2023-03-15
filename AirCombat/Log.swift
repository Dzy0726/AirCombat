//
//  Log.swift
//  (Simple-) Logging functionality
//
//  Created by 董震宇 on 2020/12/1.
//

import Foundation
import SceneKit

enum LogSeverity : Int {
    case debug = 0
    case info = 1
    case warning = 2
    case error = 3
    case none = 4
}

public class LogInfo: NSObject {
    static var _severity = LogSeverity.debug
    
    // -----------------------------------------------------------------------------
    // MARK: - Properties
    
    static var severity: LogSeverity {
        get {
            return _severity
        }
        set(value) {
            _severity = value
        }
    }
    
    // -------------------------------------------------------------------------
    // MARK: - Logging severity
        
    static func error(message: String) {
        if (LogSeverity.error.rawValue >= LogInfo.severity.rawValue) {
            LogInfo.log(message: message, severity: "⛔️")
        }
    }
    
    // -------------------------------------------------------------------------
    
    static func warning(message: String) {
        if (LogSeverity.warning.rawValue >= LogInfo.severity.rawValue) {
            LogInfo.log(message: message, severity: "⚠️")
        }
    }

    // -------------------------------------------------------------------------

    static func info(message: String) {
        if (LogSeverity.info.rawValue >= LogInfo.severity.rawValue) {
            LogInfo.log(message: message, severity: "▷")
        }
    }
    
    // -------------------------------------------------------------------------

    static func debug(message: String) {
        if (LogSeverity.debug.rawValue >= LogInfo.severity.rawValue) {
            LogInfo.log(message: message, severity: "→")
        }
    }

    // -------------------------------------------------------------------------
    // MARK: - Write logs
    
    private static func log(message: String, severity: String) {
        LogInfo.write(message: "\(severity) \(message)")
    }
    
    // -------------------------------------------------------------------------
   
    public static func write(message: String) {
        print(message)
    }
    
    // -------------------------------------------------------------------------

}

// -----------------------------------------------------------------------------
// MARK: - Short functions

func Error(_ message: String,  _ args: CVarArg...) {
    let str = String(format: message, arguments: args)
    LogInfo.error(message: str)
}

// -----------------------------------------------------------------------------

func Warning(_ message: String,  _ args: CVarArg...) {
    let str = String(format: message, arguments: args)
    LogInfo.warning(message: str)
}

// -----------------------------------------------------------------------------

func Info(_ message: String,  _ args: CVarArg...) {
    let str = String(format: message, arguments: args)
    LogInfo.info(message: str)
}

// -----------------------------------------------------------------------------

func Debug(_ message: String,  _ args: CVarArg...) {
    let str = String(format: message, arguments: args)
    LogInfo.debug(message: str)
}

// -----------------------------------------------------------------------------
