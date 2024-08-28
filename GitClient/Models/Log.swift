//
//  Log.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2022/10/02.
//

import Foundation

enum Log: Identifiable, Hashable {
    var id: String {
        switch self {
        case .notCommitted:
            return "notCommitted"
        case .committed(let c):
            return c.hash
        }
    }

    case notCommitted(NotCommitted), committed(Commit)
}

struct NotCommitted: Hashable {
    var diff: String
    var diffCached: String
    var isEmpty: Bool { (diff + diffCached).isEmpty }
}
