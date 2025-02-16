// Runner.swift
// Copyright (c) 2024 FastlaneTools

//
//  ** NOTE **
//  This file is provided by fastlane and WILL be overwritten in future updates
//  If you want to add extra functionality to this project, create a new file in a
//  new group so that it won't be marked for upgrade
//

import Foundation

let logger: Logger = .init()

public let runner: Runner = .init()

public func desc(_: String) {
    // no-op, this is handled in fastlane/lane_list.rb
}

public class Runner {
    private var thread: Thread!
    private var socketClient: SocketClient!
    private let dispatchGroup = DispatchGroup()
    private var returnValue: String? // lol, so safe
    private var currentlyExecutingCommand: RubyCommandable?
    private var shouldLeaveDispatchGroupDuringDisconnect = false
    private var executeNext: AtomicDictionary<String, Bool> = {
        if #available(macOS 10.12, *) {
            return UnfairAtomicDictionary<String, Bool>()
        } else {
            return OSSPinAtomicDictionary<String, Bool>()
        }
    }()

    public func executeCommand(_ command: RubyCommandable) -> String {
        dispatchGroup.enter()
        currentlyExecutingCommand = command
        socketClient.send(rubyCommand: command)

        let secondsToWait = DispatchTimeInterval.seconds(SocketClient.defaultCommandTimeoutSeconds)
        // swiftformat:disable:next redundantSelf
        let timeoutResult = Self.waitWithPolling(self.executeNext[command.id], toEventually: { $0 == true }, timeout: SocketClient.defaultCommandTimeoutSeconds)
        executeNext.removeValue(forKey: command.id)
        let failureMessage = "command didn't execute in: \(SocketClient.defaultCommandTimeoutSeconds) seconds"
        let success = testDispatchTimeoutResult(timeoutResult, failureMessage: failureMessage, timeToWait: secondsToWait)
        guard success else {
            log(message: "command timeout")
            preconditionFailure()
        }

        if let _returnValue = returnValue {
            return _returnValue
        } else {
            return ""
        }
    }

    static func waitWithPolling<T>(_ expression: @autoclosure @escaping () throws -> T, toEventually predicate: @escaping (T) -> Bool, timeout: Int, pollingInterval: DispatchTimeInterval = .milliseconds(4)) -> DispatchTimeoutResult {
        func memoizedClosure<T>(_ closure: @escaping () throws -> T) -> (Bool) throws -> T {
            var cache: T?
            return { withoutCaching in
                if withoutCaching || cache == nil {
                    cache = try closure()
                }
                guard let cache = cache else {
                    preconditionFailure()
                }

                return cache
            }
        }

        let runLoop = RunLoop.current
        let timeoutDate = Date(timeInterval: TimeInterval(timeout), since: Date())
        var fulfilled = false
        let _expression = memoizedClosure(expression)
        repeat {
            do {
                let exp = try _expression(true)
                fulfilled = predicate(exp)
            } catch {
                fatalError("Error raised \(error.localizedDescription)")
            }
            if !fulfilled {
                runLoop.run(until: Date(timeIntervalSinceNow: pollingInterval.timeInterval))
            } else {
                break
            }
        } while Date().compare(timeoutDate) == .orderedAscending

        if fulfilled {
            return .success
        } else {
            return .timedOut
        }
    }
}

