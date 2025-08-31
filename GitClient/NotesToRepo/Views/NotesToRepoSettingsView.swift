//
//  NotesToRepoSettingsView.swift
//  GitClient
//
//  Created by Claude on 2025/08/29.
//

import SwiftUI
import Foundation
import Defaults

struct NotesToRepoSettingsView: View {
    @Default(.notesToRepoSettings) private var notesToRepoSettings
    @Default(.notesToRepoAutoCommit) private var autoCommitEnabled
    @Default(.notesToRepoProjectFileExtensions) private var projectFileExtensions
    @Default(.notesToRepoProjectInitialLoad) private var projectInitialLoad
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes to Repo Settings")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Configure your note-taking preferences for repository-specific documentation")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Configuration Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Configuration")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        // Notes Location
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Notes Location")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            HStack {
                                TextField("Select folder for storing notes", text: $notesToRepoSettings.notesLocation)
                                    .textFieldStyle(.roundedBorder)
                                    .focusable(false)
                                Button("Browse...") {
                                    selectNotesLocation()
                                }
                                .buttonStyle(.bordered)
                            }
                            Text("Choose where your repository notes will be saved")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // Note Name Format
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Note Name Format")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            TextField("Note naming pattern", text: $notesToRepoSettings.noteNameFormat)
                                .textFieldStyle(.roundedBorder)
                                .focusable(false)
                            Text("Available placeholders: {REPO_NAME}, DDMMYYYYHHMMSS")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        // Auto-commit toggle
                        VStack(alignment: .leading, spacing: 6) {
                            Toggle("Auto-Commit (Git repositories)", isOn: $autoCommitEnabled)
                            Text("Automatically commit changes to git when notes are in a git repository")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(16)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                }
                
                // Project Tab Settings
                VStack(alignment: .leading, spacing: 16) {
                    Text("Project Tab")
                        .font(.headline)
                        .fontWeight(.medium)

                    VStack(alignment: .leading, spacing: 12) {
                        // File Extensions
                        VStack(alignment: .leading, spacing: 6) {
                            Text("File Extensions")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            TextField("e.g. md, txt", text: Binding(
                                get: { projectFileExtensions.joined(separator: ", ") },
                                set: { newValue in
                                    let cleaned = newValue
                                        .lowercased()
                                        .split(separator: ",")
                                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                                        .filter { !$0.isEmpty }
                                        .map { $0.hasPrefix(".") ? String($0.dropFirst()) : String($0) }
                                    projectFileExtensions = Array(Set(cleaned)).sorted()
                                }
                            ))
                            .textFieldStyle(.roundedBorder)
                            .focusable(false)
                            Text("Extensions to include in Project tab (comma-separated, no dots).")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        // Initial Load Count
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Initial Load Count")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            HStack {
                                Stepper(value: $projectInitialLoad, in: 10...500, step: 5) {
                                    Text("\(projectInitialLoad)")
                                }
                                .frame(maxWidth: 200, alignment: .leading)
                            }
                            Text("How many project files to load initially in the Project tab. Use 'Load more' to fetch additional files.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(16)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                }

                // Information Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("How it Works")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    VStack(spacing: 12) {
                        InfoRow(
                            icon: "note.text",
                            iconColor: .blue,
                            text: "Click 'Notes to Repo' in any commit diff view to quickly jot down thoughts or documentation."
                        )
                        
                        InfoRow(
                            icon: "folder.badge.plus",
                            iconColor: .green,
                            text: "Notes are automatically organized by repository name and stored in your chosen location."
                        )
                        
                        InfoRow(
                            icon: "doc.text.magnifyingglass",
                            iconColor: .orange,
                            text: "Browse and search through all your repository notes in one convenient interface."
                        )
                        
                        InfoRow(
                            icon: "pencil.and.outline",
                            iconColor: .purple,
                            text: "Full markdown support with syntax highlighting for rich note-taking experience."
                        )
                    }
                    .padding(16)
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                    .cornerRadius(8)
                }
            }
            .padding(24)
        }
        .frame(minWidth: 600, maxWidth: 600, minHeight: 400)
    }
    
    private func selectNotesLocation() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        
        if panel.runModal() == .OK, let url = panel.url {
            notesToRepoSettings.notesLocation = url.path
        }
    }
    
}

#Preview {
    NotesToRepoSettingsView()
}