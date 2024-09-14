//
//  Stasg.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/09/14.
//

import Foundation

struct Stash: Identifiable {
    var id: Int { index }
    var index: Int
    var message: String
    var raw: String

    init(index: Int, raw: String) {
        self.index = index
        self.raw = raw
        self.message = String(raw.split(separator: ":", maxSplits: 1).map { String($0) }[safe: 1]?.dropFirst() ?? "")
    }
}
