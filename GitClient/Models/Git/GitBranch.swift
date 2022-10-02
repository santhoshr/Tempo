//
//  GitBranch.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2022/10/02.
//

import Foundation

struct GitBranch: Git {
    typealias OutputModel = [Branch]
    var arguments: [String] {
        [
            "branch",
        ]
    }
    var directory: URL

    func parse(for stdOut: String) -> [Branch] {
        let lines = stdOut.components(separatedBy: .newlines)
        return lines.map { line in
            let s = line.components(separatedBy: .whitespaces)
            if s.first == "*", let name = s.last  {
                return Branch(name: name, isCurrent: true)
            }
            if let name = s.last {
                return Branch(name: name, isCurrent: false)
            }
            return Branch(name: "", isCurrent: false)
        }
    }
}
