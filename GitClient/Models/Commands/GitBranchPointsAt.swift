//
//  GitBranchPointsAt.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/09/20.
//

import Foundation

struct GitBranchPointsAt: Git {
    typealias OutputModel = [Branch]
    var arguments: [String] {
        [
            "git",
            "branch",
            "--all",
            "--points-at",
            object
        ]
    }
    var directory: URL
    var object: String

    func parse(for stdOut: String) throws -> [Branch] {
        let lines = stdOut.components(separatedBy: .newlines).dropLast()
        return lines.map { line in
            Branch(name: String(line.dropFirst(2)), isCurrent: line.hasPrefix("*"))
        }
    }
}
