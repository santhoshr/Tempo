//
//  GitLog.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2022/09/25.
//

import Foundation

struct GitLog: Git {
    typealias OutputModel = [Commit]
    let arguments = [
        "git",
        "log",
        "--pretty=format:%H"
        + .formatSeparator + "%an"
        + .formatSeparator + "%ar"
        + .formatSeparator + "%s"
        + .formatSeparator + "%B"
        + .formatSeparator,
    ]
    var directory: URL

    func parse(for stdOut: String) throws -> [Commit] {
        let logs = stdOut.components(separatedBy: String.formatSeparator + "\n")
        print(logs)
        return logs.map { log in
            let separated = log.components(separatedBy: String.formatSeparator)
            return Commit(
                hash: separated[0],
                author: separated[1],
                authorDateRelative: separated[2],
                title: separated[3],
                rawBody: separated[4]
            )
        }
    }
}

