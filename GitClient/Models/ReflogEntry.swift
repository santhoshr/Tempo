//
//  ReflogEntry.swift
//  GitClient
//
//  Created by Claude on 2025/08/28.
//

import Foundation

struct ReflogEntry: Identifiable, Hashable {
    let id = UUID()
    let hash: String
    let refName: String
    let message: String
    var branchNames: [String] = []
    
    var shortHash: String {
        String(hash.prefix(8))
    }
}