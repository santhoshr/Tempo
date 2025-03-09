//
//  GitLogTests.swift
//  GitClientTests
//
//  Created by Makoto Aoyama on 2024/10/01.
//

import Testing
import Foundation
@testable import Tempo

struct GitLogTests {
    @Test func parse() async throws {
        let gitlog = GitLog(directory: .testFixture!)
        let commits = try await Process.output(gitlog)
        #expect(commits.last!.hash == "f9635d9f3b39534e84f183555274867199af76a3")
        #expect(commits.last!.title == "Initial Commit")
        #expect(commits.first!.abbreviatedParentHashes == ["cfae930", "e129fc7"])
        #expect(commits.first!.branches == ["HEAD -> main", "origin/main", "origin/HEAD"])
        #expect(commits.first!.tags == ["v0.2.0"])
        #expect(commits.count == 29)
    }

    @Test func parseEmpty() async throws {
        let gitlog = GitLog(directory: URL(string: "file:///maoyama/Projects/")!)
        let output = ""
        let commits = try gitlog.parse(for: output)
        #expect(commits.count == 0)
    }
}
