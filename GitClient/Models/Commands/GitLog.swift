//
//  GitLog.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2022/09/25.
//

import Foundation

struct GitLog: Git {
    typealias OutputModel = [Commit]
    var arguments = [
        "log",
        "--pretty=format:%H"
        + .formatSeparator + "%an"
        + .formatSeparator + "%ar"
        + .formatSeparator + "%s",
    ]
    var directory: URL

    func parse(for stdOut: String) throws -> [Commit] {
        guard !stdOut.isEmpty else {
            throw GenericError(errorDescription: "git log standard output is empty.")
        }
        let lines = stdOut.components(separatedBy: .newlines)
        return lines.map { line in
            let separated = line.components(separatedBy: String.formatSeparator)
            return Commit(
                hash: separated[0],
                author: separated[1],
                authorDateRelative: separated[2],
                title: separated[3]
            )
        }
    }
}

