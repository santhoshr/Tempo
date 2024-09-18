//
//  GitTagPointsAt.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/09/19.
//

import Foundation

struct GitTagPointsAt: Git {
    typealias OutputModel = [String]
    var arguments: [String] {
        [
            "git",
            "tag",
            "--points-at",
            object
        ]
    }
    var directory: URL
    var object: String

    func parse(for stdOut: String) throws -> [String] {
        stdOut.components(separatedBy: .newlines).dropLast()
    }
}