// Handle threading stuff
extension Runner {
    func startSocketThread(port: UInt32) {
        let secondsToWait = DispatchTimeInterval.seconds(SocketClient.connectTimeoutSeconds)

        dispatchGroup.enter()

        socketClient = SocketClient(port: port, commandTimeoutSeconds: timeout, socketDelegate: self)
        thread = Thread(target: self, selector: #selector(startSocketComs), object: nil)
        guard let thread = thread else {
            preconditionFailure("Thread did not instantiate correctly")
        }

        thread.name = "socket thread"
        thread.start()

        let connectTimeout = DispatchTime.now() + secondsToWait
        let timeoutResult = dispatchGroup.wait(timeout: connectTimeout)

        let failureMessage = "couldn't start socket thread in: \(SocketClient.connectTimeoutSeconds) seconds"
        let success = testDispatchTimeoutResult(timeoutResult, failureMessage: failureMessage, timeToWait: secondsToWait)
        guard success else {
            log(message: "socket thread timeout")
            preconditionFailure()
        }
    }

    func disconnectFromFastlaneProcess() {
        shouldLeaveDispatchGroupDuringDisconnect = true
        dispatchGroup.enter()
        socketClient.sendComplete()

        let connectTimeout = DispatchTime.now() + 2
        _ = dispatchGroup.wait(timeout: connectTimeout)
    }

    @objc func startSocketComs() {
        guard let socketClient = socketClient else {
            return
        }

        socketClient.connectAndOpenStreams()
        dispatchGroup.leave()
    }

    private func testDispatchTimeoutResult(_ timeoutResult: DispatchTimeoutResult, failureMessage: String, timeToWait _: DispatchTimeInterval) -> Bool {
        switch timeoutResult {
        case .success:
            return true
        case .timedOut:
            log(message: "timeout: \(failureMessage)")
            return false
        }
    }
}

extension Runner: SocketClientDelegateProtocol {
    func commandExecuted(serverResponse: SocketClientResponse, completion: (SocketClient) -> Void) {
        switch serverResponse {
        case let .success(returnedObject, closureArgumentValue):
            verbose(message: "command executed")
            returnValue = returnedObject
            if let command = currentlyExecutingCommand as? RubyCommand {
                if let closureArgumentValue = closureArgumentValue, !closureArgumentValue.isEmpty {
                    command.performCallback(callbackArg: closureArgumentValue, socket: socketClient) {
                        self.executeNext[command.id] = true
                    }
                } else {
                    executeNext[command.id] = true
                }
            }
            dispatchGroup.leave()
            completion(socketClient)
        case .clientInitiatedCancelAcknowledged:
            verbose(message: "server acknowledged a cancel request")
            dispatchGroup.leave()
            if let command = currentlyExecutingCommand as? RubyCommand {
                executeNext[command.id] = true
            }
            completion(socketClient)
        case .alreadyClosedSockets, .connectionFailure, .malformedRequest, .malformedResponse, .serverError:
            log(message: "error encountered while executing command:\n\(serverResponse)")
            dispatchGroup.leave()
            if let command = currentlyExecutingCommand as? RubyCommand {
                executeNext[command.id] = true
            }
            completion(socketClient)
        case let .commandTimeout(timeout):
            log(message: "Runner timed out after \(timeout) second(s)")
        }
    }

    func connectionsOpened() {
        DispatchQueue.main.async {
            verbose(message: "connected!")
        }
    }

    func connectionsClosed() {
        DispatchQueue.main.async {
            if let thread = self.thread {
                thread.cancel()
            }
            self.thread = nil
            self.socketClient.closeSession()
            self.socketClient = nil
            verbose(message: "connection closed!")
            if self.shouldLeaveDispatchGroupDuringDisconnect {
                self.dispatchGroup.leave()
            }
            exit(0)
        }
    }
}

class Logger {
    enum LogMode {
        init(logMode: String) {
            switch logMode {
            case "normal", "default":
                self = .normal
            case "verbose":
                self = .verbose
            default:
                logger.log(message: "unrecognized log mode: \(logMode), defaulting to 'normal'")
                self = .normal
            }
        }

        case normal
        case verbose
    }

    public static var logMode: LogMode = .normal

    func log(message: String) {
        let timestamp = NSDate().timeIntervalSince1970
        print("[\(timestamp)]: \(message)")
    }

    func verbose(message: String) {
        if Logger.logMode == .verbose {
            let timestamp = NSDate().timeIntervalSince1970
            print("[\(timestamp)]: \(message)")
        }
    }
}

func log(message: String) {
    logger.log(message: message)
}

func verbose(message: String) {
    logger.verbose(message: message)
}

private extension DispatchTimeInterval {
    var timeInterval: TimeInterval {
        var result: TimeInterval = 0
        switch self {
        case let .seconds(value):
            result = TimeInterval(value)
        case let .milliseconds(value):
            result = TimeInterval(value) * 0.001
        case let .microseconds(value):
            result = TimeInterval(value) * 0.000_001
        case let .nanoseconds(value):
            result = TimeInterval(value) * 0.000_000_001
        case .never:
            fatalError()
        @unknown default:
            fatalError()
        }
        return result
    }
}

// Please don't remove the lines below
// They are used to detect outdated files
// FastlaneRunnerAPIVersion [0.9.2]
