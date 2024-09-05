//
//  GitStatus.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/09/06.
//

import Foundation

struct GitStatus: Git {
    typealias OutputModel = Status
    var arguments: [String] {
        [
            "git",
            "status",
            "--short",
        ]
    }
    var directory: URL

    func parse(for stdOut: String) -> Status {
        let lines = stdOut.components(separatedBy: .newlines)
        let untrackedLines = lines.filter { $0.hasPrefix("?? ") }
        return .init(untrackedFiles: untrackedLines.map { String($0.dropFirst(3)) })
    }
}
