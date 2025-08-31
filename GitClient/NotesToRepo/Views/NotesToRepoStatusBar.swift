//
//  NotesToRepoStatusBar.swift
//  GitClient
//
//  Created by Claude on 2025/08/31.
//

import SwiftUI

struct NotesToRepoStatusBar: View {
    let selectedNote: NoteFile?
    let selectedProjectFile: URL?
    let isCreatingNew: Bool
    let isGitRepo: Bool
    let hasUncommittedChanges: Bool
    let noteContent: String
    let notesToRepoSettings: NotesToRepoSettings
    
    var body: some View {
        HStack(spacing: 16) {
            // Left section - File info
            HStack(spacing: 8) {
                if let selectedNote = selectedNote {
                    let directoryPath = selectedNote.url.deletingLastPathComponent().path
                        .replacingOccurrences(of: notesToRepoSettings.notesLocation, with: "")
                        .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
                    
                    if directoryPath.isEmpty {
                        Text("Root directory")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text(directoryPath)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .help("Directory: \(selectedNote.url.deletingLastPathComponent().path)")
                    }
                } else if let selectedProjectFile = selectedProjectFile {
                    let directoryPath = selectedProjectFile.deletingLastPathComponent().path
                    Text(directoryPath)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .help("Directory: \(directoryPath)")
                } else if isCreatingNew {
                    Text("Root directory")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("No file selected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Center section - Git status
            if isGitRepo {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.triangle.branch")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if hasUncommittedChanges {
                        Text("Uncommitted changes")
                            .font(.caption)
                            .foregroundColor(.orange)
                    } else {
                        Text("Up to date")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
            
            Spacer()
            
            // Right section - Document stats
            HStack(spacing: 12) {
                if selectedNote != nil || selectedProjectFile != nil || isCreatingNew {
                    let wordCount = noteContent.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
                    let charCount = noteContent.count
                    
                    Text("\(wordCount) words")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(charCount) chars")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

#Preview {
    NotesToRepoStatusBar(
        selectedNote: NoteFile(
            id: "preview",
            name: "Sample.md",
            relativePath: "Sample.md",
            url: URL(fileURLWithPath: "/tmp/Sample.md"),
            creationDate: Date(),
            modificationDate: Date()
        ),
        selectedProjectFile: nil,
        isCreatingNew: false,
        isGitRepo: true,
        hasUncommittedChanges: false,
        noteContent: "This is some sample content for the preview.",
        notesToRepoSettings: NotesToRepoSettings(
            notesLocation: "/tmp/notes",
            noteNameFormat: "{REPO_NAME}_DDMMYYYYHHMMSS"
        )
    )
}