//
//  Branch.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2022/10/02.
//

import Foundation

struct Branch: Hashable, Identifiable {
    let detachedPrefix = "(HEAD detached at "

    var id: String {
        name
    }
    var name: String
    var isCurrent: Bool
    var point: String {
        if isDetached {
            return String(name.dropFirst(detachedPrefix.count).dropLast(1))
        }
        return name
    }
    var isDetached: Bool {
        return name.hasPrefix(detachedPrefix)
    }
}

extension [Branch] {
    var current: Branch? {
        first { $0.isCurrent }
    }
}
