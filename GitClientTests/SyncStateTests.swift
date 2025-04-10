//
//  SyncStateTests.swift
//  GitClientTests
//
//  Created by Makoto Aoyama on 2025/04/10.
//

import Testing
@testable import Tempo
import Foundation

@MainActor
struct SyncStateTests {
    @Test func synced() async throws {
        let branch = "_test-fixture"
        try await Process.output(GitSwitch(directory: .testFixture!, branchName: branch))
        let state = SyncState()
        state.folderURL = .testFixture!
        state.branchName = branch
        try await state.sync()

        #expect(state.shouldPull == false)
        #expect(state.shouldPush == false)
    }

    @Test func newBranch() async throws {
        let branch = "_test-fixture-should-push-because-new-branch"
        try await Process.output(GitSwitch(directory: .testFixture!, branchName: branch))
        let state = SyncState()
        state.folderURL = .testFixture!
        state.branchName = branch
        try await state.sync()

        #expect(state.shouldPull == false)
        #expect(state.shouldPush == true)
    }

    @Test func shouldPush() async throws {
        let branch = "_test-fixture-should-push"
        try await Process.output(GitSwitch(directory: .testFixture!, branchName: branch))
        let state = SyncState()
        state.folderURL = .testFixture!
        state.branchName = branch
        try await state.sync()

        #expect(state.shouldPull == false)
        #expect(state.shouldPush == true)
    }

    @Test func shouldPull() async throws {
        let branch = "_test-fixture-should-pull"
        try await Process.output(GitSwitch(directory: .testFixture!, branchName: branch))
        let state = SyncState()
        state.folderURL = .testFixture!
        state.branchName = branch
        try await state.sync()

        #expect(state.shouldPull == true)
        #expect(state.shouldPush == false)
    }
}
