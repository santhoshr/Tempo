//
//  NotesToRepoSettings.swift
//  GitClient
//
//  Created by Claude on 2025/08/29.
//

import Foundation

struct NotesToRepoSettings: Codable, Equatable {
    var notesLocation: String = ""
    var noteNameFormat: String = "{REPO_NAME}_DDMMYYYYHHMMSS"
    
    init() {}
    
    init(notesLocation: String, noteNameFormat: String) {
        self.notesLocation = notesLocation
        self.noteNameFormat = noteNameFormat
    }
}