//
//  NotesToRepoToolbar.swift
//  GitClient
//
//  Created by Claude on 2025/08/31.
//

import SwiftUI

struct NotesToRepoToolbar: View {
    @Binding var filterText: String
    let isProjectTab: Bool
    let isGitRepo: Bool
    let selectedNote: NoteFile?
    let fileListVisible: Bool
    
    let onToggleFileList: () -> Void
    let onOpenNotesRepo: () -> Void
    let onRevealInFinder: () -> Void
    let onCreateNote: () -> Void
    let onDeleteNote: () -> Void
    let onToggleStatusBar: () -> Void
    
    private var editingDisabled: Bool { isProjectTab }
    
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
                .help(getRevealFinderHelpText())
                
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
            
            // Right section - Note operations and file filter
            HStack(spacing: 8) {
                TextField(isProjectTab ? "Filter extensions (e.g. md, txt)" : "Filter files (e.g. project, daily)", text: $filterText)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 240)
                    .onSubmit { 
                        if isProjectTab {
                            NotificationCenter.default.post(name: NSNotification.Name("ReloadProjectFiles"), object: nil)
                        } else {
                            NotificationCenter.default.post(name: NSNotification.Name("ReloadNoteFiles"), object: nil)
                        }
                    }
                
                Button {
                    guard !editingDisabled else { return }
                    onCreateNote()
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.bordered)
                .help("Create new note (⌘N)")
                .disabled(editingDisabled)
                
                Button {
                    guard !editingDisabled else { return }
                    onDeleteNote()
                } label: {
                    Image(systemName: "minus")
                }
                .buttonStyle(.bordered)
                .help("Delete selected note")
                .disabled(editingDisabled || selectedNote == nil)
                
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
    
    private func getRevealFinderHelpText() -> String {
        if isProjectTab {
            return selectedNote != nil ? "Reveal selected project file in Finder" : "Reveal project repository in Finder"
        } else {
            return selectedNote != nil ? "Reveal selected note in Finder" : "Reveal notes location in Finder"
        }
    }
}

#Preview {
    struct Wrapper: View {
        @State var isProjectTab = false
        @State var filterText = ""
        var body: some View {
            NotesToRepoToolbar(
                filterText: $filterText,
                isProjectTab: isProjectTab,
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
    }
    return Wrapper()
}