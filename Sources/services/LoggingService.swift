/*
 Copyright 2020 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

import Foundation

/// Represents the interface of the logging service
public protocol LoggingService {
    /// Logs a message
    /// - Parameters:
    ///   - level: One of the message level identifiers, e.g., DEBUG
    ///   - label: Name of a label to localize message
    ///   - message: The string message
    func log(level: LogLevel, label: String, message: String)
}

/// An enum type representing different levels of logging used by the SDK.
public enum LogLevel: Int {
    case trace = 1
    case debug
    case warning
    case error
}