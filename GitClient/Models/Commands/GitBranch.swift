//
//  GitBranch.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2022/10/02.
//

import Foundation

struct GitBranch: Git {
    typealias OutputModel = [Branch]
    var arguments: [String] {
        [
            "git",
            "branch",
            "--sort=-authordate",
        ]
    }
    var directory: URL

    func parse(for stdOut: String) throws -> [Branch] {
        let lines = stdOut.components(separatedBy: .newlines).dropLast()
        return lines.map { line in
            Branch(name: String(line.dropFirst(2)), isCurrent: line.hasPrefix("*"))
        }
    }
}
