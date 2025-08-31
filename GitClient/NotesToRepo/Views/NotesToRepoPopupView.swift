//
//  NotesToRepoPopupView.swift
//  GitClient
//
//  Created by Claude on 2025/08/29.
//  Refactored by Claude on 2025/08/31.
//

import SwiftUI
import Foundation
import Defaults

struct NotesToRepoPopupView: View {
    @Environment(\.folder) private var folder
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    
    @Default(.notesToRepoSettings) private var notesToRepoSettings
    @Default(.notesToRepoFileListWidth) private var fileListWidth
    @Default(.notesToRepoLastOpenedFile) private var lastOpenedFileID
    @Default(.notesToRepoFileListVisible) private var fileListVisible
    @Default(.notesToRepoStatusBarVisible) private var statusBarVisible
    
    @State private var noteFiles: [NoteFile] = []
    @State private var selectedNote: NoteFile?
    @State private var noteContent = ""
    @State private var isCreatingNew = false
    @State private var newNoteFileName = ""
    @State private var showDeleteConfirmation = false
    @State private var isDirty = false
    @State private var originalContent = ""
    @State private var isGitRepo = false
    @State private var error: Error?
    @State private var hasUncommittedChanges = false
    @State private var currentFileHasUncommittedChanges = false
    @State private var scrollID: String?
    @FocusState private var isFileListFocused: Bool
    @FocusState private var isEditorFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            NotesToRepoToolbar(
                isGitRepo: isGitRepo,
                selectedNote: selectedNote,
                fileListVisible: fileListVisible,
                onToggleFileList: { fileListVisible.toggle() },
                onOpenNotesRepo: { openNotesRepoInApp() },
                onCreateNote: { createNewNote() },
                onDeleteNote: { showDeleteConfirmation = true },
                onToggleStatusBar: { statusBarVisible.toggle() }
            )
            
            Divider()
            
            // Main Content Area
            HSplitView {
                // Left Panel - File List
                if fileListVisible {
                    fileListPanel()
                }
                
                // Right Panel - Editor View
                editorPanel()
            }
            
