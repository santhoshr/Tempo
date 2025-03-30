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
            + .formatSeparator + "%aE"
            + .formatSeparator + "%ai"
            + .formatSeparator + "%ar"
            + .formatSeparator + "%s"
            + .formatSeparator + "%b"
            + .formatSeparator + "%D"
            + .componentSeparator,
        ]
        if merges {
            args.append("--merges")
        }
        if ancestryPath {
            args.append("--ancestry-path")
        }
        if reverse {
            args.append("--reverse")
        }
        if number > 0 {
            args.append("-\(number)")
        }
        if !revisionRange.isEmpty {
            args.append(revisionRange)
        }
        return args
    }
    var directory: URL
    var merges = false
    var ancestryPath = false
    var reverse = false
    var number = 0
    var revisionRange = ""

    func parse(for stdOut: String) throws -> [Commit] {
        guard !stdOut.isEmpty else { return [] }
        let logs = stdOut.components(separatedBy: String.componentSeparator + "\n")
        return logs.map { log in
            let separated = log.components(separatedBy: String.formatSeparator)
            let refs: [String]
            if separated[8].isEmpty {
                refs = []
            } else {
                refs = separated[8].components(separatedBy: ", ")
            }
            return Commit(
                hash: separated[0],
                abbreviatedParentHashes: separated[1].components(separatedBy: .whitespacesAndNewlines),
                author: separated[2],
                authorEmail: separated[3],
                authorDate: separated[4],
                authorDateRelative: separated[5],
                title: separated[6],
                body: separated[7],
                branches: refs.filter { !$0.hasPrefix("tag: ") },
                tags: refs.filter { $0.hasPrefix("tag: ") }.map { String($0.dropFirst(5)) }
            )
        }
    }
}

