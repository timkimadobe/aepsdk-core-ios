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

import XCTest
import AEPServices
@testable import AEPServicesMocks

class JSONAssertionBuilderTests: XCTestCase {

    // MARK: - Chaining & Path Resolution

    func testBuilder_AnyOrder_SetsConfigCorrectly() {
        let builder = JSONAssertionBuilder(expected: nil, actual: nil, file: #file, line: #line)
        
        builder.anyOrder(at: "items[*]")
        
        let expected = AnyCodable(["items": [1, 2]])
        let actual = AnyCodable(["items": [2, 1]])
        
        // Without anyOrder, this should fail
        let strictBuilder = JSONAssertionBuilder(expected: expected, actual: actual, file: #file, line: #line)
        XCTAssertFalse(strictBuilder.check())
        
        // With anyOrder, it should pass
        let looseBuilder = JSONAssertionBuilder(expected: expected, actual: actual, file: #file, line: #line)
            .anyOrder(at: "items")
        
        XCTAssertTrue(looseBuilder.check())
    }

    func testBuilder_TypeMatch_SetsConfigCorrectly() {
        let expected = AnyCodable(["id": 123])
        let actual = AnyCodable(["id": 456])
        
        // Default is exact match -> Fail
        XCTAssertFalse(JSONAssertionBuilder(expected: expected, actual: actual, file: #file, line: #line).check())
        
        // With typeMatch -> Pass
        let builder = JSONAssertionBuilder(expected: expected, actual: actual, file: #file, line: #line)
            .typeMatch(at: "id")
        
        XCTAssertTrue(builder.check())
    }

    func testBuilder_EqualCount_SetsConfigCorrectly() {
        let expected = AnyCodable([1])
        let actual = AnyCodable([1, 2])
        
        // Default is extensible -> Pass
        XCTAssertTrue(JSONAssertionBuilder(expected: expected, actual: actual, file: #file, line: #line).check())
        
        // With equalCount -> Fail
        let builder = JSONAssertionBuilder(expected: expected, actual: actual, file: #file, line: #line)
            .equalCount(at: []) // Root
        
        XCTAssertFalse(builder.check())
    }

    func testBuilder_KeyMustBeAbsent_SetsConfigCorrectly() {
        let actual = AnyCodable(["deleted": true])
        
        let builder = JSONAssertionBuilder(expected: nil, actual: actual, file: #file, line: #line)
            .keyMustBeAbsent(at: "deleted")
        
        XCTAssertFalse(builder.check())
    }

    func testBuilder_ValueNotEqual_SetsConfigCorrectly() {
        let expected = AnyCodable("same")
        let actual = AnyCodable("same")
        
        let builder = JSONAssertionBuilder(expected: expected, actual: actual, file: #file, line: #line)
            .valueNotEqual(at: [])
        
        XCTAssertFalse(builder.check())
    }

    // MARK: - Scopes

    func testBuilder_ScopeSubtree_AppliesToDescendants() {
        let expected = AnyCodable(["a": 1, "b": ["c": 2]])
        let actual = AnyCodable(["a": 9, "b": ["c": 8]])
        
        // Values differ, so exact match fails
        // Applying typeMatch at root with .subtree scope should make it pass
        let builder = JSONAssertionBuilder(expected: expected, actual: actual, file: #file, line: #line)
            .typeMatch(at: [], scope: .subtree)
        
        XCTAssertTrue(builder.check())
    }

    func testBuilder_ScopeSingleNode_DoesNotPropagate() {
        let expected = AnyCodable(["a": 1, "b": 2])
        let actual = AnyCodable(["a": 9, "b": 9])
        
        // Apply typeMatch only to "a"
        let builder = JSONAssertionBuilder(expected: expected, actual: actual, file: #file, line: #line)
            .typeMatch(at: "a", scope: .singleNode)
        
        let result = builder.validateWithResult()
        
        // "a" should pass (type match)
        // "b" should fail (exact match default)
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.failures.contains { $0.keyPath.contains("b") })
        XCTAssertFalse(result.failures.contains { $0.keyPath.contains("a") })
    }

    // MARK: - Validation Execution

    func testValidate_ReturnsSuccess_WhenValid() {
        let expected = AnyCodable("test")
        let actual = AnyCodable("test")
        let builder = JSONAssertionBuilder(expected: expected, actual: actual, file: #file, line: #line)
        
        XCTAssertTrue(builder.check())
        
        // validate() returns Void but asserts
        // Check with validateWithResult()
        let result = builder.validateWithResult()
        XCTAssertTrue(result.isValid)
        XCTAssertTrue(result.failures.isEmpty)
    }

    func testValidate_ReturnsFailure_WhenInvalid() {
        let expected = AnyCodable("test")
        let actual = AnyCodable("mismatch")
        let builder = JSONAssertionBuilder(expected: expected, actual: actual, file: #file, line: #line)
        
        XCTAssertFalse(builder.check())
        
        let result = builder.validateWithResult()
        XCTAssertFalse(result.isValid)
        XCTAssertFalse(result.failures.isEmpty)
    }
}

