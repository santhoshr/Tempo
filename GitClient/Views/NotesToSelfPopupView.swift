//
//  NotesToSelfPopupView.swift
//  GitClient
//
//  Created by Claude on 2025/08/29.
//

import SwiftUI
import Foundation
import Defaults

extension CGSize: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(width, forKey: .width)
        try container.encode(height, forKey: .height)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let width = try container.decode(CGFloat.self, forKey: .width)
        let height = try container.decode(CGFloat.self, forKey: .height)
        self.init(width: width, height: height)
    }
    
    enum CodingKeys: String, CodingKey {
        case width, height
    }
}
import Sourceful

struct NotesToSelfPopupView: View {
    @Environment(\.folder) private var folder
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    
    @Default(.notesToRepoSettings) private var notesToRepoSettings
    @Default(.notesToSelfAutoSave) private var autoSaveEnabled
    @Default(.notesToSelfAutoCommit) private var autoCommitEnabled
    @Default(.notesToSelfFileListWidth) private var fileListWidth
    @Default(.notesToSelfLastOpenedFile) private var lastOpenedFileID
    
    @State private var noteFiles: [NoteFile] = []
    @State private var selectedNote: NoteFile?
    @State private var noteContent = ""
    @State private var isCreatingNew = false
    @State private var newNoteFileName = ""
    @State private var showDeleteConfirmation = false
    @State private var showNavigationWarning = false
    @State private var pendingNavigationAction: (() -> Void)?
    @State private var isDirty = false
    @State private var originalContent = ""
    @State private var isGitRepo = false
    @State private var autoSaveTimer: Timer?
    @State private var showGitMenu = false
    @State private var error: Error?
    
