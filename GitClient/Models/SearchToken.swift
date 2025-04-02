//
//  SearchToken.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2025/04/02.
//

import Foundation

struct SearchToken: Identifiable, Hashable {
    var id: Self { self }
    var kind: SearchKind
    var text: String
}
