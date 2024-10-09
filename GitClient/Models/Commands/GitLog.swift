//
//  GitLog.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2022/09/25.
//

import Foundation

struct GitLog: Git {
    typealias OutputModel = [Commit]
    var arguments: [String] {
        var args = [
            "git",
            "log",
            "--pretty=format:%H"
            + .formatSeparator + "%p"
            + .formatSeparator + "%an"
            + .formatSeparator + "%ar"
            + .formatSeparator + "%s"
            + .formatSeparator + "%B"
            + .formatSeparator + "%D"
            + .componentSeparator,
        ]
        if number > 0 {
            args.append("-\(number)")
        }
        if !revisionRange.isEmpty {
            args.append(revisionRange)
        }
        return args
    }
    var directory: URL
    var number = 0
    var revisionRange = ""

    func parse(for stdOut: String) throws -> [Commit] {
        guard !stdOut.isEmpty else { return [] }
        let logs = stdOut.components(separatedBy: String.componentSeparator + "\n")
        return logs.map { log in
            let separated = log.components(separatedBy: String.formatSeparator)
            let refs: [String]
            if separated[6].isEmpty {
                refs = []
            } else {
                refs = separated[6].components(separatedBy: ", ")
            }
            return Commit(
                hash: separated[0],
                abbreviatedParentHashes: separated[1].components(separatedBy: .whitespacesAndNewlines),
                author: separated[2],
                authorDateRelative: separated[3],
                title: separated[4],
                rawBody: separated[5],
                branches: refs.filter { !$0.hasPrefix("tag: ") },
                tags: refs.filter { $0.hasPrefix("tag: ") }.map { String($0.dropFirst(5)) }
            )
        }
    }
}

