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
    @State private var projectFilterText = ""
    @State private var selectedProjectFile: URL?
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
    
    private var fileCountText: some View {
        Text("\(activeTab == .notes ? noteFiles.count : projectFiles.count)")
            .font(.caption)
            .foregroundColor(.secondary)
    }
    
    private var tabPicker: some View {
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
    }
    
    private var fileListHeader: some View {
        HStack(spacing: 12) {
            tabPicker
            Spacer()
            fileCountText
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    @ViewBuilder
    private var fileListContent: some View {
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
                ProjectFileRow(
                    fileURL: fileURL, 
                    repoRoot: folder?.path ?? "",
                    isSelected: selectedProjectFile?.path == fileURL.path,
                    onSelect: {
                        selectProjectFile(fileURL)
                    }
                )
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
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            NotesToRepoToolbar(
                projectFilterText: $projectFilterText,
                isProjectTab: activeTab == .project,
                isGitRepo: isGitRepo,
                selectedNote: selectedNote,
                fileListVisible: fileListVisible,
                onToggleFileList: { fileListVisible.toggle() },
                onOpenNotesRepo: { openNotesRepoInApp() },
                onRevealInFinder: { 
                    if activeTab == .project {
                        if let selectedProjectFile = selectedProjectFile {
                            NSWorkspace.shared.selectFile(selectedProjectFile.path, inFileViewerRootedAtPath: folder?.path ?? "")
                        } else if let folder = folder {
                            NSWorkspace.shared.open(folder)
                        }
                    } else {
                        if let selectedNote = selectedNote {
                            NSWorkspace.shared.selectFile(selectedNote.url.path, inFileViewerRootedAtPath: notesToRepoSettings.notesLocation)
                        } else {
                            let notesURL = URL(fileURLWithPath: notesToRepoSettings.notesLocation)
                            NSWorkspace.shared.open(notesURL)
                        }
                    }
                },
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
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ReloadProjectFiles"))) { _ in
            if activeTab == .project {
                loadProjectFilesIfNeeded(forceReload: true)
            }
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
            fileListHeader
            
            Divider()
            
            // Notes/Project List with improved arrow key scrolling
            ScrollView(.vertical) {
                LazyVStack(spacing: 0) {
                    fileListContent
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
            .overlay(
                // Focus ring when file list is focused
                RoundedRectangle(cornerRadius: 4)
                    .stroke(isFileListFocused ? Color.accentColor : Color.clear, lineWidth: 2)
                    .opacity(isFileListFocused ? 0.6 : 0)
                    .animation(.easeInOut(duration: 0.2), value: isFileListFocused)
            )
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
                    } else if let selectedProjectFile = selectedProjectFile {
                        Text(selectedProjectFile.lastPathComponent)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("(Project File)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("No file selected")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if selectedNote != nil || isCreatingNew || selectedProjectFile != nil {
                    HStack(spacing: 8) {
                        Button {
                            if activeTab == .notes {
                                navigateUpWithDirtyCheck()
                            } else {
                                navigateFileList(direction: .up)
                            }
                        } label: {
                            Image(systemName: "chevron.up")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .disabled(!canNavigateUp())
                        .help("Previous file (↑ or ⌘↑ or ⌘← or ⌘K or ⌘H)")
                        
                        Button {
                            if activeTab == .notes {
                                navigateDownWithDirtyCheck()
                            } else {
                                navigateFileList(direction: .down)
                            }
                        } label: {
                            Image(systemName: "chevron.down")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .disabled(!canNavigateDown())
                        .help("Next file (↓ or ⌘↓ or ⌘→ or ⌘J or ⌘L)")
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
            } else if selectedProjectFile != nil {
                ReadOnlyTextView(text: noteContent)
                    .background(Color(NSColor.textBackgroundColor))
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
            case .home:
                navigateToFirstFile()
                return .handled
            case .end:
                navigateToLastFile()
                return .handled
            default:
                break
            }
        }
        
        // Handle basic navigation without modifiers
        switch keyPress.key {
        case .upArrow:
            navigateFileList(direction: .up)
            return .handled
        case .downArrow:
            navigateFileList(direction: .down)
            return .handled
        case .pageUp:
            navigateFileList(direction: .pageUp)
            return .handled
        case .pageDown:
            navigateFileList(direction: .pageDown)
            return .handled
        case .home:
            navigateToFirstFile()
            return .handled
        case .end:
            navigateToLastFile()
            return .handled
        case .return, .space:
            if selectedNote != nil {
                isEditorFocused = true
            }
            return .handled
        case .delete, .deleteForward:
            if selectedNote != nil {
                showDeleteConfirmation = true
                return .handled
            }
            return .ignored
        default:
            break
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
    private func loadProjectFilesIfNeeded(forceReload: Bool = false) {
        guard let repoURL = folder else { return }
        if !forceReload && !projectFiles.isEmpty { return }
        loadProjectFiles(from: repoURL)
    }
    
    private func loadProjectFiles(from repoURL: URL) {
        isLoadingProjectFiles = true
        
        // Use projectFilterText if not empty, otherwise fall back to default extensions
        let extensions: [String]
        if !projectFilterText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            extensions = projectFilterText
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
                .map { $0.hasPrefix(".") ? String($0.dropFirst()) : $0 }
                .filter { !$0.isEmpty }
        } else {
            extensions = projectFileExtensions
        }
        
        let allowedExts = Set(extensions.map { $0.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: ".")) })
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
        if activeTab == .notes {
            guard !noteFiles.isEmpty else { return false }
            if let currentNote = selectedNote,
               let currentIndex = noteFiles.firstIndex(where: { $0.id == currentNote.id }) {
                return currentIndex > 0
            }
            return !noteFiles.isEmpty
        } else {
            guard !displayedProjectFiles.isEmpty else { return false }
            if let selectedProjectFile = selectedProjectFile,
               let currentIndex = displayedProjectFiles.firstIndex(where: { $0.path == selectedProjectFile.path }) {
                return currentIndex > 0
            }
            return !displayedProjectFiles.isEmpty
        }
    }
    
    private func canNavigateDown() -> Bool {
        if activeTab == .notes {
            guard !noteFiles.isEmpty else { return false }
            if let currentNote = selectedNote,
               let currentIndex = noteFiles.firstIndex(where: { $0.id == currentNote.id }) {
                return currentIndex < noteFiles.count - 1
            }
            return !noteFiles.isEmpty
        } else {
            guard !displayedProjectFiles.isEmpty else { return false }
            if let selectedProjectFile = selectedProjectFile,
               let currentIndex = displayedProjectFiles.firstIndex(where: { $0.path == selectedProjectFile.path }) {
                return currentIndex < displayedProjectFiles.count - 1
            }
            return !displayedProjectFiles.isEmpty
        }
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
    
    // MARK: - Enhanced File List Navigation
    
    enum NavigationDirection {
        case up, down, pageUp, pageDown
    }
    
    private func navigateFileList(direction: NavigationDirection) {
        if activeTab == .notes {
            guard !noteFiles.isEmpty else { return }
            
            let currentIndex: Int
            if let selectedNote = selectedNote,
               let index = noteFiles.firstIndex(where: { $0.id == selectedNote.id }) {
                currentIndex = index
            } else {
                currentIndex = -1
            }
            
            let newIndex: Int
            switch direction {
            case .up:
                newIndex = max(0, currentIndex - 1)
            case .down:
                newIndex = min(noteFiles.count - 1, currentIndex + 1)
            case .pageUp:
                newIndex = max(0, currentIndex - 10)
            case .pageDown:
                newIndex = min(noteFiles.count - 1, currentIndex + 10)
            }
            
            if newIndex != currentIndex && newIndex >= 0 && newIndex < noteFiles.count {
                let targetNote = noteFiles[newIndex]
                selectNoteWithAutoSave(targetNote)
                scrollToFile(targetNote)
            }
        } else {
            guard !displayedProjectFiles.isEmpty else { return }
            
            let currentIndex: Int
            if let selectedProjectFile = selectedProjectFile,
               let index = displayedProjectFiles.firstIndex(where: { $0.path == selectedProjectFile.path }) {
                currentIndex = index
            } else {
                currentIndex = -1
            }
            
            let newIndex: Int
            switch direction {
            case .up:
                newIndex = max(0, currentIndex - 1)
            case .down:
                newIndex = min(displayedProjectFiles.count - 1, currentIndex + 1)
            case .pageUp:
                newIndex = max(0, currentIndex - 10)
            case .pageDown:
                newIndex = min(displayedProjectFiles.count - 1, currentIndex + 10)
            }
            
            if newIndex != currentIndex && newIndex >= 0 && newIndex < displayedProjectFiles.count {
                let targetURL = displayedProjectFiles[newIndex]
                selectProjectFile(targetURL)
                withAnimation(.easeInOut(duration: 0.2)) {
                    scrollID = targetURL.path
                }
            }
        }
    }
    
    private func navigateToFirstFile() {
        if activeTab == .notes {
            guard let firstNote = noteFiles.first else { return }
            selectNoteWithAutoSave(firstNote)
            scrollToFile(firstNote)
        } else {
            guard let firstProjectFile = displayedProjectFiles.first else { return }
            selectProjectFile(firstProjectFile)
            withAnimation(.easeInOut(duration: 0.2)) {
                scrollID = firstProjectFile.path
            }
        }
    }
    
    private func navigateToLastFile() {
        if activeTab == .notes {
            guard let lastNote = noteFiles.last else { return }
            selectNoteWithAutoSave(lastNote)
            scrollToFile(lastNote)
        } else {
            guard let lastProjectFile = displayedProjectFiles.last else { return }
            selectProjectFile(lastProjectFile)
            withAnimation(.easeInOut(duration: 0.2)) {
                scrollID = lastProjectFile.path
            }
        }
    }
    
    private func scrollToFile(_ file: NoteFile) {
        withAnimation(.easeInOut(duration: 0.2)) {
            scrollID = file.id
        }
    }
    
    private func selectProjectFile(_ fileURL: URL) {
        selectedProjectFile = fileURL
        
        // Load file content for read-only viewing
        Task {
            do {
                let content = try String(contentsOf: fileURL, encoding: .utf8)
                await MainActor.run {
                    noteContent = content
                    originalContent = content
                    isDirty = false
                    selectedNote = nil // Clear note selection when viewing project file
                    isCreatingNew = false
                }
            } catch {
                await MainActor.run {
                    noteContent = "Error loading file: \(error.localizedDescription)"
                    originalContent = ""
                    isDirty = false
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
        let tabName = activeTab == .project ? "Project" : "Notes"
        
        var title = "Notes to Repo - \(repoName) [\(tabName)]"
        
        // Add position indicator based on active tab
        if activeTab == .project {
            if !displayedProjectFiles.isEmpty {
                if let selectedProjectFile = selectedProjectFile,
                   let currentIndex = displayedProjectFiles.firstIndex(where: { $0.path == selectedProjectFile.path }) {
                    title += " (\(currentIndex + 1) of \(displayedProjectFiles.count)"
                    if displayedProjectFiles.count < projectFiles.count {
                        title += "/\(projectFiles.count)"
                    }
                    title += ")"
                } else {
                    title += " (\(displayedProjectFiles.count)"
                    if displayedProjectFiles.count < projectFiles.count {
                        title += "/\(projectFiles.count)"
                    }
                    title += ")"
                }
            } else {
                title += " (empty)"
            }
        } else {
            // Notes tab
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

// MARK: - Enhanced Read-Only Text View

struct ReadOnlyTextView: NSViewRepresentable {
    let text: String
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        let textView = ReadOnlyNSTextView()
        textView.coordinator = context.coordinator
        context.coordinator.textView = textView
        textView.translatesAutoresizingMaskIntoConstraints = false
        
        // Configure text view for read-only with selection and scrolling
        textView.isEditable = false
        textView.isSelectable = true
        textView.isRichText = false
        textView.font = NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        textView.backgroundColor = NSColor.textBackgroundColor
        textView.string = text
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        
        // Configure scroll view
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = false
        scrollView.drawsBackground = false

        // Configure document view and constraints
        scrollView.documentView = textView
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainerInset = NSSize(width: 0, height: 0)
        
        // Ensure the text view tracks the width of the scroll view content
        let contentView = scrollView.contentView
        if let container = textView.textContainer {
            container.containerSize = NSSize(width: contentView.bounds.width, height: .greatestFiniteMagnitude)
            container.widthTracksTextView = true
        }

        // Set up coordinator for key handling
        textView.delegate = context.coordinator

        // Make the text view become first responder when the scroll view appears
        DispatchQueue.main.async {
            scrollView.window?.makeFirstResponder(textView)
        }

        return scrollView
    }
    
    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        if let textView = scrollView.documentView as? ReadOnlyNSTextView {
            if textView.string != text {
                textView.string = text
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class ReadOnlyNSTextView: NSTextView {
        weak var coordinator: Coordinator?
        
        override var acceptsFirstResponder: Bool { return true }
        override var isSelectable: Bool { get { true } set { } }
        
        override func awakeFromNib() {
            super.awakeFromNib()
            becomeFirstResponder()
        }
        
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            DispatchQueue.main.async {
                self.window?.makeFirstResponder(self)
            }
        }
        
        override func keyDown(with event: NSEvent) {
            interpretKeyEvents([event])
        }
        
        override func doCommand(by selector: Selector) {
            // Block editing commands
            if selector == NSSelectorFromString("insertText:") || 
               selector == #selector(deleteForward(_:)) || 
               selector == #selector(deleteBackward(_:)) || 
               selector == #selector(paste(_:)) {
                NSSound.beep()
                return
            }
            
            // Handle page up/down and document navigation with enhanced cursor positioning
            switch selector {
            case #selector(pageUp(_:)):
                pageUpAndMoveCursor(false)
                return
            case #selector(pageDown(_:)):
                pageDownAndMoveCursor(false)
                return
            case #selector(pageUpAndModifySelection(_:)):
                pageUpAndMoveCursor(true)
                return
            case #selector(pageDownAndModifySelection(_:)):
                pageDownAndMoveCursor(true)
                return
            case #selector(moveToBeginningOfDocument(_:)):
                moveToBeginningOfDocumentAndMoveCursor(false)
                return
            case #selector(moveToEndOfDocument(_:)):
                moveToEndOfDocumentAndMoveCursor(false)
                return
            case #selector(moveToBeginningOfDocumentAndModifySelection(_:)):
                moveToBeginningOfDocumentAndMoveCursor(true)
                return
            case #selector(moveToEndOfDocumentAndModifySelection(_:)):
                moveToEndOfDocumentAndMoveCursor(true)
                return
            default:
                break
            }
            
            // Allow standard text navigation and selection commands
            switch selector {
            case #selector(NSResponder.moveUp(_:)), #selector(NSResponder.moveDown(_:)),
                 #selector(moveLeft(_:)), #selector(moveRight(_:)),
                 #selector(moveUpAndModifySelection(_:)), #selector(moveDownAndModifySelection(_:)),
                 #selector(moveLeftAndModifySelection(_:)), #selector(moveRightAndModifySelection(_:)),
                 #selector(moveToBeginningOfLine(_:)), #selector(moveToEndOfLine(_:)),
                 #selector(moveToBeginningOfLineAndModifySelection(_:)), #selector(moveToEndOfLineAndModifySelection(_:)),
                 #selector(selectAll(_:)), #selector(copy(_:)),
                 #selector(moveWordLeft(_:)), #selector(moveWordRight(_:)),
                 #selector(moveWordLeftAndModifySelection(_:)), #selector(moveWordRightAndModifySelection(_:)):
                super.doCommand(by: selector)
            default:
                break
            }
        }
        
        // Enhanced cursor movement methods for page navigation
        private func pageUpAndMoveCursor(_ extendSelection: Bool) {
            let visibleRect = enclosingScrollView?.contentView.visibleRect ?? bounds
            let pageHeight = visibleRect.height
            let currentLocation = selectedRange().location
            
            // Calculate target position one page up
            let topPoint = NSPoint(x: visibleRect.minX, y: max(0, visibleRect.minY - pageHeight))
            let targetCharIndex = characterIndexForInsertion(at: topPoint)
            
            if extendSelection {
                setSelectedRange(NSRange(location: min(currentLocation, targetCharIndex), 
                                       length: abs(currentLocation - targetCharIndex)))
            } else {
                setSelectedRange(NSRange(location: targetCharIndex, length: 0))
            }
            scrollRangeToVisible(selectedRange())
        }
        
        private func pageDownAndMoveCursor(_ extendSelection: Bool) {
            let visibleRect = enclosingScrollView?.contentView.visibleRect ?? bounds
            let pageHeight = visibleRect.height
            let currentLocation = selectedRange().location
            
            // Calculate target position one page down
            let bottomPoint = NSPoint(x: visibleRect.minX, y: visibleRect.maxY + pageHeight)
            let targetCharIndex = min(characterIndexForInsertion(at: bottomPoint), string.count)
            
            if extendSelection {
                setSelectedRange(NSRange(location: min(currentLocation, targetCharIndex), 
                                       length: abs(currentLocation - targetCharIndex)))
            } else {
                setSelectedRange(NSRange(location: targetCharIndex, length: 0))
            }
            scrollRangeToVisible(selectedRange())
        }
        
        private func moveToBeginningOfDocumentAndMoveCursor(_ extendSelection: Bool) {
            let currentLocation = selectedRange().location
            
            if extendSelection {
                setSelectedRange(NSRange(location: 0, length: currentLocation))
            } else {
                setSelectedRange(NSRange(location: 0, length: 0))
            }
            scrollRangeToVisible(selectedRange())
        }
        
        private func moveToEndOfDocumentAndMoveCursor(_ extendSelection: Bool) {
            let currentLocation = selectedRange().location
            let endLocation = string.count
            
            if extendSelection {
                setSelectedRange(NSRange(location: min(currentLocation, endLocation), 
                                       length: abs(endLocation - currentLocation)))
            } else {
                setSelectedRange(NSRange(location: endLocation, length: 0))
            }
            scrollRangeToVisible(selectedRange())
        }
    }
    
    class Coordinator: NSObject, NSTextViewDelegate, NSWindowDelegate {
        let parent: ReadOnlyTextView
        weak var textView: NSTextView?
        
        init(_ parent: ReadOnlyTextView) {
            self.parent = parent
        }
        
        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            // Let the ReadOnlyNSTextView handle page and document navigation commands directly
            switch commandSelector {
            case #selector(NSResponder.pageUp(_:)), #selector(NSResponder.pageDown(_:)),
                 #selector(NSResponder.pageUpAndModifySelection(_:)), #selector(NSResponder.pageDownAndModifySelection(_:)),
                 #selector(NSResponder.moveToBeginningOfDocument(_:)), #selector(NSResponder.moveToEndOfDocument(_:)),
                 #selector(NSResponder.moveToBeginningOfDocumentAndModifySelection(_:)), #selector(NSResponder.moveToEndOfDocumentAndModifySelection(_:)):
                return true // Let the text view handle these with enhanced cursor positioning
            default:
                break
            }
            
            // Allow other navigation and selection commands
            switch commandSelector {
            case #selector(NSResponder.moveUp(_:)), #selector(NSResponder.moveDown(_:)),
                 #selector(NSResponder.moveLeft(_:)), #selector(NSResponder.moveRight(_:)),
                 #selector(NSResponder.moveUpAndModifySelection(_:)), #selector(NSResponder.moveDownAndModifySelection(_:)),
                 #selector(NSResponder.moveLeftAndModifySelection(_:)), #selector(NSResponder.moveRightAndModifySelection(_:)),
                 #selector(NSResponder.moveToBeginningOfLine(_:)), #selector(NSResponder.moveToEndOfLine(_:)),
                 #selector(NSResponder.moveToBeginningOfLineAndModifySelection(_:)), #selector(NSResponder.moveToEndOfLineAndModifySelection(_:)),
                 #selector(NSText.selectAll(_:)), #selector(NSText.copy(_:)),
                 #selector(NSResponder.moveWordLeft(_:)), #selector(NSResponder.moveWordRight(_:)),
                 #selector(NSResponder.moveWordLeftAndModifySelection(_:)), #selector(NSResponder.moveWordRightAndModifySelection(_:)):
                return false // Allow these commands
            default:
                return true // Block other commands
            }
        }
    }
}

#Preview {
    NotesToRepoPopupView()
}
