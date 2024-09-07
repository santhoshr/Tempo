//
//  DiffStat.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/09/07.
//

import Foundation

struct DiffStat {
    var files: [String]
    var insertions: [Int]
    var insertionsTotal: Int {
        insertions.reduce(0) { partialResult, e in
            partialResult + e
        }
    }
    var deletions: [Int]
    var deletionsTotal: Int {
        deletions.reduce(0) { partialResult, e in
            partialResult + e
        }
    }
}
