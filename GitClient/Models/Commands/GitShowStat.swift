//
//  GitShowStat.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/04/05.
//

import Foundation

struct GitShowStat: Git {
    var arguments: [String] {
        [
            "git",
            "show",
            "--shortstat",
            object
        ]
    }
    var directory: URL
    var object: String

    func parse(for stdOut: String) throws -> String {
        guard !stdOut.isEmpty else { throw GenericError(errorDescription: "Parse error: stdOut is empty.") }
        return String(stdOut.split(separator: "\n").last ?? "")
    }
}
