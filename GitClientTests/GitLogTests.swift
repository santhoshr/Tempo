//
//  GitLogTests.swift
//  GitClientTests
//
//  Created by Makoto Aoyama on 2024/10/01.
//

import Testing
import Foundation
@testable import GitClient

struct GitLogTests {

    @Test func parse() async throws {
        let gitlog = GitLog(directory: URL(string: "file:///maoyama/Projects/")!)
        let output = """
27966358a36d0691b872febe062200a5b43f03ae{separator-44cd166895ac93832525}Erik Eckstein{separator-44cd166895ac93832525}9 years ago{separator-44cd166895ac93832525}SimplifyCFG: simplify a cond_br which branches to a cond_fail which has the same condition.{separator-44cd166895ac93832525}
SimplifyCFG: simplify a cond_br which branches to a cond_fail which has the same condition.

This pattern occurs in the code of Dictionary accesses.

Swift SVN r30315
{separator-44cd166895ac93832525}{component-separator-44cd166895ac93832525}
4e26069c8f4f9a098a0fd0efa83ba8c87ebc2e66{separator-44cd166895ac93832525}Slava Pestov{separator-44cd166895ac93832525}9 years ago{separator-44cd166895ac93832525}Parse: Fix EndLoc of #if without #endif in parseDeclIfConfig(), and clean up duplication{separator-44cd166895ac93832525}Parse: Fix EndLoc of #if without #endif in parseDeclIfConfig(), and clean up duplication

Fixes <rdar://problem/19671208>.

Swift SVN r30314
{separator-44cd166895ac93832525}{component-separator-44cd166895ac93832525}
"""
        let commits = try gitlog.parse(for: output)
        #expect(commits.count == 2)
    }

    @Test func parseEmpty() async throws {
        let gitlog = GitLog(directory: URL(string: "file:///maoyama/Projects/")!)
        let output = ""
        let commits = try gitlog.parse(for: output)
        #expect(commits.count == 0)
    }
}
