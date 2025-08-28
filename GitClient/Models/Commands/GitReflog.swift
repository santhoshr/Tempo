//
//  GitReflog.swift
//  GitClient
//
//  Created by Claude on 2025/08/28.
//

import Foundation

struct GitReflog: Git {
    typealias OutputModel = [ReflogEntry]
    var arguments: [String] {
        return [
            "git",
            "reflog",
            "--pretty=format:%H%x09%gD%x09%gs",
            "-n",
            "100"
        ]
    }
    var directory: URL

    func parse(for stdOut: String) -> [ReflogEntry] {
        let lines = stdOut.components(separatedBy: .newlines)
        return lines.compactMap { line in
            let components = line.components(separatedBy: "\t")
            guard components.count >= 3 else { return nil }
            
            let hash = components[0]
            let refName = components[1]
            let message = components[2]
            
            return ReflogEntry(
                hash: hash,
                refName: refName,
                message: message
            )
        }
    }
}