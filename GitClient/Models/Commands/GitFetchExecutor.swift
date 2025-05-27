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
        print("start git fetch")
        try Process.outputSync(command)
        print("end git fetch")
    }

    func execute(_ command: GitPull) throws {
        print("start git pull")
        try Process.outputSync(command)
        print("end git pull")
    }
}
