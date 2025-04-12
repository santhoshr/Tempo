//
//  LogStoreTests.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/04/12.
//

import Testing
import Foundation
@testable import Tempo

@MainActor
struct LogStoreTests {
    @Test func refresh() async throws {
        try await Process.output(GitSwitch(directory: .testFixture!, branchName: "_test-fixture"))
        let store = LogStore()
        store.directory = .testFixture!
        store.searchTokens = [] // 検索トークンがなければ全件取得

        await store.refresh()

        #expect(store.commits.count == 29)
        #expect(store.logs().first == .committed(store.commits.first!))
        #expect(store.error == nil)
    }

    @Test func refreshWithRevisionRange() async throws {
        try await Process.output(GitSwitch(directory: .testFixture!, branchName: "_test-fixture"))
        let store = LogStore()
        store.directory = .testFixture!
        store.searchTokens = [.init(kind: .revisionRange, text: "cfae930..")]

        await store.refresh()

        #expect(store.commits.count == 2)
        #expect(store.error == nil)
    }

    @Test func updateAddsCommits() async throws {
        try await Process.output(GitSwitch(directory: .testFixture!, branchName: "_test-fixture"))
        let store = LogStore()
        store.directory = .testFixture!
        store.searchTokens = []

        await store.refresh()
        let oldCount = store.commits.count
        await store.update()
        let newCount = store.commits.count

        #expect(newCount == oldCount)
        #expect(store.error == nil)
    }

    @Test func loadMoreAppendsCommits() async throws {
        try await Process.output(GitSwitch(directory: .testFixture!, branchName: "_test-fixture"))
        let store = LogStore()
        store.number = 10
        store.directory = .testFixture!

        await store.refresh()
        #expect(store.commits.count == 10)

        let first = store.commits.first
        await store.logViewTask(.committed(first!))
        #expect(store.commits.count == 10)

        await store.update()
        #expect(store.commits.count == 10)

        let last = store.commits.last
        await store.logViewTask(.committed(last!))
        #expect(store.commits.count == 20)

        let last2 = store.commits.last
        await store.logViewTask(.committed(last2!))
        #expect(store.commits.count == 29)

        #expect(store.error == nil)
    }

    @Test func loadMoreAppendsCommitsWithRevisionRange() async throws {
        try await Process.output(GitSwitch(directory: .testFixture!, branchName: "_test-fixture"))
        let store = LogStore()
        store.number = 1
        store.directory = .testFixture!
        store.searchTokens = [.init(kind: .revisionRange, text: "cfae930..")]

        await store.refresh()
        #expect(store.commits.count == 2)

        let first = store.commits.first
        await store.logViewTask(.committed(first!))
        #expect(store.commits.count == 2)

        await store.update()
        #expect(store.commits.count == 2)

        let last = store.commits.last
        await store.logViewTask(.committed(last!))
        #expect(store.commits.count == 2)

        let last2 = store.commits.last
        await store.logViewTask(.committed(last2!))
        #expect(store.commits.count == 2)

        #expect(store.error == nil)
    }

}
