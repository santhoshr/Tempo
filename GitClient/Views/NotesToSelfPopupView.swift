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
    @State private var hasUncommittedChanges = false
    
    var body: some View {
        HSplitView {
            // Left Panel - Folder View
            VStack(alignment: .leading, spacing: 0) {
                // Title Bar
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text("Repository Notes")
                                .font(.headline)
                            
                            if isGitRepo {
                                Image(systemName: hasUncommittedChanges ? "circle.fill" : "checkmark.circle.fill")
                                    .foregroundColor(hasUncommittedChanges ? .orange : .green)
                                    .font(.caption)
                                    .help(hasUncommittedChanges ? "Uncommitted changes" : "All changes committed")
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text(getRepositoryName())
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("\(noteFiles.count) note\(noteFiles.count == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
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
                .background(Color(NSColor.windowBackgroundColor))
                
                // Toolbar
                HStack(spacing: 8) {
                    // Git repository buttons (left edge)
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
                        
                        Button {
                            manualCommit()
                        } label: {
                            Image(systemName: "arrow.up.doc")
                        }
                        .buttonStyle(.bordered)
                        .help("Commit all notes changes")
                    }
                    
                    Spacer()
                    
                    // Add/Delete buttons (right edge)
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
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(NSColor.controlBackgroundColor))
                
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
                .background(Color(NSColor.windowBackgroundColor))
                
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
            checkGitStatus()
            // Restore last opened file or create new note
            restoreLastOpenedFile()
        }
        .onDisappear {
            autoSaveTimer?.invalidate()
            // Auto-save and auto-commit when closing if enabled and dirty
            if isDirty && autoSaveEnabled {
                saveNote(shouldAutoCommit: true)
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
                saveNote(shouldAutoCommit: true)
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
        
        let repoName = getRepositoryName()
        let notesURL = URL(fileURLWithPath: notesToRepoSettings.notesLocation)
        
        do {
            // Use recursive enumeration to find files in subdirectories
            let fileURLs = FileManager.default.enumerator(
                at: notesURL,
                includingPropertiesForKeys: [.creationDateKey, .contentModificationDateKey, .isDirectoryKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            )?.compactMap { element -> URL? in
                guard let url = element as? URL else { return nil }
                
                // Only include files, not directories
                let resourceValues = try? url.resourceValues(forKeys: [.isDirectoryKey])
                let isDirectory = resourceValues?.isDirectory ?? false
                
                return isDirectory ? nil : url
            } ?? []
            
            noteFiles = fileURLs
                .filter { $0.pathExtension == "md" }
                .filter { fileURL in
                    // Get the full relative path from notes directory
                    let relativePath = fileURL.path.replacingOccurrences(of: notesURL.path + "/", with: "")
                    
                    // Check if the path contains the repo name in various patterns:
                    // 1. Flat: {REPO_NAME}_DDMMYYYYHHMMSS.md
                    // 2. Nested: {REPO_NAME}/dummy_folder/{REPO_NAME}_DDMMYYYYHHMMSS.md
                    // 3. Timestamped: DDMMYYYYHHMMSS/{REPO_NAME}/DDMMYYYYHHMMSS.md
                    // 4. Any path component contains repo name
                    
                    let fileName = fileURL.lastPathComponent
                    let nameWithoutExtension = String(fileName.dropLast(3)) // Remove .md
                    let pathComponents = relativePath.components(separatedBy: "/")
                    
                    // STRICT filename matching - only exact patterns
                    let fileNameMatches = nameWithoutExtension.hasPrefix(repoName + "_") || 
                                         nameWithoutExtension == repoName
                    
                    // STRICT path component matching - only exact repo name as folder
                    let pathContainsRepo = pathComponents.contains(repoName)
                    
                    // Additional strict check: if filename contains repo name, it must be at word boundaries
                    let strictFileNameMatch = self.isRepoNameInFileName(fileName: nameWithoutExtension, repoName: repoName)
                    
                    return fileNameMatches || pathContainsRepo || strictFileNameMatch
                }
                .compactMap { url in
                    guard let resourceValues = try? url.resourceValues(forKeys: [.creationDateKey, .contentModificationDateKey]),
                          let creationDate = resourceValues.creationDate,
                          let modificationDate = resourceValues.contentModificationDate else {
                        return nil
                    }
                    // Calculate relative path for display
                    let relativePath = url.path.replacingOccurrences(of: notesURL.path + "/", with: "")
                    
                    return NoteFile(
                        id: url.absoluteString,
                        name: url.lastPathComponent,
                        relativePath: relativePath,
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
    
    private func isRepoNameInFileName(fileName: String, repoName: String) -> Bool {
        // Check if repo name appears as a complete word in filename
        // This prevents "Tempo" from matching "TempoSTC"
        let pattern = "\\b\(NSRegularExpression.escapedPattern(for: repoName))\\b"
        let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let range = NSRange(location: 0, length: fileName.utf16.count)
        return regex?.firstMatch(in: fileName, options: [], range: range) != nil
    }
    
    private func selectNote(_ noteFile: NoteFile) {
        // Auto-save current note before switching if enabled and dirty
        if isDirty && autoSaveEnabled && (selectedNote != nil || isCreatingNew) {
            saveNote(shouldAutoCommit: true)
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
            saveNote(shouldAutoCommit: true)
        }
        
        selectedNote = nil
        isCreatingNew = true
        noteContent = ""
        originalContent = ""
        isDirty = false
        
        // Generate new file name based on format
        let repoName = getRepositoryName()
        let formatter = DateFormatter()
        formatter.dateFormat = "ddMMyyyyHHmmss"
        let timestamp = formatter.string(from: Date())
        
        newNoteFileName = notesToRepoSettings.noteNameFormat
            .replacingOccurrences(of: "{REPO_NAME}", with: repoName)
            .replacingOccurrences(of: "DDMMYYYYHHMMSS", with: timestamp) + ".md"
    }
    
    private func saveNote(shouldAutoCommit: Bool = false) {
        guard let folder = folder,
              !notesToRepoSettings.notesLocation.isEmpty else { return }
        
        let repoName = getRepositoryName()
        let notesURL = URL(fileURLWithPath: notesToRepoSettings.notesLocation)
        
        let fileURL: URL
        if let selectedNote = selectedNote {
            // Use the existing file's URL directly
            fileURL = selectedNote.url
        } else {
            // For new notes, create the file path
            fileURL = notesURL.appendingPathComponent(newNoteFileName)
        }
        
        do {
            let previousContent = originalContent
            try noteContent.write(to: fileURL, atomically: true, encoding: .utf8)
            
            // Handle git auto-commit ONLY when explicitly requested (navigation/close events)
            if shouldAutoCommit && isGitRepo && autoCommitEnabled && hasContentChanges(from: previousContent, to: noteContent) {
                let relativePath = fileURL.path.replacingOccurrences(of: notesURL.path + "/", with: "")
                performAutoCommit(for: relativePath, action: isCreatingNew ? "added" : "edited")
            }
            
            // Update dirty state
            originalContent = noteContent
            isDirty = false
            
            // Update git status
            checkGitStatus()
            
            if isCreatingNew {
                // Create the new note object directly instead of reloading all notes
                let resourceValues = try? fileURL.resourceValues(forKeys: [.creationDateKey, .contentModificationDateKey])
                let creationDate = resourceValues?.creationDate ?? Date()
                let modificationDate = resourceValues?.contentModificationDate ?? Date()
                let relativePath = fileURL.path.replacingOccurrences(of: notesURL.path + "/", with: "")
                
                let newNote = NoteFile(
                    id: fileURL.absoluteString,
                    name: fileURL.lastPathComponent,
                    relativePath: relativePath,
                    url: fileURL,
                    creationDate: creationDate,
                    modificationDate: modificationDate
                )
                
                // Add to the beginning of the list (newest first)
                noteFiles.insert(newNote, at: 0)
                selectedNote = newNote
                isCreatingNew = false
            } else {
                // For existing notes, just update the modification date
                if let selectedNote = selectedNote,
                   let index = noteFiles.firstIndex(where: { $0.id == selectedNote.id }) {
                    let resourceValues = try? fileURL.resourceValues(forKeys: [.contentModificationDateKey])
                    let modificationDate = resourceValues?.contentModificationDate ?? Date()
                    
                    // Update the note in place
                    let updatedNote = NoteFile(
                        id: selectedNote.id,
                        name: selectedNote.name,
                        relativePath: selectedNote.relativePath,
                        url: selectedNote.url,
                        creationDate: selectedNote.creationDate,
                        modificationDate: modificationDate
                    )
                    
                    noteFiles[index] = updatedNote
                    self.selectedNote = updatedNote
                }
            }
        } catch {
            self.error = error
        }
    }
    
    private func deleteSelectedNote() {
        guard let selectedNote = selectedNote,
              let currentIndex = noteFiles.firstIndex(where: { $0.id == selectedNote.id }) else { return }
        
        let notesURL = URL(fileURLWithPath: notesToRepoSettings.notesLocation)
        let relativePath = selectedNote.url.path.replacingOccurrences(of: notesURL.path + "/", with: "")
        
        do {
            try FileManager.default.removeItem(at: selectedNote.url)
            
            // Handle git auto-commit if enabled
            if isGitRepo && autoCommitEnabled {
                performAutoCommit(for: relativePath, action: "deleted")
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
            saveNote(shouldAutoCommit: true)
        }
        action()
    }
    
    private func performAutoSaveAndClose() {
        if isDirty && autoSaveEnabled {
            saveNote(shouldAutoCommit: true)
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
    
    private func checkGitStatus() {
        guard isGitRepo else {
            hasUncommittedChanges = false
            return
        }
        
        let notesURL = URL(fileURLWithPath: notesToRepoSettings.notesLocation)
        
        Task {
            do {
                let gitStatus = GitStatus(directory: notesURL)
                let status = try await Process.output(gitStatus)
                
                // Check if there are any untracked or unmerged files
                hasUncommittedChanges = !status.untrackedFiles.isEmpty || !status.unmergedFiles.isEmpty
            } catch {
                print("DEBUG: Git status check failed: \(error)")
                hasUncommittedChanges = false
            }
        }
    }
    
    // MARK: - Repository Name Detection
    
    private func getRepositoryName() -> String {
        guard let folder = folder else { return "Unknown" }
        
        // Check if this is a git worktree first
        if let worktreeRepoName = getWorktreeRepositoryName(folder: folder) {
            return worktreeRepoName
        }
        
        // Try to get the actual repository name from git remote origin URL
        let gitConfigURL = folder.appendingPathComponent(".git/config")
        
        if FileManager.default.fileExists(atPath: gitConfigURL.path) {
            do {
                let gitConfig = try String(contentsOf: gitConfigURL)
                
                // Look for remote origin URL (same logic as existing app)
                let lines = gitConfig.components(separatedBy: .newlines)
                var inOriginSection = false
                
                for line in lines {
                    let trimmedLine = line.trimmingCharacters(in: .whitespaces)
                    
                    if trimmedLine == "[remote \"origin\"]" {
                        inOriginSection = true
                        continue
                    }
                    
                    if trimmedLine.hasPrefix("[") && trimmedLine != "[remote \"origin\"]" {
                        inOriginSection = false
                        continue
                    }
                    
                    if inOriginSection && trimmedLine.hasPrefix("url = ") {
                        let urlString = String(trimmedLine.dropFirst(6))
                        return extractRepoNameFromGitURL(urlString)
                    }
                }
            } catch {
                // If we can't read git config, fall back to folder name
            }
        }
        
        // Fallback to folder name if git config method fails
        return folder.lastPathComponent
    }
    
    private func getWorktreeRepositoryName(folder: URL) -> String? {
        let gitPath = folder.appendingPathComponent(".git")
        
        // Check if .git is a file (worktree) instead of a directory
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: gitPath.path, isDirectory: &isDirectory)
        
        if exists && !isDirectory.boolValue {
            // This is a worktree - .git is a file containing path to main repo
            do {
                let gitFileContent = try String(contentsOf: gitPath)
                
                // Parse the gitdir line: "gitdir: /path/to/main/repo/.git/worktrees/branch-name"
                for line in gitFileContent.components(separatedBy: .newlines) {
                    let trimmedLine = line.trimmingCharacters(in: .whitespaces)
                    if trimmedLine.hasPrefix("gitdir: ") {
                        let gitDirPath = String(trimmedLine.dropFirst(8))
                        
                        // Navigate to main repository's .git/config
                        // From: /path/to/main/repo/.git/worktrees/branch-name
                        // To:   /path/to/main/repo/.git/config
                        let gitDirURL = URL(fileURLWithPath: gitDirPath)
                        let mainGitDir = gitDirURL.deletingLastPathComponent().deletingLastPathComponent()
                        let mainConfigURL = mainGitDir.appendingPathComponent("config")
                        
                        if FileManager.default.fileExists(atPath: mainConfigURL.path) {
                            let mainConfig = try String(contentsOf: mainConfigURL)
                            return extractRepoNameFromConfig(mainConfig)
                        }
                    }
                }
            } catch {
                print("Failed to read worktree git file: \(error)")
            }
        }
        
        return nil
    }
    
    private func extractRepoNameFromConfig(_ gitConfig: String) -> String? {
        let lines = gitConfig.components(separatedBy: .newlines)
        var inOriginSection = false
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            if trimmedLine == "[remote \"origin\"]" {
                inOriginSection = true
                continue
            }
            
            if trimmedLine.hasPrefix("[") && trimmedLine != "[remote \"origin\"]" {
                inOriginSection = false
                continue
            }
            
            if inOriginSection && trimmedLine.hasPrefix("url = ") {
                let urlString = String(trimmedLine.dropFirst(6))
                return extractRepoNameFromGitURL(urlString)
            }
        }
        
        return nil
    }
    
    private func extractRepoNameFromGitURL(_ urlString: String) -> String {
        var cleanURL = urlString
        
        // Remove .git suffix if present
        if cleanURL.hasSuffix(".git") {
            cleanURL = String(cleanURL.dropLast(4))
        }
        
        // Extract repo name from different URL formats:
        // https://github.com/user/repo
        // git@github.com:user/repo
        // https://gitlab.com/user/repo
        
        if let lastSlash = cleanURL.lastIndex(of: "/") {
            return String(cleanURL[cleanURL.index(after: lastSlash)...])
        } else if cleanURL.contains(":") {
            // Handle SSH format like git@github.com:user/repo
            let parts = cleanURL.components(separatedBy: ":")
            if let lastPart = parts.last, let lastSlash = lastPart.lastIndex(of: "/") {
                return String(lastPart[lastPart.index(after: lastSlash)...])
            } else if let lastPart = parts.last {
                return lastPart
            }
        }
        
        // If all else fails, return the folder name
        return folder?.lastPathComponent ?? "Unknown"
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
    
    private func manualCommit() {
        guard isGitRepo else { return }
        
        let notesURL = URL(fileURLWithPath: notesToRepoSettings.notesLocation)
        let repoName = getRepositoryName()
        let commitMessage = "Manual commit of \(repoName) notes\n\n🤖 Generated with [Claude Code](https://claude.ai/code)\n\nCo-Authored-By: Claude <noreply@anthropic.com>"
        
        Task {
            do {
                print("DEBUG: Manual commit - adding all files")
                
                // Add all changes in the notes directory
                let gitAddAll = GitAdd(directory: notesURL)
                try await Process.output(gitAddAll)
                
                print("DEBUG: Manual commit - files added, attempting commit")
                
                // Commit all changes
                let gitCommit = GitCommit(directory: notesURL, message: commitMessage)
                try await Process.output(gitCommit)
                
                print("DEBUG: Manual commit successful")
                
            } catch {
                print("DEBUG: Manual commit failed: \(error)")
                self.error = GenericError(errorDescription: "Manual commit failed: \(error.localizedDescription)")
            }
        }
    }
    
    private func performAutoCommit(for filePath: String, action: String) {
        guard isGitRepo && autoCommitEnabled else { return }
        
        let notesURL = URL(fileURLWithPath: notesToRepoSettings.notesLocation)
        let commitMessage = "\(filePath) \(action)\n\n🤖 Generated with [Claude Code](https://claude.ai/code)\n\nCo-Authored-By: Claude <noreply@anthropic.com>"
        
        Task {
            do {
                print("DEBUG: Attempting to add file: \(filePath)")
                
                // Use existing GitAddPathspec command from the application's Git infrastructure
                // Always add the specific file path, git will handle the directory structure
                let gitAddFile = GitAddPathspec(directory: notesURL, pathspec: filePath)
                try await Process.output(gitAddFile)
                
                print("DEBUG: File added successfully, attempting commit")
                
                // Use existing GitCommit command from the application's Git infrastructure
                let gitCommit = GitCommit(directory: notesURL, message: commitMessage)
                try await Process.output(gitCommit)
                
                print("DEBUG: Commit successful for: \(filePath)")
                
            } catch {
                print("DEBUG: Git auto-commit failed for \(filePath): \(error)")
                // Fallback: add all changes and commit
                do {
                    print("DEBUG: Trying fallback - add all files")
                    let gitAddAll = GitAdd(directory: notesURL)
                    try await Process.output(gitAddAll)
                    
                    let gitCommit = GitCommit(directory: notesURL, message: commitMessage)
                    try await Process.output(gitCommit)
                    
                    print("DEBUG: Fallback commit successful")
                } catch {
                    print("DEBUG: Git auto-commit fallback also failed: \(error)")
                }
            }
        }
    }
}

struct NoteFile: Identifiable {
    let id: String
    let name: String
    let relativePath: String
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
                
                // Show relative path if file is in a subdirectory
                if noteFile.relativePath != noteFile.name {
                    Text(noteFile.relativePath)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
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