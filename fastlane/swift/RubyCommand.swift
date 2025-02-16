// RubyCommand.swift
// Copyright (c) 2024 FastlaneTools

//
//  ** NOTE **
//  This file is provided by fastlane and WILL be overwritten in future updates
//  If you want to add extra functionality to this project, create a new file in a
//  new group so that it won't be marked for upgrade
//

import Foundation

public struct RubyCommand: RubyCommandable {
    public var type: CommandType { return .action }

    public init(commandID: String, methodName: String, className: String?, args: [Argument]) {
        self.commandID = commandID
        self.methodName = methodName
        self.className = className
        self.args = args
    }

    public struct Argument {
        public enum ArgType {
            case stringClosure

            var typeString: String {
                switch self {
                case .stringClosure:
                    return "string_closure" // this should match when is in ruby's SocketServerActionCommandExecutor
                }
            }
        }

        let name: String
        public let value: Any?
        let type: ArgType?

        public init(name: String, value: Any?, type: ArgType? = nil) {
            self.name = name
            self.value = value
            self.type = type
        }

        var hasValue: Bool {
            return value != nil
        }

        var json: String {
            if let someValue = value {
                let typeJson: String
                if let type = type {
                    typeJson = ", \"value_type\" : \"\(type.typeString)\""
                } else {
                    typeJson = ""
                }

                if type == .stringClosure {
                    return "{\"name\" : \"\(name)\", \"value\" : \"ignored_for_closure\"\(typeJson)}"
                } else if let array = someValue as? [String] {
                    return "{\"name\" : \"\(name)\", \"value\" : \(array)\(typeJson)}"
                } else if let hash = someValue as? [String: Any] {
                    let jsonData = try! JSONSerialization.data(withJSONObject: hash, options: [])
                    let jsonString = String(data: jsonData, encoding: .utf8)!
                    return "{\"name\" : \"\(name)\", \"value\" : \(jsonString)\(typeJson)}"
                } else {
                    let dictionary = [
                        "name": name,
                        "value": someValue,
                    ]
                    let jsonData = try! JSONSerialization.data(withJSONObject: dictionary, options: [])
                    let jsonString = String(data: jsonData, encoding: .utf8)!
                    return jsonString
                }
            } else {
                // Just exclude this arg if it doesn't have a value
                return ""
            }
        }
    }

    let commandID: String
    let methodName: String
    let className: String?
    let args: [Argument]
    public let id: String = UUID().uuidString

    var closure: ((String) -> Void)? {
        let callbacks = args.filter { ($0.type != nil) && $0.type == .stringClosure }
        guard let callback = callbacks.first else {
            return nil
        }

        guard let callbackArgValue = callback.value else {
            return nil
        }

        guard let callbackClosure = callbackArgValue as? ((String) -> Void) else {
            return nil
        }
        return callbackClosure
    }

    func callbackClosure(_ callbackArg: String) -> ((String) -> Void)? {
        // WARNING: This will perform the first callback it receives
        let callbacks = args.filter { ($0.type != nil) && $0.type == .stringClosure }
        guard let callback = callbacks.first else {
            verbose(message: "received call to performCallback with \(callbackArg), but no callback available to perform")
            return nil
        }

        guard let callbackArgValue = callback.value else {
            verbose(message: "received call to performCallback with \(callbackArg), but callback is nil")
            return nil
        }

        guard let callbackClosure = callbackArgValue as? ((String) -> Void) else {
            verbose(message: "received call to performCallback with \(callbackArg), but callback type is unknown \(callbackArgValue.self)")
            return nil
        }
        return callbackClosure
    }

    func performCallback(callbackArg: String, socket: SocketClient, completion: @escaping () -> Void) {
        verbose(message: "Performing callback with: \(callbackArg)")
        socket.leave()
        callbackClosure(callbackArg)?(callbackArg)
        completion()
    }

    public var commandJson: String {
        let argsArrayJson = args
            .map { $0.json }
            .filter { $0 != "" }

        let argsJson: String?
        if !argsArrayJson.isEmpty {
            argsJson = "\"args\" : [\(argsArrayJson.joined(separator: ","))]"
        } else {
            argsJson = nil
        }

        let commandIDJson = "\"commandID\" : \"\(commandID)\""
        let methodNameJson = "\"methodName\" : \"\(methodName)\""

        var jsonParts = [commandIDJson, methodNameJson]
        if let argsJson = argsJson {
            jsonParts.append(argsJson)
        }

        if let className = className {
            let classNameJson = "\"className\" : \"\(className)\""
            jsonParts.append(classNameJson)
        }

        let commandJsonString = "{\(jsonParts.joined(separator: ","))}"

        return commandJsonString
    }
}

// Please don't remove the lines below
// They are used to detect outdated files
// FastlaneRunnerAPIVersion [0.9.2]
