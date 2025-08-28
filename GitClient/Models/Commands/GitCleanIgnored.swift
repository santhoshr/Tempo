//
//  GitCleanIgnored.swift
//  GitClient
//
//  Created by Claude on 2025/08/28.
//

import Foundation

struct GitCleanIgnored: Git {
    typealias OutputModel = Void
    var arguments: [String] {
        return [
            "git",
            "clean",
            "-fx"
        ]
    }
    var directory: URL

    func parse(for stdOut: String) -> Void {}
}