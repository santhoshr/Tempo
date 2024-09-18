//
//  Branch.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2022/10/02.
//

import Foundation

struct Branch: Hashable, Identifiable {
    var id: String {
        name
    }
    var name: String
    var isCurrent: Bool
    var point: String {
        let detachedPrefix = "(HEAD detached at "
        if name.hasPrefix(detachedPrefix) {
            return String(name.dropFirst(detachedPrefix.count).dropLast(1))
        }
        return name
    }
}

extension [Branch] {
    var current: Branch? {
        first { $0.isCurrent }
    }
}
