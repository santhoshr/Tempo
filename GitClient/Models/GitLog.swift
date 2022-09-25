//
//  GitLog.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2022/09/25.
//

import Foundation

struct GitLog {
    var arguments = ["log"]
    var directory: URL
    func run() throws -> String {
        try Process.run(executableURL: .git, arguments: arguments, currentDirectoryURL: directory)
    }
}
