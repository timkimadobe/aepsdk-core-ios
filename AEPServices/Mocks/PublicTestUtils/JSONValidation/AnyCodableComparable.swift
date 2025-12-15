/*
 Copyright 2025 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
*/

import AEPServices
import Foundation

// MARK: - AnyCodableComparable Protocol

/// A protocol that enables conversion of conforming types into `AnyCodable` format.
public protocol AnyCodableComparable {
    /// Converts the conforming type to an optional `AnyCodable` instance.
    ///
    /// - Returns: An optional `AnyCodable` instance representing the conforming type, or `nil` if the conversion fails.
    func toAnyCodable() -> AnyCodable?
}

// MARK: - AnyCodableComparable Conformances

extension Optional: AnyCodableComparable where Wrapped: AnyCodableComparable {
    public func toAnyCodable() -> AnyCodable? {
        switch self {
        case .some(let value):
            return value.toAnyCodable()
        case .none:
            return nil
        }
    }
}

extension Dictionary: AnyCodableComparable where Key == String, Value: Any {
    public func toAnyCodable() -> AnyCodable? {
        // Convert self to [String: Any?] - this is a no-op for [String: Any] and
        // correctly wraps the value in an optional for [String: Any?]
        let optionalValueDict = self.mapValues { $0 as Any? }
        return AnyCodable(AnyCodable.from(dictionary: optionalValueDict))
    }
}

extension String: AnyCodableComparable {
    public func toAnyCodable() -> AnyCodable? {
        guard let data = self.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(AnyCodable.self, from: data)
    }
}

extension AnyCodable: AnyCodableComparable {
    public func toAnyCodable() -> AnyCodable? {
        return self
    }
}

extension NetworkRequest: AnyCodableComparable {
    public func toAnyCodable() -> AnyCodable? {
        guard let payloadAsDictionary = try? JSONSerialization.jsonObject(with: self.connectPayload, options: []) as? [String: Any] else {
            return nil
        }
        return payloadAsDictionary.toAnyCodable()
    }
}
