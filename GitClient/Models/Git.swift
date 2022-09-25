//
//  Git.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2022/09/25.
//

import Foundation

protocol Git {
    var arguments: [String] { get set}
    var directory: URL { get set }
    func run() throws -> String
}

extension Git {
    func run() throws -> String {
        try Process.run(executableURL: .git, arguments: arguments, currentDirectoryURL: directory)
    }
}
