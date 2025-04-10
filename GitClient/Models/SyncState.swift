//
//  SyncState.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/04/10.
//

import Foundation
import Observation

@MainActor
@Observable class SyncState {
    var folderURL: URL?
    var branchName: String?
    var shouldPull = false
    var shouldPush = false

    func sync() async throws {
        guard let folderURL, let branchName else {
            shouldPull = false
            shouldPush = false
            return
        }
        try await Process.output(GitFetch(directory: folderURL))

        let existRemoteBranch = try? await Process.output(GitShowref(directory: folderURL, pattern: "refs/remotes/origin/\(branchName)"))
        guard existRemoteBranch != nil else {
            shouldPull = false
            shouldPush = true
            return
        }
        shouldPull = !(try await Process.output(GitLog(directory: folderURL, revisionRange: "\(branchName)..origin/\(branchName)")).isEmpty)
        shouldPush = !(try await Process.output(GitLog(directory: folderURL, revisionRange: "origin/\(branchName)..\(branchName)")).isEmpty)
    }
}
