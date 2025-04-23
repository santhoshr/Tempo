//
//  SearchKind.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/04/02.
//

import Foundation

enum SearchKind: Codable {
    case grep, grepAllMatch, s, g, author, revisionRange
}
