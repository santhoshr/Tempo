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
        // https://git-scm.com/docs/git-status#_short_format
        let untrackedLines = lines.filter { $0.hasPrefix("?? ") }
        let unmergedLines = lines.filter { $0.hasPrefix("U") }
        let modifiedLines = lines.filter { $0.hasPrefix(" M ") || $0.hasPrefix("M ") || $0.hasPrefix("MM ") }
        let addedLines = lines.filter { $0.hasPrefix("A ") || $0.hasPrefix("AM ") }
        let deletedLines = lines.filter { $0.hasPrefix(" D ") || $0.hasPrefix("D ") || $0.hasPrefix("AD ") }
        
        return .init(
            untrackedFiles: untrackedLines.map { String($0.dropFirst(3)) }, 
            unmergedFiles: unmergedLines.map { $0.components(separatedBy: .whitespaces).last ?? "" },
            modifiedFiles: modifiedLines.map { String($0.dropFirst(3)) },
            addedFiles: addedLines.map { String($0.dropFirst(3)) },
            deletedFiles: deletedLines.map { String($0.dropFirst(3)) }
        )
    }
}
