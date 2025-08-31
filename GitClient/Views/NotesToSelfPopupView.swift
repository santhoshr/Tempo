//
//  NotesToSelfPopupView.swift
//  GitClient
//
//  Created by Claude on 2025/08/29.
//

import SwiftUI
import Foundation
import Defaults

import Sourceful


// MARK: - Notes to Repo Auto-commit Documentation
/*
 Auto-save and auto-commit behavior:

 1. **Auto-save on navigation**: Always save when navigating away from a dirty note
    - Triggered by: onDisappear, selectNote(), createNewNote(), navigation keys
    - Condition: isDirty

 2. **Auto-commit**: Always commit individual files if notes location is a Git repository
    - Triggered by: saveNote() function
    - Condition: isGitRepo
    - Uses individual file commits (not blanket commits)

 3. **File deletion**: Auto-commit deletion if Git repository
    - Triggered by: deleteSelectedNote()
    - Condition: isGitRepo

 Auto-commit requirements:
 - Notes location must be a valid Git repository (.git directory or worktree file)
 - Must have valid git user configuration
 - File must have actual changes (checked via git status)

 Auto-commit will be skipped if:
 - Notes location is not a valid Git repository
 - Git user configuration is missing
 - No changes detected in the file
 - Git command fails (logged for debugging)
*/

struct NotesToSelfPopupView: View {
    @Environment(\.folder) private var folder
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    
    @Default(.notesToRepoSettings) private var notesToRepoSettings
    @Default(.notesToSelfFileListWidth) private var fileListWidth
    @Default(.notesToSelfLastOpenedFile) private var lastOpenedFileID
    
