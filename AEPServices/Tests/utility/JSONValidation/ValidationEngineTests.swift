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

class ValidationEngineTests: XCTestCase {

    // MARK: - Primitive Tests

    func testValidate_Primitives_ExactMatch() {
        let config = NodeConfig(defaults: .init(exactMatch: true))
        let result = ValidationEngine.validate(expected: AnyCodable("test"), actual: AnyCodable("test"), config: config)
        XCTAssertTrue(result.isValid)
    }

    func testValidate_Primitives_Mismatch() {
        let config = NodeConfig(defaults: .init(exactMatch: true))
        let result = ValidationEngine.validate(expected: AnyCodable("test"), actual: AnyCodable("fail"), config: config)
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.failures.first?.message, "Values do not match.")
    }

    func testValidate_Primitives_TypeMatch() {
        // "test" (String) matches "other" (String) because exactMatch = false
        let config = NodeConfig(defaults: .init(exactMatch: false))
        let result = ValidationEngine.validate(expected: AnyCodable("test"), actual: AnyCodable("other"), config: config)
        XCTAssertTrue(result.isValid)
    }

    func testValidate_Primitives_TypeMismatch() {
        let config = NodeConfig(defaults: .init(exactMatch: false))
        let result = ValidationEngine.validate(expected: AnyCodable("test"), actual: AnyCodable(123), config: config)
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.failures.first?.message.contains("types do not match") ?? false)
    }

    // MARK: - Dictionary Tests

    func testValidate_Dictionary_Subset() {
        // Expected is subset of Actual -> Pass
        let expected = AnyCodable(["a": 1])
        let actual = AnyCodable(["a": 1, "b": 2])
        
        let config = NodeConfig() // Defaults: extensible (equalCount: false)
        
        let result = ValidationEngine.validate(expected: expected, actual: actual, config: config)
        XCTAssertTrue(result.isValid)
    }

    func testValidate_Dictionary_EqualCount_Fail() {
        // Expected is subset, but we require equal count -> Fail
        let expected = AnyCodable(["a": 1])
        let actual = AnyCodable(["a": 1, "b": 2])
        
        var config = NodeConfig()
        config.equalCount = true
        
        let result = ValidationEngine.validate(expected: expected, actual: actual, config: config)
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.failures.first?.message.contains("count does not match") ?? false)
    }

    func testValidate_Dictionary_MissingKey() {
        let expected = AnyCodable(["a": 1, "c": 3])
        let actual = AnyCodable(["a": 1, "b": 2])
        
        let result = ValidationEngine.validate(expected: expected, actual: actual, config: NodeConfig())
        XCTAssertFalse(result.isValid)
        // Failure comes from "c" being nil in actual
        XCTAssertTrue(result.failures.first?.message.contains("Actual JSON is nil") ?? false)
    }

    // MARK: - Array Tests

    func testValidate_Array_Ordered_Pass() {
        let expected = AnyCodable([1, 2])
        let actual = AnyCodable([1, 2, 3]) // Extensible by default
        
        let result = ValidationEngine.validate(expected: expected, actual: actual, config: NodeConfig())
        XCTAssertTrue(result.isValid)
    }

    func testValidate_Array_Ordered_FailOrder() {
        let expected = AnyCodable([1, 2])
        let actual = AnyCodable([2, 1])
        
        let result = ValidationEngine.validate(expected: expected, actual: actual, config: NodeConfig())
        XCTAssertFalse(result.isValid)
    }

    func testValidate_Array_AnyOrder_Pass() {
        let expected = AnyCodable([1, 2])
        let actual = AnyCodable([2, 1, 3])
        
        var config = NodeConfig()
        config.anyOrder = true
        
        let result = ValidationEngine.validate(expected: expected, actual: actual, config: config)
        XCTAssertTrue(result.isValid)
    }

    func testValidate_Array_AnyOrder_FailMissing() {
        let expected = AnyCodable([1, 2, 99])
        let actual = AnyCodable([2, 1, 3])
        
        var config = NodeConfig()
        config.anyOrder = true
        
        let result = ValidationEngine.validate(expected: expected, actual: actual, config: config)
        XCTAssertFalse(result.isValid)
        // 99 not found
        XCTAssertTrue(result.failures.first?.message.contains("found no matches") ?? false)
    }

    func testValidate_Array_MixedOrder() {
        // [0] is fixed (must be 1)
        // [1] is anyOrder (must find 2 somewhere)
        let expected = AnyCodable([1, 2])
        let actual = AnyCodable([1, 99, 2])
        
        var config = NodeConfig()
        // Default is strict order.
        // Set anyOrder ONLY for index 1
        var index1 = NodeConfig(name: "1")
        index1.anyOrder = true
        config.children["1"] = index1
        
        let result = ValidationEngine.validate(expected: expected, actual: actual, config: config)
        XCTAssertTrue(result.isValid)
    }

    // MARK: - Special Constraints

    func testValidate_KeyMustBeAbsent() {
        let actual = AnyCodable(["a": 1, "b": 2])
        
        var config = NodeConfig()
        var nodeB = NodeConfig(name: "b")
        nodeB.keyMustBeAbsent = true
        config.children["b"] = nodeB
        
        // Expected is irrelevant for this constraint usually, but we pass nil or empty
        let result = ValidationEngine.validate(expected: nil, actual: actual, config: config)
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.failures.first?.message.contains("must not have key") ?? false)
    }

    func testValidate_ValueNotEqual() {
        let expected = AnyCodable("oldValue")
        let actual = AnyCodable("oldValue")
        
        var config = NodeConfig()
        config.valueNotEqual = true
        
        let result = ValidationEngine.validate(expected: expected, actual: actual, config: config)
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.failures.first?.message.contains("Values must NOT be equal") ?? false)
    }
}