            // Status Bar
            if statusBarVisible {
                Divider()
                NotesToRepoStatusBar(
                    selectedNote: selectedNote,
                    isCreatingNew: isCreatingNew,
                    isGitRepo: isGitRepo,
                    hasUncommittedChanges: hasUncommittedChanges,
                    noteContent: noteContent,
                    notesToRepoSettings: notesToRepoSettings
                )
            }
        }
        .frame(minWidth: 600, maxWidth: .infinity,
               minHeight: 400, maxHeight: .infinity)
        .navigationTitle(getWindowTitle())
        .focusable()
        .onKeyPress(action: handleKeyPress)
        .onAppear { setupView() }
        .onDisappear { handleDisappear() }
        .confirmationDialog("Delete Note", isPresented: $showDeleteConfirmation,
                          actions: deleteConfirmationActions,
                          message: deleteConfirmationMessage)
        .errorSheet($error)
        .onChange(of: scenePhase) { oldPhase, newPhase in
            handleScenePhaseChange(oldPhase, newPhase)
        }
        .onChange(of: selectedNote?.id) { _, _ in
            checkCurrentFileGitStatus()
        }
        .onChange(of: isCreatingNew) { _, _ in
            checkCurrentFileGitStatus()
        }
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private func fileListPanel() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // File list header
            HStack {
                Text("Files")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(noteFiles.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Notes List with improved arrow key scrolling
            ScrollView(.vertical) {
                LazyVStack(spacing: 0) {
                    ForEach(noteFiles, id: \.id) { noteFile in
                        NoteFileRow(
                            noteFile: noteFile,
                            isSelected: selectedNote?.id == noteFile.id
                        ) {
                            selectNoteWithAutoSave(noteFile)
                        }
                        .id(noteFile.id)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollContentBackground(.hidden)
            .background(Color(NSColor.controlBackgroundColor))
            .scrollPosition(id: $scrollID)
            .focusable()
            .focused($isFileListFocused)
            .onKeyPress(action: handleFileListKeyPress)
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
    }
    
    @ViewBuilder
    private func editorPanel() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Editor header
            HStack {
                HStack(spacing: 8) {
                    if let selectedNote = selectedNote {
                        Text(selectedNote.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        if isDirty {
                            Circle()
                                .fill(.secondary)
                                .frame(width: 6, height: 6)
                                .help("Unsaved changes")
                        }
                        
                        if currentFileHasUncommittedChanges {
                            Image(systemName: "plus.circle.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                                .help("File has uncommitted changes")
                        }
                    } else if isCreatingNew {
                        Text(newNoteFileName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Circle()
                            .fill(.green)
                            .frame(width: 6, height: 6)
                            .help("New file")
                    } else {
                        Text("No note selected")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if selectedNote != nil || isCreatingNew {
                    HStack(spacing: 8) {
                        Button {
                            navigateUpWithDirtyCheck()
                        } label: {
                            Image(systemName: "chevron.up")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .disabled(!canNavigateUp())
                        .help("Previous note (↑)")
                        
                        Button {
                            navigateDownWithDirtyCheck()
                        } label: {
                            Image(systemName: "chevron.down")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .disabled(!canNavigateDown())
                        .help("Next note (↓)")
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Editor content
            if selectedNote != nil || isCreatingNew {
                TextEditor(text: $noteContent)
                    .scrollContentBackground(.hidden)
                    .background(Color(NSColor.textBackgroundColor))
                    .font(.system(.body, design: .monospaced, weight: .regular))
                    .padding(16)
                    .focused($isEditorFocused)
                    .onTapGesture {
                        isFileListFocused = false
                        isEditorFocused = true
                    }
                    .onChange(of: noteContent) { _, newValue in
                        updateDirtyState(newContent: newValue)
                    }
            } else {
                // Empty state
                VStack(spacing: 16) {
                    Spacer()
                    
                    VStack(spacing: 12) {
                        Image(systemName: "note.text")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                            .opacity(0.6)
                        
                        VStack(spacing: 4) {
                            Text("No note selected")
                                .font(.title2)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Text("Select a note from the list or create a new one")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Button {
                            createNewNote()
                        } label: {
                            Label("Create New Note", systemImage: "plus.circle.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(NSColor.textBackgroundColor))
            }
        }
        .frame(minWidth: 400)
    }
    
    // MARK: - Key Press Handling
    
    private func handleKeyPress(_ keyPress: KeyPress) -> KeyPress.Result {
        // Handle global keyboard shortcuts only
        if keyPress.modifiers.contains(.command) {
            switch keyPress.key {
            case KeyEquivalent("1"):
                fileListVisible.toggle()
                return .handled
            case KeyEquivalent("n"):
                createNewNote()
                return .handled
            default:
                break
            }
        }
        
        return .ignored
    }
    
    private func handleFileListKeyPress(_ keyPress: KeyPress) -> KeyPress.Result {
        // Handle file list specific navigation keys
        switch keyPress.key {
        case .upArrow:
            navigateUpWithDirtyCheck()
            return .handled
        case .downArrow:
            navigateDownWithDirtyCheck()
            return .handled
        case .return:
            if selectedNote == nil && !noteFiles.isEmpty {
                let firstNote = noteFiles[0]
                selectNoteWithAutoSave(firstNote)
                scrollID = firstNote.id
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
    
    // MARK: - Lifecycle & Setup
    
    private func setupView() {
        loadNotes()
        checkIfGitRepo()
        checkGitStatus()
        restoreLastOpenedFile()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isFileListFocused = true
        }
    }
    
    private func handleDisappear() {
        if isDirty {
            saveNote()
        }
    }
    
    private func handleScenePhaseChange(_ oldPhase: ScenePhase, _ newPhase: ScenePhase) {
        // Handle scene phase changes if needed
    }
    
    // MARK: - Note Operations
    
    private func loadNotes() {
        noteFiles = NoteFileManager.loadNoteFiles(for: folder, settings: notesToRepoSettings)
    }
    
    private func createNewNote() {
        if isDirty && (selectedNote != nil || isCreatingNew) {
            saveNote()
        }
        
        selectedNote = nil
        isCreatingNew = true
        checkCurrentFileGitStatus()
        
        let newNoteData = NotesToRepoFileService.createNewNote(settings: notesToRepoSettings, folder: folder)
        newNoteFileName = newNoteData.fileName
        noteContent = newNoteData.content
        originalContent = newNoteData.originalContent
        isDirty = newNoteData.isDirty
    }
    
    private func selectNote(_ noteFile: NoteFile) {
        if isDirty && (selectedNote != nil || isCreatingNew) {
            saveNote()
        }
        
        selectedNote = noteFile
        isCreatingNew = false
        updateLastOpenedFile()
        
        do {
            let noteData = try NotesToRepoFileService.loadNoteContent(from: noteFile)
            noteContent = noteData.content
            originalContent = noteData.originalContent
            isDirty = noteData.isDirty
            checkCurrentFileGitStatus()
        } catch {
            self.error = error
            noteContent = ""
            originalContent = ""
        }
        
        DispatchQueue.main.async {
            self.scrollID = noteFile.id
            self.isFileListFocused = true
            self.isEditorFocused = false
        }
    }
    
    private func selectNoteWithAutoSave(_ noteFile: NoteFile) {
        if isDirty {
            saveNote()
            selectNote(noteFile)
        } else {
            selectNote(noteFile)
        }
    }
    
    private func saveNote() {
        guard folder != nil else { return }
        
        Task {
            do {
                let result = try await NotesToRepoFileService.saveNoteWithAutoCommit(
                    content: noteContent,
                    selectedNote: selectedNote,
                    newFileName: newNoteFileName,
                    settings: notesToRepoSettings,
                    isCreatingNew: isCreatingNew,
                    isGitRepo: isGitRepo
                )
                
                await MainActor.run {
                    // Update state
                    originalContent = noteContent
                    isDirty = false
                    
                    // Update file list and selection
                    if let updatedNote = NotesToRepoFileService.updateFileInList(
                        &noteFiles,
                        savedURL: result.savedURL,
                        notesLocation: notesToRepoSettings.notesLocation,
                        wasCreatingNew: result.wasCreatingNew
                    ) {
                        selectedNote = updatedNote
                        isCreatingNew = false
                    }
                    
                    // Refresh Git status
                    checkGitStatus()
                    checkCurrentFileGitStatus()
                }
                
            } catch {
                await MainActor.run {
                    self.error = error
                }
            }
        }
    }
    
    // MARK: - Navigation
    
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
            scrollID = previousNote.id
        } else if selectedNote == nil {
            selectNote(noteFiles[0])
            scrollID = noteFiles[0].id
        }
        
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
            scrollID = nextNote.id
        } else if selectedNote == nil {
            selectNote(noteFiles[0])
            scrollID = noteFiles[0].id
        }
        
        isFileListFocused = true
        isEditorFocused = false
    }
    
    private func navigateUpWithDirtyCheck() {
        if isDirty {
            saveNote()
            navigateUp()
        } else {
            navigateUp()
        }
    }
    
    private func navigateDownWithDirtyCheck() {
        if isDirty {
            saveNote()
            navigateDown()
        } else {
            navigateDown()
        }
    }
    
    // MARK: - Git Operations
    
    private func checkIfGitRepo() {
        isGitRepo = NotesToRepoGitService.isGitRepository(at: notesToRepoSettings.notesLocation)
    }
    
    private func checkGitStatus() {
        guard isGitRepo else {
            hasUncommittedChanges = false
            currentFileHasUncommittedChanges = false
            return
        }
        
        let notesURL = URL(fileURLWithPath: notesToRepoSettings.notesLocation)
        
        Task {
            let result = await NotesToRepoGitService.checkGitStatus(at: notesURL)
            await MainActor.run {
                hasUncommittedChanges = result.hasChanges
                checkCurrentFileGitStatus()
            }
        }
    }
    
    private func checkCurrentFileGitStatus() {
        guard isGitRepo else {
            currentFileHasUncommittedChanges = false
            return
        }
        
        if isCreatingNew {
            currentFileHasUncommittedChanges = true
            return
        }
        
        guard let selectedNote = selectedNote else {
            currentFileHasUncommittedChanges = false
            return
        }
        
        let notesURL = URL(fileURLWithPath: notesToRepoSettings.notesLocation)
        
        Task {
            let hasChanges = await NotesToRepoGitService.checkCurrentFileGitStatus(file: selectedNote, notesURL: notesURL)
            await MainActor.run {
                currentFileHasUncommittedChanges = hasChanges
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func updateDirtyState(newContent: String) {
        isDirty = (newContent != originalContent)
    }
    
    private func getWindowTitle() -> String {
        let repoName = NoteFileManager.getRepositoryName(for: folder)
        var title = "Notes to Repo - \(repoName) (\(noteFiles.count))"
        
        if isDirty {
            title += " •"
        }
        
        if isGitRepo && (currentFileHasUncommittedChanges || hasUncommittedChanges) {
            title += " ⚠"
        }
        
        return title
    }
    
    private func updateLastOpenedFile() {
        if let selectedNote = selectedNote {
            lastOpenedFileID = selectedNote.id
        }
    }
    
    private func restoreLastOpenedFile() {
        if let fileToRestore = NotesToRepoFileService.findFileToRestore(
            in: noteFiles,
            lastOpenedFileID: lastOpenedFileID
        ) {
            selectNote(fileToRestore)
            scrollID = fileToRestore.id
        } else {
            createNewNote()
        }
    }
    
    private func openNotesRepoInApp() {
        guard !notesToRepoSettings.notesLocation.isEmpty else { return }
        
        let notesURL = URL(fileURLWithPath: notesToRepoSettings.notesLocation)
        let newFolder = Folder(url: notesURL)
        
        var currentFolders = Defaults[.folders]
        currentFolders.removeAll { $0.url == notesURL }
        currentFolders.insert(newFolder, at: 0)
        Defaults[.folders] = currentFolders
        
        NotificationCenter.default.post(
            name: NSNotification.Name("SelectRepository"),
            object: notesURL
        )
        
        dismiss()
    }
    
    // MARK: - Delete Confirmation
    
    @ViewBuilder
    private func deleteConfirmationActions() -> some View {
        Button("Delete", role: .destructive) {
            deleteSelectedNote()
        }
        Button("Cancel", role: .cancel) {}
    }
    
    @ViewBuilder
    private func deleteConfirmationMessage() -> some View {
        Text("Are you sure you want to delete this note? This action cannot be undone.")
    }
    
    private func deleteSelectedNote() {
        guard let selectedNote = selectedNote,
              let currentIndex = noteFiles.firstIndex(where: { $0.id == selectedNote.id }) else { return }
        
        Task {
            do {
                try await NotesToRepoFileService.deleteNoteWithAutoCommit(
                    selectedNote,
                    settings: notesToRepoSettings,
                    isGitRepo: isGitRepo
                )
                
                await MainActor.run {
                    // Reload notes after deletion
                    loadNotes()
                    
                    // Navigate to next note or create new one
                    if let nextNote = NotesToRepoFileService.findNavigationTarget(in: noteFiles, after: currentIndex) {
                        selectNote(nextNote)
                        scrollID = nextNote.id
                    } else {
                        createNewNote()
                    }
                    
                    // Refresh Git status
                    checkGitStatus()
                    checkCurrentFileGitStatus()
                }
                
            } catch {
                await MainActor.run {
                    self.error = error
                }
            }
        }
    }
}

#Preview {
    NotesToRepoPopupView()
}