//
//  NoteFile.swift
//  GitClient
//
//  Created by Claude on 2025/08/31.
//

import Foundation

struct NoteFile: Identifiable {
    let id: String
    let name: String
    let relativePath: String
    let url: URL
    let creationDate: Date
    let modificationDate: Date
}