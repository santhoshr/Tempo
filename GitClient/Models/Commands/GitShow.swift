//
//  GitShow.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/10/08.
//

import Foundation

struct GitShow: Git {
    typealias OutputModel = CommitDetail
    var arguments: [String] {
        [
            "git",
            "show",
            "--pretty=format:%H"
            + .formatSeparator + "%an"
            + .formatSeparator + "%ai"
            + .formatSeparator + "%ae"
            + .formatSeparator + "%s"
            + .formatSeparator + "%b"
            + .formatSeparator + "%D"
            + .componentSeparator,
            object
        ]
    }
    var directory: URL
    var object: String

    func parse(for stdOut: String) throws -> CommitDetail {
        guard !stdOut.isEmpty else { throw GenericError(errorDescription: "Parse error: stdOut is empty.") }
        let splits = stdOut.split(separator: String.componentSeparator + "\n", maxSplits: 1)
        let commitInfo = splits[0]
        let separated = commitInfo.components(separatedBy: String.formatSeparator)
        let refs: [String]
        if separated[6].isEmpty {
            refs = []
        } else {
            refs = separated[6].components(separatedBy: ", ")
        }
        return CommitDetail(
            hash: separated[0],
            author: separated[1],
            authorEmail: separated[2],
            authorDate: separated[3],
            title: separated[4],
            body: separated[5],
            branches: refs.filter { !$0.hasPrefix("tag: ") },
            tags: refs.filter { $0.hasPrefix("tag: ") }.map { String($0.dropFirst(5)) },
            diff: try Diff(raw: String(splits[safe: 1] ?? ""))
        )
    }
}

