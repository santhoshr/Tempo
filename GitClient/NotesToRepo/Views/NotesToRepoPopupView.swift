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
    @Default(.notesToRepoAutoSave) private var autoSaveEnabled
    @Default(.notesToRepoFileListWidth) private var fileListWidth
    @Default(.notesToRepoLastOpenedFile) private var lastOpenedFileID
    @Default(.notesToRepoFileListVisible) private var fileListVisible
    @Default(.notesToRepoStatusBarVisible) private var statusBarVisible
    @Default(.notesToRepoProjectFileExtensions) private var projectFileExtensions
    @Default(.notesToRepoProjectInitialLoad) private var projectInitialLoad
    
    @State private var noteFiles: [NoteFile] = []
    @State private var selectedNote: NoteFile?
    @State private var noteContent = ""
    @State private var isCreatingNew = false
    
    // Project tab state
    enum FileListTab: Hashable { case notes, project }
    @State private var activeTab: FileListTab = .notes
    @State private var projectFiles: [URL] = []
    @State private var displayedProjectFiles: [URL] = []
    @State private var projectLoadedCount: Int = 0
    @State private var isLoadingProjectFiles = false
    @State private var newNoteFileName = ""
    @State private var showDeleteConfirmation = false
    @State private var isDirty = false
    @State private var originalContent = ""
    @State private var isGitRepo = false
    @State private var error: Error?
    @State private var hasUncommittedChanges = false
    @State private var currentFileHasUncommittedChanges = false
    @State private var scrollID: String?
    @State private var autoSaveTimer: Timer?
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
                onRevealInFinder: { revealNotesLocationInFinder() },
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
        .onKeyPress(phases: [.down], action: handleKeyPress)
        .onAppear { setupView(); if activeTab == .project { loadProjectFilesIfNeeded() } }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("CreateNewNoteFromWindow"))) { _ in
            createNewNote()
        }
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
            // File list header with tabs
            HStack(spacing: 12) {
                Picker("", selection: $activeTab) {
                    Text("Notes").tag(FileListTab.notes)
                    Text("Project").tag(FileListTab.project)
                }
                .pickerStyle(.segmented)
                .frame(width: 180)
                .onChange(of: activeTab) { _, newTab in
                    if newTab == .project {
                        loadProjectFilesIfNeeded()
                    }
                }

                Spacer()

                if activeTab == .notes {
                    Text("\(noteFiles.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("\(projectFiles.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Notes/Project List with improved arrow key scrolling
            ScrollView(.vertical) {
                LazyVStack(spacing: 0) {
                    if activeTab == .notes {
                        ForEach(noteFiles, id: \.id) { noteFile in
                            NoteFileRow(
                                noteFile: noteFile,
                                isSelected: selectedNote?.id == noteFile.id
                            ) {
                                selectNoteWithAutoSave(noteFile)
                            }
                            .id(noteFile.id)
                        }
                    } else {
                        ForEach(displayedProjectFiles, id: \.path) { fileURL in
                            ProjectFileRow(fileURL: fileURL, repoRoot: folder?.url.path ?? "",
                                           onReveal: { NSWorkspace.shared.selectFile(fileURL.path, inFileViewerRootedAtPath: folder?.url.path ?? "") })
                            .id(fileURL.path)
                        }
                        if projectLoadedCount < projectFiles.count {
                            HStack {
                                Spacer()
                                Button(action: loadMoreProjectFiles) {
                                    if isLoadingProjectFiles {
                                        ProgressView().controlSize(.small)
                                    } else {
                                        Text("Load more")
                                    }
                                }
                                .buttonStyle(.bordered)
                                .padding(.vertical, 8)
                                Spacer()
                            }
                        }
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
                        .help("Previous note (↑ or ⌘↑ or ⌘← or ⌘K or ⌘H)")
                        
                        Button {
                            navigateDownWithDirtyCheck()
                        } label: {
                            Image(systemName: "chevron.down")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .disabled(!canNavigateDown())
                        .help("Next note (↓ or ⌘↓ or ⌘→ or ⌘J or ⌘L)")
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
                    .onKeyPress(action: handleEditorKeyPress)
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
        // Handle global keyboard shortcuts
        if keyPress.modifiers.contains(.command) {
            switch keyPress.key {
            case KeyEquivalent("1"):
                fileListVisible.toggle()
                return .handled
            case KeyEquivalent("n"):
                createNewNote()
                return .handled
            // File navigation shortcuts (Cmd+Arrow keys)
            case .upArrow:
                navigateUpWithDirtyCheck() // Previous file
                return .handled
            case .downArrow:
                navigateDownWithDirtyCheck() // Next file
                return .handled
            case .leftArrow:
                navigateUpWithDirtyCheck() // Previous file (left = up in file list)
                return .handled
            case .rightArrow:
                navigateDownWithDirtyCheck() // Next file (right = down in file list)
                return .handled
            // Vim-style navigation (Cmd+HJKL)
            case KeyEquivalent("h"):
                navigateUpWithDirtyCheck() // h = left = previous file
                return .handled
            case KeyEquivalent("j"):
                navigateDownWithDirtyCheck() // j = down = next file
                return .handled
            case KeyEquivalent("k"):
                navigateUpWithDirtyCheck() // k = up = previous file
                return .handled
            case KeyEquivalent("l"):
                navigateDownWithDirtyCheck() // l = right = next file
                return .handled
            case KeyEquivalent("b"):
                toggleSidebarWithFocus() // Toggle sidebar with proper focus management
                return .handled
            case .delete, .deleteForward:
                if selectedNote != nil {
                    showDeleteConfirmation = true
                    return .handled
                }
                return .ignored
            case KeyEquivalent("\u{7f}"), KeyEquivalent("\u{08}"):  // Backspace characters
                if selectedNote != nil {
                    showDeleteConfirmation = true
                    return .handled
                }
                return .ignored
            default:
                break
            }
        }
        
        // Handle Cmd+Alt shortcuts
        if keyPress.modifiers.contains(.command) && keyPress.modifiers.contains(.option) {
            switch keyPress.key {
            case KeyEquivalent("s"):
                statusBarVisible.toggle() // Toggle status bar
                return .handled
            default:
                break
            }
        }
        
        return .ignored
    }
    
    private func handleEditorKeyPress(_ keyPress: KeyPress) -> KeyPress.Result {
        // Handle Cmd+navigation shortcuts from editor
        if keyPress.modifiers.contains(.command) {
            switch keyPress.key {
            case .upArrow, .leftArrow, KeyEquivalent("k"), KeyEquivalent("h"):
                navigateUpWithDirtyCheck()
                return .handled
            case .downArrow, .rightArrow, KeyEquivalent("j"), KeyEquivalent("l"):
                navigateDownWithDirtyCheck()
                return .handled
            case KeyEquivalent("n"):
                createNewNote()
                return .handled
            case KeyEquivalent("b"):
                toggleSidebarWithFocus() // Toggle sidebar with proper focus management
                return .handled
            case KeyEquivalent("1"):
                fileListVisible.toggle()
                return .handled
            case .delete, .deleteForward:
                if selectedNote != nil {
                    showDeleteConfirmation = true
                    return .handled
                }
                return .ignored
            case KeyEquivalent("\u{7f}"), KeyEquivalent("\u{08}"):  // Backspace characters
                if selectedNote != nil {
                    showDeleteConfirmation = true
                    return .handled
                }
                return .ignored
            default:
                break
            }
        }
        
        // Handle Cmd+Alt shortcuts
        if keyPress.modifiers.contains(.command) && keyPress.modifiers.contains(.option) {
            switch keyPress.key {
            case KeyEquivalent("s"):
                statusBarVisible.toggle() // Toggle status bar
                return .handled
            default:
                break
            }
        }
        
        return .ignored
    }
    
    private func handleFileListKeyPress(_ keyPress: KeyPress) -> KeyPress.Result {
        // Handle Cmd+arrow keys and Cmd+HJKL first (global shortcuts)
        if keyPress.modifiers.contains(.command) {
            switch keyPress.key {
            case .upArrow, .leftArrow, KeyEquivalent("k"), KeyEquivalent("h"):
                navigateUpWithDirtyCheck()
                return .handled
            case .downArrow, .rightArrow, KeyEquivalent("j"), KeyEquivalent("l"):
                navigateDownWithDirtyCheck()
                return .handled
            case KeyEquivalent("n"):
                createNewNote()
                return .handled
            case KeyEquivalent("1"):
                fileListVisible.toggle()
                return .handled
            case KeyEquivalent("b"):
                toggleSidebarWithFocus() // Toggle sidebar with proper focus management
                return .handled
            case .delete, .deleteForward:
                if selectedNote != nil {
                    showDeleteConfirmation = true
                    return .handled
                }
                return .ignored
            case KeyEquivalent("\u{7f}"), KeyEquivalent("\u{08}"):  // Backspace characters
                if selectedNote != nil {
                    showDeleteConfirmation = true
                    return .handled
                }
                return .ignored
            default:
                break
            }
        }
        
        // Handle Cmd+Alt shortcuts
        if keyPress.modifiers.contains(.command) && keyPress.modifiers.contains(.option) {
            switch keyPress.key {
            case KeyEquivalent("s"):
                statusBarVisible.toggle() // Toggle status bar
                return .handled
            default:
                break
            }
        }
        
        // Handle file list specific navigation keys (regular arrows)
        switch keyPress.key {
        case .upArrow:
            navigateUpWithDirtyCheck()
            return .handled
        case .downArrow:
            navigateDownWithDirtyCheck()
            return .handled
        case .return:
            if selectedNote != nil {
                // File is already selected, focus the editor
                isFileListFocused = false
                isEditorFocused = true
                return .handled
            } else if !noteFiles.isEmpty {
                // No file selected, select the first one
                let firstNote = noteFiles[0]
                selectNoteWithAutoSave(firstNote)
                withAnimation(.easeInOut(duration: 0.2)) {
                    scrollID = firstNote.id
                }
                return .handled
            }
            return .ignored
        case .delete, .deleteForward:
            if selectedNote != nil {
                showDeleteConfirmation = true
                return .handled
            }
            return .ignored
        case KeyEquivalent("\u{7f}"), KeyEquivalent("\u{08}"):  // Backspace characters
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
        // Ensure default tab is Notes
        activeTab = .notes
        loadNotes()
        checkIfGitRepo()
        checkGitStatus()
        restoreLastOpenedFile()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isFileListFocused = true
        }
    }
    
    // MARK: - Project Tab
    private func loadProjectFilesIfNeeded() {
        guard let repoURL = folder?.url else { return }
        if !projectFiles.isEmpty { return }
        loadProjectFiles(from: repoURL)
    }
    
    private func loadProjectFiles(from repoURL: URL) {
        isLoadingProjectFiles = true
        let allowedExts = Set(projectFileExtensions.map { $0.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: ".")) })
        let rootPath = repoURL.path
        DispatchQueue.global(qos: .userInitiated).async {
            var collected: [(url: URL, depth: Int, rel: String)] = []
            let fm = FileManager.default
            if let en = fm.enumerator(at: repoURL, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles, .skipsPackageDescendants]) {
                for case let fileURL as URL in en {
                    let ext = fileURL.pathExtension.lowercased()
                    guard allowedExts.contains(ext) else { continue }
                    let fullPath = fileURL.path
                    var rel = fullPath
                    if rel.hasPrefix(rootPath) { rel.removeFirst(rootPath.count) }
                    rel = rel.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
                    let depth = rel.isEmpty ? 0 : rel.components(separatedBy: "/").count - 1
                    collected.append((fileURL, depth, rel))
                }
            }
            // Sort: shallow first by depth, then by relative path alphabetical
            collected.sort { (a, b) in
                if a.depth != b.depth { return a.depth < b.depth }
                return a.rel.localizedCaseInsensitiveCompare(b.rel) == .orderedAscending
            }
            let sortedURLs = collected.map { $0.url }
            DispatchQueue.main.async {
                self.projectFiles = sortedURLs
                self.projectLoadedCount = 0
                self.displayedProjectFiles.removeAll()
                self.loadMoreProjectFiles()
                self.isLoadingProjectFiles = false
            }
        }
    }
    
    private func loadMoreProjectFiles() {
        guard projectLoadedCount < projectFiles.count else { return }
        let next = min(projectLoadedCount + max(1, projectInitialLoad), projectFiles.count)
        displayedProjectFiles.append(contentsOf: projectFiles[projectLoadedCount..<next])
        projectLoadedCount = next
    }
    
    private func handleDisappear() {
        // Cancel auto-save timer
        autoSaveTimer?.invalidate()
        autoSaveTimer = nil
        
        // Save any remaining changes
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
        
        let currentlySelectedNote = selectedNote
        selectedNote = nil
        isCreatingNew = true
        checkCurrentFileGitStatus()
        
        let newNoteData = NotesToRepoFileService.createNewNote(settings: notesToRepoSettings, folder: folder, selectedNote: currentlySelectedNote)
        newNoteFileName = newNoteData.fileName
        noteContent = newNoteData.content
        originalContent = newNoteData.originalContent
        isDirty = newNoteData.isDirty
        
        // Ensure file list is visible for context when creating new notes
        if !fileListVisible {
            fileListVisible = true
        }
        
        // Focus the editor when creating a new note
        DispatchQueue.main.async {
            self.isFileListFocused = false
            self.isEditorFocused = true
        }
    }
    
    private func selectNote(_ noteFile: NoteFile) {
        if isDirty && (selectedNote != nil || isCreatingNew) {
            Task {
                await saveNoteAsync()
                await MainActor.run {
                    performNoteSelection(noteFile)
                }
            }
            return
        }
        
        performNoteSelection(noteFile)
    }
    
    private func performNoteSelection(_ noteFile: NoteFile) {
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
            withAnimation(.easeInOut(duration: 0.2)) {
                self.scrollID = noteFile.id
            }
            // Focus management: file list if visible, editor if sidebar is closed
            if self.fileListVisible {
                // Sidebar is open - focus file list for subsequent navigation
                self.isEditorFocused = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    self.isFileListFocused = true
                }
            } else {
                // Sidebar is closed - focus editor for subsequent navigation
                self.isFileListFocused = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    self.isEditorFocused = true
                }
            }
        }
    }
    
    private func selectNoteWithAutoSave(_ noteFile: NoteFile) {
        if isDirty {
            Task {
                await saveNoteAsync()
                await MainActor.run {
                    performNoteSelection(noteFile)
                }
            }
        } else {
            performNoteSelection(noteFile)
        }
    }
    
    private func saveNote() {
        guard folder != nil else { return }
        
        // Cancel any pending auto-save
        autoSaveTimer?.invalidate()
        autoSaveTimer = nil
        
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
    
    private func saveNoteAsync() async {
        guard folder != nil else { return }
        
        // Cancel any pending auto-save
        await MainActor.run {
            autoSaveTimer?.invalidate()
            autoSaveTimer = nil
        }
        
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
            withAnimation(.easeInOut(duration: 0.2)) {
                scrollID = previousNote.id
            }
        } else if selectedNote == nil {
            selectNote(noteFiles[0])
            withAnimation(.easeInOut(duration: 0.2)) {
                scrollID = noteFiles[0].id
            }
        }
    }
    
    private func navigateDown() {
        guard !noteFiles.isEmpty else { return }
        
        if let currentNote = selectedNote,
           let currentIndex = noteFiles.firstIndex(where: { $0.id == currentNote.id }),
           currentIndex < noteFiles.count - 1 {
            let nextNote = noteFiles[currentIndex + 1]
            selectNote(nextNote)
            withAnimation(.easeInOut(duration: 0.2)) {
                scrollID = nextNote.id
            }
        } else if selectedNote == nil {
            selectNote(noteFiles[0])
            withAnimation(.easeInOut(duration: 0.2)) {
                scrollID = noteFiles[0].id
            }
        }
    }
    
    private func navigateUpWithDirtyCheck() {
        if isDirty {
            Task {
                await saveNoteAsync()
                await MainActor.run {
                    navigateUp()
                }
            }
        } else {
            navigateUp()
        }
    }
    
    private func navigateDownWithDirtyCheck() {
        if isDirty {
            Task {
                await saveNoteAsync()
                await MainActor.run {
                    navigateDown()
                }
            }
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
    
    private func toggleSidebarWithFocus() {
        fileListVisible.toggle()
        
        // Manage focus when toggling sidebar
        if fileListVisible {
            // Sidebar is now visible - focus it if we have files
            if !noteFiles.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    self.isEditorFocused = false
                    self.isFileListFocused = true
                }
            }
        } else {
            // Sidebar is now hidden - focus editor if we have content
            if selectedNote != nil || isCreatingNew {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    self.isFileListFocused = false
                    self.isEditorFocused = true
                }
            }
        }
    }
    
    private func updateDirtyState(newContent: String) {
        isDirty = (newContent != originalContent)
        
        // Schedule auto-save if enabled and there are changes
        if autoSaveEnabled && isDirty {
            scheduleAutoSave()
        }
    }
    
    private func scheduleAutoSave() {
        // Cancel existing timer
        autoSaveTimer?.invalidate()
        
        // Schedule new auto-save in 3 seconds
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            Task { @MainActor in
                if self.isDirty {
                    self.saveNote()
                }
            }
        }
    }
    
    private func getWindowTitle() -> String {
        let repoName = NoteFileManager.getRepositoryName(for: folder)
        
        var title = "Notes to Repo - \(repoName)"
        
        // Add position indicator if we have files and a selected note
        if !noteFiles.isEmpty {
            if let selectedNote = selectedNote,
               let currentIndex = noteFiles.firstIndex(where: { $0.id == selectedNote.id }) {
                title += " (\(currentIndex + 1) of \(noteFiles.count))"
            } else if isCreatingNew {
                title += " (new of \(noteFiles.count))"
            } else {
                title += " (\(noteFiles.count))"
            }
        } else {
            title += " (empty)"
        }
        
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
            withAnimation(.easeInOut(duration: 0.2)) {
                scrollID = fileToRestore.id
            }
        } else {
            createNewNote()
        }
    }
    
    private func revealNotesLocationInFinder() {
        guard !notesToRepoSettings.notesLocation.isEmpty else { return }
        
        // If we have a selected note, reveal that specific file
        if let selectedNote = selectedNote {
            NSWorkspace.shared.selectFile(selectedNote.url.path, inFileViewerRootedAtPath: notesToRepoSettings.notesLocation)
        } else {
            // Otherwise, reveal the notes directory
            let notesURL = URL(fileURLWithPath: notesToRepoSettings.notesLocation)
            NSWorkspace.shared.open(notesURL)
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
        Button("Cancel", role: .cancel) {}
        Button("Delete", role: .destructive) {
            deleteSelectedNote()
        }
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
                        withAnimation(.easeInOut(duration: 0.2)) {
                            scrollID = nextNote.id
                        }
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
