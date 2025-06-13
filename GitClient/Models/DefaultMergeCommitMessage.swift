//
//  DefaultMergeCommitMessage.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/06/13.
//

import Foundation

struct DefaultMergeCommitMessage {
    var directory: URL

    func get() async throws -> String {
        let path = try await Process.output(GitRevParse(directory: directory, gitPath: "MERGE_MSG"))
        let output = try await Process.output(arguments: ["cat", path], currentDirectoryURL: directory)
        return output.standardOutput.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
