// LaneFileProtocol.swift
// Copyright (c) 2024 FastlaneTools

//
//  ** NOTE **
//  This file is provided by fastlane and WILL be overwritten in future updates
//  If you want to add extra functionality to this project, create a new file in a
//  new group so that it won't be marked for upgrade
//

import Foundation

public protocol LaneFileProtocol: AnyObject {
    var fastlaneVersion: String { get }
    static func runLane(from fastfile: LaneFile?, named lane: String, with parameters: [String: String]) -> Bool

    func recordLaneDescriptions()
    func beforeAll(with lane: String)
    func afterAll(with lane: String)
    func onError(currentLane: String, errorInfo: String, errorClass: String?, errorMessage: String?)
}

public extension LaneFileProtocol {
    var fastlaneVersion: String { return "" } // Defaults to "" because that means any is fine
    func beforeAll(with _: String) {} // No-op by default
    func afterAll(with _: String) {} // No-op by default
    func recordLaneDescriptions() {} // No-op by default
}

@objcMembers
open class LaneFile: NSObject, LaneFileProtocol {
    private(set) static var fastfileInstance: LaneFile?
    private static var onErrorCalled = Set<String>()

    private static func trimLaneFromName(laneName: String) -> String {
        return String(laneName.prefix(laneName.count - 4))
    }

    private static func trimLaneWithOptionsFromName(laneName: String) -> String {
        return String(laneName.prefix(laneName.count - 12))
    }

    open func beforeAll(with _: String) {}

    open func afterAll(with _: String) {}

    open func onError(currentLane: String, errorInfo _: String, errorClass _: String?, errorMessage _: String?) {
        LaneFile.onErrorCalled.insert(currentLane)
    }

    private static var laneFunctionNames: [String] {
        var lanes: [String] = []
        var methodCount: UInt32 = 0
        #if !SWIFT_PACKAGE
            let methodList = class_copyMethodList(self, &methodCount)
        #else
            // In SPM we're calling this functions out of the scope of the normal binary that it's
            // being built, so *self* in this scope would be the SPM executable instead of the Fastfile
            // that we'd normally expect.
            let methodList = class_copyMethodList(type(of: fastfileInstance!), &methodCount)
        #endif
        for i in 0 ..< Int(methodCount) {
            let selName = sel_getName(method_getName(methodList![i]))
            let name = String(cString: selName)
            let lowercasedName = name.lowercased()
            if lowercasedName.hasSuffix("lane") || lowercasedName.hasSuffix("lanewithoptions:") {
                lanes.append(name)
            }
        }
        return lanes
    }

    public static var lanes: [String: String] {
        var laneToMethodName: [String: String] = [:]
        for name in laneFunctionNames {
            let lowercasedName = name.lowercased()
            if lowercasedName.hasSuffix("lane") {
                laneToMethodName[lowercasedName] = name
                let lowercasedNameNoLane = trimLaneFromName(laneName: lowercasedName)
                laneToMethodName[lowercasedNameNoLane] = name
            } else if lowercasedName.hasSuffix("lanewithoptions:") {
                let lowercasedNameNoOptions = trimLaneWithOptionsFromName(laneName: lowercasedName)
                laneToMethodName[lowercasedNameNoOptions] = name
                let lowercasedNameNoLane = trimLaneFromName(laneName: lowercasedNameNoOptions)
                laneToMethodName[lowercasedNameNoLane] = name
            }
        }

        return laneToMethodName
    }

    public static func loadFastfile() {
        if fastfileInstance == nil {
            let fastfileType: AnyObject.Type = NSClassFromString(className())!
            let fastfileAsNSObjectType: NSObject.Type = fastfileType as! NSObject.Type
            let currentFastfileInstance: Fastfile? = fastfileAsNSObjectType.init() as? Fastfile
            fastfileInstance = currentFastfileInstance
        }
    }

    public static func runLane(from fastfile: LaneFile?, named lane: String, with parameters: [String: String]) -> Bool {
        log(message: "Running lane: \(lane)")
        #if !SWIFT_PACKAGE
            // When not in SPM environment, we load the Fastfile from its `className()`.
            loadFastfile()
            guard let fastfileInstance = fastfileInstance as? Fastfile else {
                let message = "Unable to instantiate class named: \(className())"
                log(message: message)
                fatalError(message)
            }
        #else
            // When in SPM environment, we can't load the Fastfile from its `className()` because the executable is in
            // another scope, so `className()` won't be the expected Fastfile. Instead, we load the Fastfile as a Lanefile
            // in a static way, by parameter.
            guard let fastfileInstance = fastfile else {
                log(message: "Found nil instance of fastfile")
                preconditionFailure()
            }
            self.fastfileInstance = fastfileInstance
        #endif
        let currentLanes = lanes
        let lowerCasedLaneRequested = lane.lowercased()

        guard let laneMethod = currentLanes[lowerCasedLaneRequested] else {
            let laneNames = laneFunctionNames.map { laneFunctionName in
                if laneFunctionName.hasSuffix("lanewithoptions:") {
                    return trimLaneWithOptionsFromName(laneName: laneFunctionName)
                } else {
                    return trimLaneFromName(laneName: laneFunctionName)
                }
            }.joined(separator: ", ")

            let message = "[!] Could not find lane '\(lane)'. Available lanes: \(laneNames)"
            log(message: message)

            let shutdownCommand = ControlCommand(commandType: .cancel(cancelReason: .clientError), message: message)
            _ = runner.executeCommand(shutdownCommand)
            return false
        }

        // Call all methods that need to be called before we start calling lanes.
        fastfileInstance.beforeAll(with: lane)

        // We need to catch all possible errors here and display a nice message.
        _ = fastfileInstance.perform(NSSelectorFromString(laneMethod), with: parameters)

        // Call only on success.
        if LaneFile.onErrorCalled.contains(lane) {
            log(message: "Error running lane: \(lane) 😥")
            fatalError("Aborting run due to lane failure")
        }
        fastfileInstance.afterAll(with: lane)

        log(message: "Done running lane: \(lane) 🚀")
        return true
    }
}

// Please don't remove the lines below
// They are used to detect outdated files
// FastlaneRunnerAPIVersion [0.9.2]
