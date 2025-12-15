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
@testable import AEPServicesMocks

class NodeConfigTests: XCTestCase {

    // MARK: - Option Storage Tests

    func testOptionStorage_StoresValuesCorrectly() {
        var config = NodeConfig()
        
        // Initial state (nil)
        XCTAssertNil(config.exactMatch)
        XCTAssertNil(config.anyOrder)
        
        // Set values
        config.exactMatch = false
        config.anyOrder = true
        
        // Verify storage
        XCTAssertEqual(config.exactMatch, false)
        XCTAssertEqual(config.anyOrder, true)
        
        // Verify resolved accessors reflect storage
        XCTAssertFalse(config.isExactMatch)
        XCTAssertTrue(config.isAnyOrder)
    }

    // MARK: - Defaults Inheritance Tests

    func testDefaultsInheritance_UsesDefaultsWhenNil() {
        let defaults = NodeConfig.Defaults(anyOrder: false, exactMatch: true)
        let config = NodeConfig(defaults: defaults)
        
        // No overrides set
        XCTAssertNil(config.exactMatch)
        
        // Should resolve to defaults
        XCTAssertTrue(config.isExactMatch)
        XCTAssertFalse(config.isAnyOrder)
    }

    // MARK: - Navigation & Mutation Tests

    func testSetOption_CreatesPathAndSetsValue() {
        var root = NodeConfig()
        let path: JSONPath = "users[0].name"
        
        // Set option at deep path
        root.setExactMatch(false, at: path, scope: .singleNode)
        
        // Verify structure was created
        guard let users = root.getChild(named: "users"),
              let index0 = users.getChild(indexed: 0),
              let name = index0.getChild(named: "name") else {
            XCTFail("Failed to navigate to created node")
            return
        }
        
        // Verify option is set on the leaf
        XCTAssertEqual(name.exactMatch, false)
        
        // Verify intermediates are clean (nil)
        XCTAssertNil(users.exactMatch)
        XCTAssertNil(index0.exactMatch)
    }

    // MARK: - Resolution Precedence Tests
    
    // Chain: Child Specific > Wildcard > Parent > Default

    func testResolution_ChildOverridesEverything() {
        var parent = NodeConfig()
        parent.exactMatch = true // Parent says True
        parent.wildcardChildren = NodeConfig()
        parent.wildcardChildren?.exactMatch = true // Wildcard says True
        
        var child = NodeConfig(name: "child")
        child.exactMatch = false // Child says False
        parent.children["child"] = child
        
        let resolved = parent.resolvedChild(named: "child")
        XCTAssertFalse(resolved.isExactMatch, "Child specific override should win")
    }

    func testResolution_WildcardOverridesParent() {
        var parent = NodeConfig()
        parent.exactMatch = true // Parent says True
        
        parent.wildcardChildren = NodeConfig()
        parent.wildcardChildren?.exactMatch = false // Wildcard says False
        
        // Child exists but has no opinion
        let child = NodeConfig(name: "child")
        parent.children["child"] = child
        
        let resolved = parent.resolvedChild(named: "child")
        XCTAssertFalse(resolved.isExactMatch, "Wildcard setting should override parent")
    }

    func testResolution_ParentOverridesDefault() {
        // Default is False
        let defaults = NodeConfig.Defaults(exactMatch: false)
        var parent = NodeConfig(defaults: defaults)
        parent.exactMatch = true // Parent says True
        
        // Child exists, no opinion, no wildcard
        let child = NodeConfig(name: "child")
        parent.children["child"] = child
        
        let resolved = parent.resolvedChild(named: "child")
        XCTAssertTrue(resolved.isExactMatch, "Parent setting should override defaults")
    }
    
    func testResolution_FallsBackToDefault() {
        // Default is True
        let defaults = NodeConfig.Defaults(exactMatch: true)
        var parent = NodeConfig(defaults: defaults)
        // Parent has no opinion (nil)
        
        // Child exists, no opinion
        let child = NodeConfig(name: "child")
        parent.children["child"] = child
        
        let resolved = parent.resolvedChild(named: "child")
        XCTAssertTrue(resolved.isExactMatch, "Should fall back to defaults")
    }

    // MARK: - Wildcard Creation Tests

    func testSetOption_WithWildcardPath_CreatesWildcardNode() {
        var root = NodeConfig()
        let path: JSONPath = "items[*].id"
        
        root.setExactMatch(false, at: path, scope: .singleNode)
        
        // "items" node
        guard let items = root.getChild(named: "items") else {
            XCTFail("Items node not created")
            return
        }
        
        // "items" should have a wildcard child
        guard let wildcard = items.wildcardChildren else {
            XCTFail("Wildcard child not created")
            return
        }
        
        // Wildcard child should have "id" child
        guard let id = wildcard.getChild(named: "id") else {
            XCTFail("ID node not created under wildcard")
            return
        }
        
        XCTAssertEqual(id.exactMatch, false)
    }
    
    func testResolve_WildcardAppliesToNonExistentChild() {
        var root = NodeConfig()
        let path: JSONPath = "items[*]"
        root.setExactMatch(false, at: path, scope: .singleNode)
        
        let items = root.resolvedChild(named: "items")
        
        // Resolve a child index that was never explicitly created
        // It should be generated from the wildcard template
        let index0 = items.resolvedChild(at: 0)
        
        XCTAssertFalse(index0.isExactMatch)
    }

    // MARK: - Scope Tests

    func testSetOption_SubtreeScope_PropagatesToDefaults() {
        var root = NodeConfig()
        let path: JSONPath = "users"
        
        // Apply at "users" with subtree scope
        root.setExactMatch(false, at: path, scope: .subtree)
        
        let users = root.resolvedChild(named: "users")
        
        // The node itself should NOT have the property set directly (it's in defaults)
        XCTAssertNil(users.exactMatch)
        
        // But its defaults should be updated
        XCTAssertFalse(users.defaults.exactMatch)
        
        // And resolved value should be false
        XCTAssertFalse(users.isExactMatch)
        
        // Any child of users should inherit this new default
        let child = users.resolvedChild(named: "anyChild")
        XCTAssertFalse(child.isExactMatch)
    }
}

