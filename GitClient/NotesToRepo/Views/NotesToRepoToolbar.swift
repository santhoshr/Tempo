//
//  NotesToRepoToolbar.swift
//  GitClient
//
//  Created by Claude on 2025/08/31.
//

import SwiftUI

struct NotesToRepoToolbar: View {
    let isGitRepo: Bool
    let selectedNote: NoteFile?
    let fileListVisible: Bool
    
    let onToggleFileList: () -> Void
    let onOpenNotesRepo: () -> Void
    let onRevealInFinder: () -> Void
    let onCreateNote: () -> Void
    let onDeleteNote: () -> Void
    let onToggleStatusBar: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Left section - File operations
            HStack(spacing: 8) {
                Button {
                    onToggleFileList()
                } label: {
                    Image(systemName: "sidebar.left")
                }
                .buttonStyle(.bordered)
                .help("Toggle file list (⌘1)")
                
                Button {
                    onRevealInFinder()
                } label: {
                    Image(systemName: "folder")
                }
                .buttonStyle(.bordered)
                .help(selectedNote != nil ? "Reveal selected note in Finder" : "Reveal notes location in Finder")
                
                if isGitRepo {
                    Button {
                        onOpenNotesRepo()
                    } label: {
                        Image(systemName: "folder.badge.gearshape")
                    }
                    .buttonStyle(.bordered)
                    .help("Open notes repository in main app")
                }
            }
            
            Spacer()
            
            // Right section - Note operations
            HStack(spacing: 8) {
                Button {
                    onCreateNote()
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.bordered)
                .help("Create new note (⌘N)")
                
                Button {
                    onDeleteNote()
                } label: {
                    Image(systemName: "minus")
                }
                .buttonStyle(.bordered)
                .disabled(selectedNote == nil)
                .help("Delete selected note")
                
                Button {
                    onToggleStatusBar()
                } label: {
                    Image(systemName: "info.circle")
                }
                .buttonStyle(.bordered)
                .help("Toggle status bar")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

#Preview {
    NotesToRepoToolbar(
        isGitRepo: true,
        selectedNote: NoteFile(
            id: "preview",
            name: "Sample.md",
            relativePath: "Sample.md",
            url: URL(fileURLWithPath: "/tmp/Sample.md"),
            creationDate: Date(),
            modificationDate: Date()
        ),
        fileListVisible: true,
        onToggleFileList: {},
        onOpenNotesRepo: {},
        onRevealInFinder: {},
        onCreateNote: {},
        onDeleteNote: {},
        onToggleStatusBar: {}
    )
}