    var body: some View {
        HSplitView {
            // Left Panel - Folder View
            VStack(alignment: .leading, spacing: 0) {
                // Title Bar
                HStack {
                    Text("Repository Notes")
                        .font(.headline)
                    
                    if isDirty {
                        Image(systemName: "circle.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                            .help("Unsaved changes")
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
                
                // Toolbar
                HStack(spacing: 0) {
                    // Git repository buttons (left edge)
                    HStack(spacing: 4) {
                        if isGitRepo {
                            Button {
                                openNotesRepoInApp()
                            } label: {
                                Image(systemName: "folder.badge.gearshape")
                            }
                            .buttonStyle(.bordered)
                            .help("Open notes repository in main app")
                            
                            Button {
                                autoCommitEnabled.toggle()
                            } label: {
                                Image(systemName: autoCommitEnabled ? "checkmark.circle.fill" : "checkmark.circle")
                                    .foregroundColor(autoCommitEnabled ? .green : .secondary)
                            }
                            .buttonStyle(.bordered)
                            .help("Toggle automatic git commits")
                        }
                    }
                    
                    Spacer()
                    
                    // Add/Delete buttons (right edge)
                    HStack(spacing: 4) {
                        Button {
                            showDeleteConfirmation = true
                        } label: {
                            Image(systemName: "minus")
                        }
                        .buttonStyle(.bordered)
                        .disabled(selectedNote == nil)
                        .help("Delete selected note")
                        
                        Button {
                            createNewNote()
                        } label: {
                            Image(systemName: "plus")
                        }
                        .buttonStyle(.bordered)
                        .help("Create new note")
                    }
                    .padding(.trailing, 0)
                }
                .padding(.leading, 8)
                .padding(.vertical, 4)
                .background(Color(NSColor.controlBackgroundColor))
                .padding()
                
                Divider()
                
                // Notes List
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(noteFiles) { noteFile in
                            NoteFileRow(
                                noteFile: noteFile,
                                isSelected: selectedNote?.id == noteFile.id
                            ) {
                                selectNoteWithAutoSave(noteFile)
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, 8)
                }
            }
            .frame(minWidth: 200, idealWidth: fileListWidth, maxWidth: 500)
            .background(Color(NSColor.controlBackgroundColor))
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .onChange(of: geometry.size.width) { _, newWidth in
                            fileListWidth = newWidth
                        }
                }
            )
            
            // Right Panel - Editor View
            VStack(alignment: .leading, spacing: 0) {
                // Title Bar
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        if let selectedNote = selectedNote {
                            Text(selectedNote.name)
                                .font(.headline)
                            VStack(alignment: .leading, spacing: 1) {
                                Text("Created: \(selectedNote.creationDate, format: .dateTime.month().day().year().hour().minute())")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("Modified: \(selectedNote.modificationDate, format: .dateTime.month().day().year().hour().minute())")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } else if isCreatingNew {
                            Text(newNoteFileName)
                                .font(.headline)
                            Text("New note")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Select a note or create a new one")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
                
                // Toolbar
                if selectedNote != nil || isCreatingNew {
                    HStack(spacing: 8) {
                        // Navigation buttons
                        Button {
                            navigateUpWithDirtyCheck()
                        } label: {
                            Image(systemName: "chevron.up")
                        }
                        .buttonStyle(.bordered)
                        .disabled(!canNavigateUp())
                        .help("Previous note")
                        
                        Button {
                            navigateDownWithDirtyCheck()
                        } label: {
                            Image(systemName: "chevron.down")
                        }
                        .buttonStyle(.bordered)
                        .disabled(!canNavigateDown())
                        .help("Next note")
                        
                        Spacer()
                        
                        // Auto-save toggle
                        Button {
                            autoSaveEnabled.toggle()
                            updateAutoSaveTimer()
                        } label: {
                            Image(systemName: autoSaveEnabled ? "arrow.triangle.2.circlepath" : "arrow.triangle.2.circlepath")
                                .foregroundColor(autoSaveEnabled ? .green : .secondary)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.regular)
                        .help(autoSaveEnabled ? "Auto-save enabled" : "Auto-save disabled")
                        
                        Button {
                            saveNote()
                        } label: {
                            Image(systemName: "square.and.arrow.down")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(noteContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .help("Save note")
                        
                        Button {
                            performAutoSaveAndClose()
                        } label: {
                            Image(systemName: "xmark")
                        }
                        .buttonStyle(.bordered)
                        .help("Close editor")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(NSColor.controlBackgroundColor))
                }
                
                Divider()
                
                // Editor
                if selectedNote != nil || isCreatingNew {
                    TextEditor(text: $noteContent)
                        .scrollContentBackground(.hidden)
                        .background(Color(NSColor.textBackgroundColor))
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .onChange(of: noteContent) { _, newValue in
                            updateDirtyState(newContent: newValue)
                            if autoSaveEnabled {
                                updateAutoSaveTimer()
                            }
                        }
                } else {
                    VStack {
                        Spacer()
                        Image(systemName: "note.text")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No note selected")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("Select a note from the list or create a new one")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(minWidth: 400)
        }
        .frame(minWidth: 600, maxWidth: .infinity, 
               minHeight: 400, maxHeight: .infinity)
        .navigationTitle("Notes to Self")
        .onAppear {
            loadNotes()
            checkIfGitRepo()
            // Restore last opened file or create new note
            restoreLastOpenedFile()
        }
        .onDisappear {
            autoSaveTimer?.invalidate()
            // Auto-save when closing if enabled and dirty
            if isDirty && autoSaveEnabled {
                saveNote()
            }
        }
        .confirmationDialog("Delete Note", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                deleteSelectedNote()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this note? This action cannot be undone.")
        }
        .confirmationDialog("Unsaved Changes", isPresented: $showNavigationWarning) {
            Button("Save & Continue", role: .destructive) {
                saveNote()
                pendingNavigationAction?()
                pendingNavigationAction = nil
            }
            Button("Discard Changes", role: .destructive) {
                isDirty = false
                pendingNavigationAction?()
                pendingNavigationAction = nil
            }
            Button("Cancel", role: .cancel) {
                pendingNavigationAction = nil
            }
        } message: {
            Text("You have unsaved changes. What would you like to do?")
        }
        .errorSheet($error)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background || newPhase == .inactive {
                // Only save window state, no auto-commit on background events
            }
        }
    }
    
    
    private func loadNotes() {
        guard let folder = folder,
              !notesToRepoSettings.notesLocation.isEmpty else { return }
        
        let repoName = folder.lastPathComponent
        let notesURL = URL(fileURLWithPath: notesToRepoSettings.notesLocation)
        
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: notesURL,
                includingPropertiesForKeys: [.creationDateKey, .contentModificationDateKey],
                options: .skipsHiddenFiles
            )
            
            noteFiles = fileURLs
                .filter { $0.pathExtension == "md" }
                .filter { $0.lastPathComponent.contains(repoName) }
                .compactMap { url in
                    guard let resourceValues = try? url.resourceValues(forKeys: [.creationDateKey, .contentModificationDateKey]),
                          let creationDate = resourceValues.creationDate,
                          let modificationDate = resourceValues.contentModificationDate else {
                        return nil
                    }
                    return NoteFile(
                        id: url.absoluteString,
                        name: url.lastPathComponent,
                        url: url,
                        creationDate: creationDate,
                        modificationDate: modificationDate
                    )
                }
                .sorted { $0.creationDate > $1.creationDate }
        } catch {
            self.error = error
        }
    }
    
    private func selectNote(_ noteFile: NoteFile) {
        // Auto-save current note before switching if enabled and dirty
        if isDirty && autoSaveEnabled && (selectedNote != nil || isCreatingNew) {
            saveNote()
        }
        
        selectedNote = noteFile
        isCreatingNew = false
        updateLastOpenedFile()
        
        do {
            noteContent = try String(contentsOf: noteFile.url)
            originalContent = noteContent
            isDirty = false
        } catch {
            self.error = error
            noteContent = ""
            originalContent = ""
        }
    }
    
    private func createNewNote() {
        guard let folder = folder else { return }
        
        // Auto-save current note before creating new one if enabled and dirty
        if isDirty && autoSaveEnabled && (selectedNote != nil || isCreatingNew) {
            saveNote()
        }
        
        selectedNote = nil
        isCreatingNew = true
        noteContent = ""
        originalContent = ""
        isDirty = false
        
        // Generate new file name based on format
        let repoName = folder.lastPathComponent
        let formatter = DateFormatter()
        formatter.dateFormat = "ddMMyyyyHHmmss"
        let timestamp = formatter.string(from: Date())
        
        newNoteFileName = notesToRepoSettings.noteNameFormat
            .replacingOccurrences(of: "{REPO_NAME}", with: repoName)
            .replacingOccurrences(of: "DDMMYYYYHHMMSS", with: timestamp) + ".md"
    }
    
    private func saveNote() {
        guard let folder = folder,
              !notesToRepoSettings.notesLocation.isEmpty else { return }
        
        let repoName = folder.lastPathComponent
        let notesURL = URL(fileURLWithPath: notesToRepoSettings.notesLocation)
        
        let fileName: String
        if let selectedNote = selectedNote {
            fileName = selectedNote.name
        } else {
            fileName = newNoteFileName
        }
        
        let fileURL = notesURL.appendingPathComponent(fileName)
        
        do {
            let previousContent = originalContent
            try noteContent.write(to: fileURL, atomically: true, encoding: .utf8)
            
            // Handle git auto-commit if enabled and content has meaningful changes
            if isGitRepo && autoCommitEnabled && hasContentChanges(from: previousContent, to: noteContent) {
                performAutoCommit(for: fileName, action: isCreatingNew ? "added" : "edited")
            }
            
            // Update dirty state
            originalContent = noteContent
            isDirty = false
            
            loadNotes() // Refresh the list
            
            if isCreatingNew {
                // Select the newly created note
                if let newNote = noteFiles.first(where: { $0.url == fileURL }) {
                    selectedNote = newNote
                }
                isCreatingNew = false
            }
        } catch {
            self.error = error
        }
    }
    
    private func deleteSelectedNote() {
        guard let selectedNote = selectedNote,
              let currentIndex = noteFiles.firstIndex(where: { $0.id == selectedNote.id }) else { return }
        
        let fileName = selectedNote.name
        
        do {
            try FileManager.default.removeItem(at: selectedNote.url)
            
            // Handle git auto-commit if enabled
            if isGitRepo && autoCommitEnabled {
                performAutoCommit(for: fileName, action: "deleted")
            }
            
            // Refresh the notes list first
            loadNotes()
            
            // Navigate to next note with wrap-around
            if !noteFiles.isEmpty {
                var nextIndex = currentIndex
                if nextIndex >= noteFiles.count {
                    nextIndex = noteFiles.count - 1 // Stay at last note if we deleted the last one
                }
                if nextIndex >= 0 && nextIndex < noteFiles.count {
                    selectNote(noteFiles[nextIndex])
                }
            } else {
                // If no notes left, start creating a new one
                createNewNote()
            }
            
        } catch {
            self.error = error
        }
    }
    
    private func canNavigateUp() -> Bool {
        guard let currentNote = selectedNote,
              let currentIndex = noteFiles.firstIndex(where: { $0.id == currentNote.id }) else {
            return false
        }
        return currentIndex > 0
    }
    
    private func canNavigateDown() -> Bool {
        guard let currentNote = selectedNote,
              let currentIndex = noteFiles.firstIndex(where: { $0.id == currentNote.id }) else {
            return false
        }
        return currentIndex < noteFiles.count - 1
    }
    
    private func navigateUp() {
        guard let currentNote = selectedNote,
              let currentIndex = noteFiles.firstIndex(where: { $0.id == currentNote.id }),
              currentIndex > 0 else {
            return
        }
        
        let previousNote = noteFiles[currentIndex - 1]
        selectNote(previousNote)
    }
    
    private func navigateDown() {
        guard let currentNote = selectedNote,
              let currentIndex = noteFiles.firstIndex(where: { $0.id == currentNote.id }),
              currentIndex < noteFiles.count - 1 else {
            return
        }
        
        let nextNote = noteFiles[currentIndex + 1]
        selectNote(nextNote)
    }
    
    // MARK: - Navigation with Dirty Check
    
    private func navigateUpWithDirtyCheck() {
        if isDirty && autoSaveEnabled {
            performAutoSaveAndNavigate(action: navigateUp)
        } else if isDirty {
            pendingNavigationAction = navigateUp
            showNavigationWarning = true
        } else {
            navigateUp()
        }
    }
    
    private func navigateDownWithDirtyCheck() {
        if isDirty && autoSaveEnabled {
            performAutoSaveAndNavigate(action: navigateDown)
        } else if isDirty {
            pendingNavigationAction = navigateDown
            showNavigationWarning = true
        } else {
            navigateDown()
        }
    }
    
    // MARK: - Dirty State Management
    
    private func updateDirtyState(newContent: String) {
        isDirty = (newContent != originalContent)
    }
    
    // MARK: - Auto-Save Functionality
    
    private func updateAutoSaveTimer() {
        autoSaveTimer?.invalidate()
        
        if autoSaveEnabled && isDirty {
            autoSaveTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
                Task { @MainActor in
                    if self.isDirty {
                        self.saveNote()
                    }
                }
            }
        }
    }
    
    private func performAutoSaveAndNavigate(action: @escaping () -> Void) {
        if isDirty && autoSaveEnabled {
            saveNote()
        }
        action()
    }
    
    private func performAutoSaveAndClose() {
        if isDirty && autoSaveEnabled {
            saveNote()
        }
        dismiss()
    }
    
    private func selectNoteWithAutoSave(_ noteFile: NoteFile) {
        if isDirty && autoSaveEnabled {
            performAutoSaveAndNavigate {
                self.selectNote(noteFile)
            }
        } else if isDirty {
            // Show warning dialog for manual save
            pendingNavigationAction = { self.selectNote(noteFile) }
            showNavigationWarning = true
        } else {
            selectNote(noteFile)
        }
    }
    
    // MARK: - Git Repository Detection
    
    private func checkIfGitRepo() {
        guard !notesToRepoSettings.notesLocation.isEmpty else {
            isGitRepo = false
            return
        }
        
        let notesURL = URL(fileURLWithPath: notesToRepoSettings.notesLocation)
        let gitURL = notesURL.appendingPathComponent(".git")
        isGitRepo = FileManager.default.fileExists(atPath: gitURL.path)
    }
    
    // MARK: - Content Change Detection
    
    private func hasContentChanges(from oldContent: String, to newContent: String) -> Bool {
        // Normalize whitespace for comparison (trim and collapse whitespace)
        let normalizedOld = oldContent
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        let normalizedNew = newContent
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        return normalizedOld != normalizedNew
    }
    
    // MARK: - Git Operations
    
    private func openNotesRepoInApp() {
        guard !notesToRepoSettings.notesLocation.isEmpty else { return }
        
        let notesURL = URL(fileURLWithPath: notesToRepoSettings.notesLocation)
        let newFolder = Folder(url: notesURL)
        
        // Get current folders from Defaults
        var currentFolders = Defaults[.folders]
        
        // Remove if already exists and add to front (like addFolderToList does)
        currentFolders.removeAll { $0.url == notesURL }
        currentFolders.insert(newFolder, at: 0)
        
        // Save updated folders back to Defaults
        Defaults[.folders] = currentFolders
        
        // Post notification to select the repository
        NotificationCenter.default.post(
            name: NSNotification.Name("SelectRepository"), 
            object: notesURL
        )
        
        // Close the notes popup
        dismiss()
    }
    
    // MARK: - Window State Persistence
    
    private func updateLastOpenedFile() {
        if let selectedNote = selectedNote {
            lastOpenedFileID = selectedNote.id
        }
    }
    
    private func restoreLastOpenedFile() {
        guard let lastFileID = lastOpenedFileID,
              let fileToRestore = noteFiles.first(where: { $0.id == lastFileID }) else {
            // If no last file or file not found, create new note
            createNewNote()
            return
        }
        
        // Silently fail if file doesn't exist anymore
        if FileManager.default.fileExists(atPath: fileToRestore.url.path) {
            selectNote(fileToRestore)
        } else {
            // File was deleted, create new note instead
            createNewNote()
        }
    }
    
    private func performAutoCommit(for fileName: String, action: String) {
        guard isGitRepo && autoCommitEnabled else { return }
        
        let notesURL = URL(fileURLWithPath: notesToRepoSettings.notesLocation)
        let commitMessage = "\(fileName) \(action)\n\n🤖 Generated with [Claude Code](https://claude.ai/code)\n\nCo-Authored-By: Claude <noreply@anthropic.com>"
        
        Task {
            do {
                // Add file to git using existing command infrastructure
                try await Process.output(arguments: ["git", "add", fileName], currentDirectoryURL: notesURL)
                
                // Commit the change using existing GitCommit command
                let gitCommit = GitCommit(directory: notesURL, message: commitMessage)
                try await Process.output(gitCommit)
                
            } catch {
                print("Git auto-commit failed: \(error)")
            }
        }
    }
}

struct NoteFile: Identifiable {
    let id: String
    let name: String
    let url: URL
    let creationDate: Date
    let modificationDate: Date
}

struct NoteFileRow: View {
    let noteFile: NoteFile
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(noteFile.name)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .medium : .regular)
                    .lineLimit(1)
                
                Text(noteFile.creationDate, format: .dateTime.month().day().hour().minute())
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
        .cornerRadius(6)
        .onTapGesture {
            onSelect()
        }
        .contentShape(Rectangle())
    }
}

#Preview {
    NotesToSelfPopupView()
}