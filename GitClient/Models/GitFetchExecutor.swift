//
//  GitFetchExecutor.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/05/27.
//

import Foundation

actor GitFetchExecutor {
    static let shared = GitFetchExecutor()

    func execute(_ command: GitFetch) throws {
        try Process.outputSync(command)
    }

    func execute(_ command: GitPull) throws {
        try Process.outputSync(command)
    }
}