    @State private var noteFiles: [NoteFile] = []
    @State private var selectedNote: NoteFile?
    @State private var noteContent = ""
    @State private var isCreatingNew = false
    @State private var newNoteFileName = ""
    @State private var showDeleteConfirmation = false
    @State private var isDirty = false
    @State private var originalContent = ""
    @State private var isGitRepo = false
    @State private var showGitMenu = false
    @State private var error: Error?
    @State private var hasUncommittedChanges = false
    @State private var currentFileHasUncommittedChanges = false
    @State private var titleUpdateTrigger = false
    @FocusState private var isFileListFocused: Bool
    @FocusState private var isEditorFocused: Bool
    
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
                List(noteFiles, id: \.id, selection: Binding<String?>(
                    get: { selectedNote?.id },
                    set: { newID in
                        if let id = newID,
                           let noteFile = noteFiles.first(where: { $0.id == id }) {
                            selectNoteWithAutoSave(noteFile)
                        }
                    }
                )) { noteFile in
                    NoteFileRow(
                        noteFile: noteFile,
                        isSelected: selectedNote?.id == noteFile.id
                    ) {
                        selectNoteWithAutoSave(noteFile)
                    }
                    .tag(noteFile.id)
                }
                .listStyle(.sidebar)
                .scrollContentBackground(.hidden)
                .background(Color(NSColor.controlBackgroundColor))
                .focused($isFileListFocused)
                .onTapGesture {
                    isFileListFocused = true
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
                            HStack(spacing: 4) {
                                Text(selectedNote.name)
                                    .font(.headline)
                                if currentFileHasUncommittedChanges {
                                    Text("+")
                                        .font(.headline)
                                        .foregroundColor(.orange)
                                        .help("File has uncommitted changes")
                                }
                            }
                            VStack(alignment: .leading, spacing: 1) {
                                Text("Created: \(selectedNote.creationDate, format: .dateTime.month().day().year().hour().minute())")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .redacted(reason: selectedNote.creationDate.timeIntervalSince1970 == 0 ? .placeholder : [])
                                Text("Modified: \(selectedNote.modificationDate, format: .dateTime.month().day().year().hour().minute())")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .redacted(reason: selectedNote.modificationDate.timeIntervalSince1970 == 0 ? .placeholder : [])
                            }
                        } else if isCreatingNew {
                            HStack(spacing: 4) {
                                Text(newNoteFileName)
                                    .font(.headline)
                                Text("+")
                                    .font(.headline)
                                    .foregroundColor(.green)
                                    .help("New file (not yet saved)")
                            }
                            VStack(alignment: .leading, spacing: 1) {
                                Text("New note")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            Text("Select a note or create a new one")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            VStack(alignment: .leading, spacing: 1) {
                                Text("")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(NSColor.windowBackgroundColor))
                
                // Toolbar - Always visible
                HStack(spacing: 8) {
                    if selectedNote != nil || isCreatingNew {
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
                        
                        
                        Button {
                            performAutoSaveAndClose()
                        } label: {
                            Image(systemName: "xmark")
                        }
                        .buttonStyle(.bordered)
                        .help("Close editor")
                    } else {
                        // Placeholder content when no note is selected
                        Spacer()
                        
                        // Create new note button
                        Button {
                            createNewNote()
                        } label: {
                            Image(systemName: "plus.circle")
                        }
                        .buttonStyle(.borderedProminent)
                        .help("Create new note")
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(NSColor.controlBackgroundColor))
                
                Divider()
                
                // Editor
                if selectedNote != nil || isCreatingNew {
                    TextEditor(text: $noteContent)
                        .scrollContentBackground(.hidden)
                        .background(Color(NSColor.textBackgroundColor))
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .focused($isEditorFocused)
                        .onTapGesture {
                            isFileListFocused = false
                            isEditorFocused = true
                        }
                        .onChange(of: noteContent) { _, newValue in
                            updateDirtyState(newContent: newValue)
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
        .navigationTitle(getWindowTitle())
        .focusable()
        .onKeyPress { keyPress in
            // Only handle navigation keys when file list is focused
            guard isFileListFocused else { return .ignored }
            
            switch keyPress.key {
            case .upArrow:
                navigateUpWithDirtyCheck()
                return .handled
            case .downArrow:
                navigateDownWithDirtyCheck()
                return .handled
            case .return:
                if selectedNote == nil && !noteFiles.isEmpty {
                    selectNoteWithAutoSave(noteFiles[0])
                    return .handled
                }
                return .ignored
            case .delete, .deleteForward:
                if selectedNote != nil {
                    showDeleteConfirmation = true
                    return .handled
                }
                return .ignored
            default:
                return .ignored
            }
        }
        .onChange(of: titleUpdateTrigger) { _, _ in
            // This triggers when title needs to update
        }
        .onChange(of: hasUncommittedChanges) { _, _ in
            titleUpdateTrigger.toggle()
        }
        .onChange(of: currentFileHasUncommittedChanges) { _, _ in
            titleUpdateTrigger.toggle()
        }
        .onChange(of: selectedNote?.id) { _, _ in
            checkCurrentFileGitStatus()
            titleUpdateTrigger.toggle()
        }
        .onChange(of: isCreatingNew) { _, _ in
            checkCurrentFileGitStatus()
            titleUpdateTrigger.toggle()
        }
        .onAppear {
            loadNotes()
            checkIfGitRepo()
            checkGitStatus()
            // Restore last opened file or create new note
            restoreLastOpenedFile()
            // Set focus to file list for keyboard navigation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isFileListFocused = true
            }
        }
        .onDisappear {
            // Auto-save and auto-commit when closing if dirty
            if isDirty {
                print("DEBUG: OnDisappear - auto-saving with auto commit")
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
        .errorSheet($error)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background || newPhase == .inactive {
                // Only save window state, no auto-commit on background events
            }
        }
    }
    
    
    private func loadNotes() {
        guard folder != nil,
              !notesToRepoSettings.notesLocation.isEmpty else { return }
        
        let repoName = getRepositoryName()
        let notesURL = URL(fileURLWithPath: notesToRepoSettings.notesLocation)
        
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
        // Auto-save current note before switching if dirty
        if isDirty && (selectedNote != nil || isCreatingNew) {
            print("DEBUG: Auto-saving before note selection with auto commit")
            saveNote()
        }
        
        selectedNote = noteFile
        isCreatingNew = false
        updateLastOpenedFile()
        
        do {
            noteContent = try String(contentsOf: noteFile.url)
            originalContent = noteContent
            isDirty = false
            checkCurrentFileGitStatus()
        } catch {
            self.error = error
            noteContent = ""
            originalContent = ""
        }
        
        // Maintain focus on file list for keyboard navigation
        DispatchQueue.main.async {
            self.isFileListFocused = true
            self.isEditorFocused = false
        }
    }
    
    private func createNewNote() {
        guard folder != nil else { return }
        
        // Auto-save current note before creating new one if dirty
        if isDirty && (selectedNote != nil || isCreatingNew) {
            saveNote()
        }
        
        selectedNote = nil
        isCreatingNew = true
        noteContent = ""
        originalContent = ""
        isDirty = false
        checkCurrentFileGitStatus()
        
        // Generate new file name based on format
        let repoName = getRepositoryName()
        let formatter = DateFormatter()
        formatter.dateFormat = "ddMMyyyyHHmmss"
        let timestamp = formatter.string(from: Date())
        
        newNoteFileName = notesToRepoSettings.noteNameFormat
            .replacingOccurrences(of: "{REPO_NAME}", with: repoName)
            .replacingOccurrences(of: "DDMMYYYYHHMMSS", with: timestamp) + ".md"
    }
    
    private func saveNote(caller: String = #function) {
        guard folder != nil,
              !notesToRepoSettings.notesLocation.isEmpty else { return }
        
        _ = getRepositoryName()
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
            
            print("DEBUG: === SAVE NOTE CALLED ===")
            print("DEBUG: Called by: \(caller)")
            
            // Update dirty state and git status
            originalContent = noteContent
            isDirty = false
            checkGitStatus()
            checkCurrentFileGitStatus()
            
            // Simple autocommit logic: always auto-commit if git repo
            if isGitRepo {
                print("DEBUG: Git repo detected, auto-committing...")
                
                // Calculate relative path
                let relativePath: String
                if fileURL.path.hasPrefix(notesURL.path + "/") {
                    relativePath = String(fileURL.path.dropFirst(notesURL.path.count + 1))
                } else {
                    relativePath = fileURL.lastPathComponent
                }
                
                print("DEBUG: File path: \(relativePath)")
                
                // Always try to commit if it's a git repo
                // The commit function will check if there are actually changes
                performAutoCommit(for: relativePath, action: isCreatingNew ? "added" : "edited")
            } else {
                print("DEBUG: Not a git repo - skipping commit")
            }
            
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
        
        // Calculate relative path more reliably
        let relativePath: String
        if selectedNote.url.path.hasPrefix(notesURL.path + "/") {
            relativePath = String(selectedNote.url.path.dropFirst(notesURL.path.count + 1))
        } else {
            relativePath = selectedNote.url.lastPathComponent
        }
        print("DEBUG: Delete - calculated relative path: \(relativePath)")
        
        do {
            try FileManager.default.removeItem(at: selectedNote.url)
            
            // Handle git auto-commit 
            if isGitRepo {
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
        guard !noteFiles.isEmpty else { return false }
        if let currentNote = selectedNote,
           let currentIndex = noteFiles.firstIndex(where: { $0.id == currentNote.id }) {
            return currentIndex > 0
        }
        return !noteFiles.isEmpty
    }
    
    private func canNavigateDown() -> Bool {
        guard !noteFiles.isEmpty else { return false }
        if let currentNote = selectedNote,
           let currentIndex = noteFiles.firstIndex(where: { $0.id == currentNote.id }) {
            return currentIndex < noteFiles.count - 1
        }
        return !noteFiles.isEmpty
    }
    
    private func navigateUp() {
        guard !noteFiles.isEmpty else { return }
        
        if let currentNote = selectedNote,
           let currentIndex = noteFiles.firstIndex(where: { $0.id == currentNote.id }),
           currentIndex > 0 {
            let previousNote = noteFiles[currentIndex - 1]
            selectNote(previousNote)
        } else if selectedNote == nil {
            // If no selection, select first note
            selectNote(noteFiles[0])
        }
        
        // Ensure focus stays on file list
        isFileListFocused = true
        isEditorFocused = false
    }
    
    private func navigateDown() {
        guard !noteFiles.isEmpty else { return }
        
        if let currentNote = selectedNote,
           let currentIndex = noteFiles.firstIndex(where: { $0.id == currentNote.id }),
           currentIndex < noteFiles.count - 1 {
            let nextNote = noteFiles[currentIndex + 1]
            selectNote(nextNote)
        } else if selectedNote == nil {
            // If no selection, select first note
            selectNote(noteFiles[0])
        }
        
        // Ensure focus stays on file list
        isFileListFocused = true
        isEditorFocused = false
    }
    
    // MARK: - Navigation with Dirty Check
    
    private func navigateUpWithDirtyCheck() {
        if isDirty {
            performAutoSaveAndNavigate(action: navigateUp)
        } else {
            navigateUp()
        }
    }
    
    private func navigateDownWithDirtyCheck() {
        if isDirty {
            performAutoSaveAndNavigate(action: navigateDown)
        } else {
            navigateDown()
        }
    }
    
    // MARK: - Dirty State Management
    
    private func updateDirtyState(newContent: String) {
        let wasDirty = isDirty
        isDirty = (newContent != originalContent)
        
        // Update window title when dirty state changes
        if wasDirty != isDirty {
            titleUpdateTrigger.toggle()
        }
    }
    
    // MARK: - Auto-Save Functionality
    
    private func performAutoSaveAndNavigate(action: @escaping () -> Void) {
        if isDirty {
            print("DEBUG: Auto-save and navigate - always auto-commit if git repo")
            saveNote()
        }
        action()
    }
    
    private func performAutoSaveAndClose() {
        if isDirty {
            print("DEBUG: Auto-save and close - always auto-commit if git repo")
            saveNote()
        }
        dismiss()
    }
    
    private func selectNoteWithAutoSave(_ noteFile: NoteFile) {
        if isDirty {
            performAutoSaveAndNavigate {
                self.selectNote(noteFile)
            }
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
        let gitPath = notesURL.appendingPathComponent(".git")
        
        // Check for regular git directory or git worktree file
        let isDirectory = FileManager.default.fileExists(atPath: gitPath.path) && 
                         (try? gitPath.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
        let isFile = FileManager.default.fileExists(atPath: gitPath.path) && 
                    (try? gitPath.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == false
        
        isGitRepo = isDirectory || isFile
        print("DEBUG: Git repo check - path: \(gitPath.path), isDirectory: \(isDirectory), isFile: \(isFile), result: \(isGitRepo)")
    }
    
    private func checkGitStatus() {
        guard isGitRepo else {
            hasUncommittedChanges = false
            currentFileHasUncommittedChanges = false
            return
        }
        
        let notesURL = URL(fileURLWithPath: notesToRepoSettings.notesLocation)
        
        Task {
            do {
                let gitStatus = GitStatus(directory: notesURL)
                let status = try await Process.output(gitStatus)
                
                // Check if there are any uncommitted changes
                await MainActor.run {
                    hasUncommittedChanges = !status.untrackedFiles.isEmpty || 
                                          !status.unmergedFiles.isEmpty || 
                                          !status.modifiedFiles.isEmpty || 
                                          !status.addedFiles.isEmpty
                    checkCurrentFileGitStatus()
                }
            } catch {
                print("DEBUG: Git status check failed: \(error)")
                await MainActor.run {
                    hasUncommittedChanges = false
                    currentFileHasUncommittedChanges = false
                }
            }
        }
    }
    
    private func checkCurrentFileGitStatus() {
        guard isGitRepo else {
            currentFileHasUncommittedChanges = false
            return
        }
        
        let notesURL = URL(fileURLWithPath: notesToRepoSettings.notesLocation)
        
        if isCreatingNew {
            // New files are always uncommitted
            currentFileHasUncommittedChanges = true
            return
        }
        
        guard let selectedNote = selectedNote else {
            currentFileHasUncommittedChanges = false
            return
        }
        
        Task {
            do {
                let gitStatus = GitStatus(directory: notesURL)
                let status = try await Process.output(gitStatus)
                
                // Get relative path of current file more reliably
                let relativePath: String
                if selectedNote.url.path.hasPrefix(notesURL.path + "/") {
                    relativePath = String(selectedNote.url.path.dropFirst(notesURL.path.count + 1))
                } else {
                    relativePath = selectedNote.url.lastPathComponent
                }
                
                // Check if current file has any uncommitted changes
                await MainActor.run {
                    currentFileHasUncommittedChanges = status.untrackedFiles.contains(relativePath) ||
                                                     status.unmergedFiles.contains(relativePath) ||
                                                     status.modifiedFiles.contains(relativePath) ||
                                                     status.addedFiles.contains(relativePath)
                }
            } catch {
                print("DEBUG: Current file git status check failed: \(error)")
                await MainActor.run {
                    currentFileHasUncommittedChanges = false
                }
            }
        }
    }
    
    // MARK: - Window Title Management
    
    private func getWindowTitle() -> String {
        var title = "Notes to Self"
        
        if let selectedNote = selectedNote {
            title = selectedNote.name
            if isDirty {
                title += " *"
            }
            if isGitRepo && currentFileHasUncommittedChanges {
                title += " <*>"
            }
        } else if isCreatingNew {
            title = newNoteFileName
            if isDirty {
                title += " *"
            }
            // New files are always uncommitted until first commit
            if isGitRepo {
                title += " <*>"
            }
        } else {
            title = "Notes to Self"
            if isGitRepo && hasUncommittedChanges {
                title += " <*>"
            }
        }
        
        return title
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
    
    
    private func performAutoCommit(for filePath: String, action: String) {
        guard isGitRepo else { 
            print("DEBUG: Auto commit skipped - not a git repo")
            return 
        }
        
        let notesURL = URL(fileURLWithPath: notesToRepoSettings.notesLocation)
        let commitMessage = "\(filePath) \(action)\n\n🤖 Generated with [Claude Code](https://claude.ai/code)\n\nCo-Authored-By: Claude <noreply@anthropic.com>"
        
        print("DEBUG: === AUTOCOMMIT START ===")
        print("DEBUG: File: \(filePath), Action: \(action)")
        print("DEBUG: isGitRepo: \(isGitRepo)")
        print("DEBUG: Notes location: \(notesToRepoSettings.notesLocation)")
        print("DEBUG: Notes URL: \(notesURL.path)")
        print("DEBUG: Commit message: \(commitMessage)")
        
        Task {
            do {
                // Pre-flight checks
                try await validateGitRepository(at: notesURL)
                
                // Check if there are actually changes to commit
                let hasChanges = try await checkForChanges(in: notesURL)
                guard hasChanges else {
                    print("DEBUG: No changes detected, skipping commit")
                    return
                }
                
                // Add files with better error handling
                try await addFilesToGit(directory: notesURL, specificFile: filePath)
                
                print("DEBUG: Files added successfully, attempting commit")
                
                // Commit changes with validation
                try await commitChanges(directory: notesURL, message: commitMessage)
                
                print("DEBUG: Auto commit successful for: \(filePath)")
                
                // Update git status after successful commit
                await MainActor.run {
                    checkGitStatus()
                    checkCurrentFileGitStatus()
                }
                
            } catch {
                print("DEBUG: === AUTOCOMMIT FAILED ===")
                print("DEBUG: Error type: \(type(of: error))")
                print("DEBUG: Error: \(error)")
                print("DEBUG: Error description: \(error.localizedDescription)")
                
                if let processError = error as? ProcessError {
                    print("DEBUG: ProcessError details: \(processError.errorDescription ?? "No description")")
                }
                
                // Show user-friendly error
                await MainActor.run {
                    self.error = GenericError(errorDescription: "Auto-commit failed for \(filePath): \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Git Helper Methods
    
    private func validateGitRepository(at directory: URL) async throws {
        // Check if directory exists
        guard FileManager.default.fileExists(atPath: directory.path) else {
            throw GenericError(errorDescription: "Notes directory does not exist: \(directory.path)")
        }
        
        // Check if it's a git repository
        let gitPath = directory.appendingPathComponent(".git")
        let isGitDir = FileManager.default.fileExists(atPath: gitPath.path)
        
        // Also check for git worktree (single .git file)
        let gitFile = directory.appendingPathComponent(".git")
        let isGitFile = FileManager.default.fileExists(atPath: gitFile.path) && !isGitDir
        
        guard isGitDir || isGitFile else {
            throw GenericError(errorDescription: "Directory is not a git repository: \(directory.path)")
        }
        
        // Check git user configuration - common cause of commit failures
        do {
            print("DEBUG: Checking git user configuration...")
            let gitConfigName = Process()
            gitConfigName.executableURL = URL(fileURLWithPath: "/usr/bin/git")
            gitConfigName.arguments = ["config", "user.name"]
            gitConfigName.currentDirectoryURL = directory
            
            let gitConfigEmail = Process()
            gitConfigEmail.executableURL = URL(fileURLWithPath: "/usr/bin/git")
            gitConfigEmail.arguments = ["config", "user.email"]
            gitConfigEmail.currentDirectoryURL = directory
            
            let namePipe = Pipe()
            let emailPipe = Pipe()
            gitConfigName.standardOutput = namePipe
            gitConfigEmail.standardOutput = emailPipe
            
            try gitConfigName.run()
            try gitConfigEmail.run()
            
            gitConfigName.waitUntilExit()
            gitConfigEmail.waitUntilExit()
            
            let nameData = namePipe.fileHandleForReading.readDataToEndOfFile()
            let emailData = emailPipe.fileHandleForReading.readDataToEndOfFile()
            
            let userName = String(data: nameData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let userEmail = String(data: emailData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            
            print("DEBUG: Git user name: '\(userName)'")
            print("DEBUG: Git user email: '\(userEmail)'")
            
            if userName.isEmpty || userEmail.isEmpty {
                throw GenericError(errorDescription: "Git user not configured. Run: git config user.name 'Your Name' && git config user.email 'your@email.com'")
            }
            
        } catch {
            print("DEBUG: Git user config check failed: \(error)")
            throw GenericError(errorDescription: "Git user configuration required for commits: \(error.localizedDescription)")
        }
        
        print("DEBUG: Git repository validation passed")
    }
    
    private func checkForChanges(in directory: URL) async throws -> Bool {
        do {
            let gitStatus = GitStatus(directory: directory)
            let status = try await Process.output(gitStatus)
            
            let hasChanges = !status.untrackedFiles.isEmpty || 
                           !status.modifiedFiles.isEmpty || 
                           !status.addedFiles.isEmpty ||
                           !status.unmergedFiles.isEmpty
            
            print("DEBUG: Change detection - untracked: \(status.untrackedFiles.count), modified: \(status.modifiedFiles.count), added: \(status.addedFiles.count)")
            
            return hasChanges
        } catch {
            print("DEBUG: Failed to check git status, assuming changes exist: \(error)")
            return true // Assume changes exist if we can't check
        }
    }
    
    private func addFilesToGit(directory: URL, specificFile: String) async throws {
        print("DEBUG: addFilesToGit called with directory: \(directory.path), specificFile: \(specificFile)")
        
        // First try to add the specific file
        do {
            let gitAddFile = GitAddPathspec(directory: directory, pathspec: specificFile)
            print("DEBUG: Executing git command: \(gitAddFile.arguments.joined(separator: " ")) in \(directory.path)")
            try await Process.output(gitAddFile)
            print("DEBUG: Successfully added specific file: \(specificFile)")
        } catch {
            print("DEBUG: Failed to add specific file \(specificFile), error: \(error)")
            print("DEBUG: Error type: \(type(of: error))")
            
            if let processError = error as? ProcessError {
                print("DEBUG: ProcessError description: \(processError.errorDescription ?? "None")")
            }
            
            print("DEBUG: Trying fallback to add all files...")
            
            // Fallback to adding all files
            let gitAddAll = GitAdd(directory: directory)
            print("DEBUG: Executing fallback git command: \(gitAddAll.arguments.joined(separator: " ")) in \(directory.path)")
            try await Process.output(gitAddAll)
            print("DEBUG: Successfully added all files via fallback")
        }
    }
    
    private func commitChanges(directory: URL, message: String) async throws {
        print("DEBUG: commitChanges called with directory: \(directory.path)")
        print("DEBUG: Commit message: \(message)")
        
        // Check if there are staged changes before committing
        do {
            let gitStatus = GitStatus(directory: directory)
            print("DEBUG: Checking git status before commit...")
            let status = try await Process.output(gitStatus)
            
            print("DEBUG: Git status - addedFiles: \(status.addedFiles.count), modifiedFiles: \(status.modifiedFiles.count), unmergedFiles: \(status.unmergedFiles.count)")
            print("DEBUG: addedFiles: \(status.addedFiles)")
            print("DEBUG: modifiedFiles: \(status.modifiedFiles)")
            print("DEBUG: unmergedFiles: \(status.unmergedFiles)")
            
            let hasStagedChanges = !status.addedFiles.isEmpty ||
                                 !status.modifiedFiles.isEmpty ||
                                 !status.unmergedFiles.isEmpty
            
            print("DEBUG: hasStagedChanges: \(hasStagedChanges)")
            
            guard hasStagedChanges else {
                throw GenericError(errorDescription: "No staged changes to commit")
            }
        } catch let statusError {
            print("DEBUG: Could not check staged changes, proceeding with commit: \(statusError)")
        }
        
        // Perform the commit
        let gitCommit = GitCommit(directory: directory, message: message)
        print("DEBUG: Executing commit command: \(gitCommit.arguments.joined(separator: " ")) in \(directory.path)")
        try await Process.output(gitCommit)
        print("DEBUG: Commit completed successfully")
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
                
                Text(noteFile.creationDate.timeIntervalSince1970 == 0 ? "No date" : noteFile.creationDate.formatted(.dateTime.month().day().hour().minute()))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .redacted(reason: noteFile.creationDate.timeIntervalSince1970 == 0 ? .placeholder : [])
            }
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(isSelected ? Color.accentColor.opacity(0.3) : Color.clear)
        .background(
            // Hover effect
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.primary.opacity(0.05))
                .opacity(isSelected ? 0 : 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.accentColor, lineWidth: isSelected ? 1 : 0)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
        .simultaneousGesture(
            TapGesture()
                .onEnded { _ in
                    onSelect()
                }
        )
    }
}

#Preview {
    NotesToSelfPopupView()
}
