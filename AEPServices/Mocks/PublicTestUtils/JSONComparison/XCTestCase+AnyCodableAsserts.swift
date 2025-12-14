//
// Copyright 2023 Adobe. All rights reserved.
// This file is licensed to you under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software distributed under
// the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
// OF ANY KIND, either express or implied. See the License for the specific language
// governing permissions and limitations under the License.
//

import XCTest
import AEPServices

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

// MARK: - AnyCodableAsserts Protocol

/// A protocol that provides JSON assertion methods for test cases.
public protocol AnyCodableAsserts {
    /// Asserts exact equality between two `AnyCodableComparable` instances.
    ///
    /// Both type and value must match exactly, and collections must have the same count.
    ///
    /// - Parameters:
    ///   - expected: The expected `AnyCodableComparable` to compare.
    ///   - actual: The actual `AnyCodableComparable` to compare.
    ///   - file: The file from which the method is called, used for localized assertion failures.
    ///   - line: The line from which the method is called, used for localized assertion failures.
    func assertEqual(expected: AnyCodableComparable?, actual: AnyCodableComparable?, file: StaticString, line: UInt)

    /// Performs JSON validation where only the types from the `expected` JSON are required.
    ///
    /// Values must have the same type but their literal values can differ.
    /// Both objects and arrays use extensible collections by default.
    ///
    /// - Parameters:
    ///   - expected: The expected `AnyCodableComparable` to compare.
    ///   - actual: The actual `AnyCodableComparable` to compare.
    ///   - file: The file from which the method is called, used for localized assertion failures.
    ///   - line: The line from which the method is called, used for localized assertion failures.
    func assertTypeMatch(expected: AnyCodableComparable, actual: AnyCodableComparable?, file: StaticString, line: UInt)

    /// Performs JSON validation where only the values from the `expected` JSON are required.
    ///
    /// Values must have the same type AND the same literal value.
    /// Both objects and arrays use extensible collections by default.
    ///
    /// - Parameters:
    ///   - expected: The expected `AnyCodableComparable` to compare.
    ///   - actual: The actual `AnyCodableComparable` to compare.
    ///   - file: The file from which the method is called, used for localized assertion failures.
    ///   - line: The line from which the method is called, used for localized assertion failures.
    func assertExactMatch(expected: AnyCodableComparable, actual: AnyCodableComparable?, file: StaticString, line: UInt)
}

// MARK: - AnyCodableAsserts Implementation

public extension AnyCodableAsserts where Self: XCTestCase {
    
    /// Asserts exact equality between two `AnyCodableComparable` instances.
    ///
    /// Both type and value must match exactly, and collections must have the same count.
    ///
    /// - Parameters:
    ///   - expected: The expected `AnyCodableComparable` to compare.
    ///   - actual: The actual `AnyCodableComparable` to compare.
    ///   - file: The file from which the method is called, used for localized assertion failures.
    ///   - line: The line from which the method is called, used for localized assertion failures.
    func assertEqual(expected: AnyCodableComparable?, actual: AnyCodableComparable?, file: StaticString = #file, line: UInt = #line) {
        if expected == nil && actual == nil {
            return
        }
        guard let expected = expected, let actual = actual else {
            XCTFail(
                """
                \(expected == nil ? "Expected is nil" : "Actual is nil") and \(expected == nil ? "Actual" : "Expected") is non-nil.
                Expected: \(String(describing: expected))
                Actual: \(String(describing: actual))
                """,
                file: file,
                line: line)
            return
        }
        // Exact equality is exact match with equal count enforced on the entire tree
        assertJSON(expected: expected, actual: actual, file: file, line: line)
            .equalCount(scope: .subtree)
            .validate()
    }

    /// Performs JSON validation where only the types from the `expected` JSON are required.
    ///
    /// Values must have the same type but their literal values can differ.
    /// Both objects and arrays use extensible collections by default.
    ///
    /// - Parameters:
    ///   - expected: The expected `AnyCodableComparable` to compare.
    ///   - actual: The actual `AnyCodableComparable` to compare.
    ///   - file: The file from which the method is called, used for localized assertion failures.
    ///   - line: The line from which the method is called, used for localized assertion failures.
    func assertTypeMatch(expected: AnyCodableComparable, actual: AnyCodableComparable?, file: StaticString = #file, line: UInt = #line) {
        assertJSON(expected: expected, actual: actual, file: file, line: line)
            .typeMatch(scope: .subtree)
            .validate()
    }

    /// Performs JSON validation where only the values from the `expected` JSON are required.
    ///
    /// Values must have the same type AND the same literal value.
    /// Both objects and arrays use extensible collections by default.
    ///
    /// - Parameters:
    ///   - expected: The expected `AnyCodableComparable` to compare.
    ///   - actual: The actual `AnyCodableComparable` to compare.
    ///   - file: The file from which the method is called, used for localized assertion failures.
    ///   - line: The line from which the method is called, used for localized assertion failures.
    func assertExactMatch(expected: AnyCodableComparable, actual: AnyCodableComparable?, file: StaticString = #file, line: UInt = #line) {
        // exactMatch is the default, so no additional options needed
        assertJSON(expected: expected, actual: actual, file: file, line: line)
            .validate()
    }
}

// MARK: - XCTestCase Conformance

extension XCTestCase: AnyCodableAsserts {}

// MARK: - Utility Extensions

extension AnyCodable {
    /// Creates an `AnyCodable` from an optional `Any` value, extracting the underlying value if present.
    ///
    /// - Parameter value: The optional value to wrap.
    /// - Returns: An `AnyCodable` instance representing the value, or an `AnyCodable` with `nil` value if the input is `nil`.
    static func from(optionalAny value: Any?) -> AnyCodable {
        guard let value = value else {
            return AnyCodable(nilLiteral: ())
        }
        switch value {
        case let existing as AnyCodable:
            return existing
        default:
            return AnyCodable(value)
        }
    }
}
