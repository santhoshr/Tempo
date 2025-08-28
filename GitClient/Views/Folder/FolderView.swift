//
//  CommitsView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2022/09/25.
//

import SwiftUI
import Foundation
import AppKit

struct FolderView: View {
    var folder: Folder
    @Binding var selectionLog: Log?
    @Binding var subSelectionLogID: String?
    @Binding var isRefresh: Bool
    @State private var logStore = LogStore()
    @State private var syncState = SyncState()
    @State private var isLoading = false
    @State private var error: Error?
    @State private var showing = FolderViewShowing()
    @State private var branch: Branch?
    @State private var selectionLogID: String?
    @State private var searchTokens: [SearchToken] = []
    @State private var searchText = ""
    @State private var searchTask: Task<(), Never>?
    @State private var showGraph = false
    @AppStorage(AppStorageKey.searchTokenHisrtory.rawValue) var searchTokenHistory: Data?
    private var decodedSearchTokenHistory: [SearchToken] {
        guard let searchTokenHistory else { return [] }
        do {
            return try JSONDecoder().decode([SearchToken].self, from: searchTokenHistory)
        } catch {
            return []
        }
    }
    private var suggestSearchToken: [SearchToken] {
        decodedSearchTokenHistory.filter { !searchTokens.contains($0)}
    }

    var body: some View {
        VStack(spacing: 0) {
            if showGraph {
                CommitGraphView(
                    logStore: $logStore,
                    selectionLogID: $selectionLogID,
                    subSelectionLogID: $subSelectionLogID,
                    showing: $showing,
                    isRefresh: $isRefresh
                )
            } else {
                CommitLogView(
                    logStore: $logStore,
                    selectionLogID: $selectionLogID,
                    subSelectionLogID: $subSelectionLogID,
                    showing: $showing,
                    isRefresh: $isRefresh,
                    error: $error
                )
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 0) {
                Divider()
                Spacer()
                countText()
                    .font(.callout)
                Spacer()
            }
            .frame(height: 40)
            .background(Color(nsColor: .textBackgroundColor))
            .overlay(alignment: .trailing) {
                Button(action: {
                    showGraph.toggle()
                }) {
                    Image(systemName: showGraph ? "point.3.filled.connected.trianglepath.dotted" : "point.3.connected.trianglepath.dotted")
                        .font(.title3)
                        .rotationEffect(.init(degrees: 270))
                        .foregroundStyle( showGraph ? Color.accentColor : Color.secondary)
                }
                .buttonStyle(.accessoryBar)
                .padding(.horizontal, 8)
                .help("Commit Graph")
            }
        }
        .overlay(content: {
            if logStore.commits.isEmpty && !searchTokens.isEmpty {
                Text("No Commits History")
                    .foregroundColor(.secondary)
            }
        })
        .searchable(text: $searchText, editableTokens: $searchTokens, prompt: "Search Commits", token: { $token in
            Picker(selection: $token.kind) {
                ForEach(SearchKind.allCases, id: \.self) { kind in
                    Text(kind.shortLabel)
                        .tag(kind)
                        .help(kind.help)
                }
            } label: {
                Text(token.text)
            }
        })
        .searchSuggestions({
            if searchText.isEmpty {
                if !suggestSearchToken.isEmpty {
                    Section("History") {
                        ForEach(suggestSearchToken) { token in
                            HStack {
                                Text(token.kind.label)
                                    .foregroundStyle(.secondary)
                                Text(token.text)
                            }
                                .searchCompletion(token)
                                .contextMenu {
                                    Button("Use as Text") {
                                        if searchText.isEmpty {
                                            searchText = token.text
                                        } else {
                                            searchText += " " + token.text
                                        }
                                    }
                                    Button("Delete") {
                                        var tokens = decodedSearchTokenHistory
                                        tokens.removeAll { $0 == token }
                                        do {
                                            try self.searchTokenHistory = JSONEncoder().encode(tokens)
                                        } catch {
                                            self.error = error
                                        }
                                    }
                                }
                        }
                    }
                }
            } else {
                ForEach(SearchKind.allCases, id: \.self) { kind in
                    HStack {
                        Text(kind.label)
                            .foregroundStyle(.secondary)
                        Text(searchText)
                    }
                        .searchCompletion(SearchToken(kind: kind, text: searchText))
                        .help(kind.help)
                }
            }
        })
        .task {
            await refreshModels()
        }
        .onChange(of: searchTokens, { oldValue, newValue in
            searchTokens = SearchTokensHandler.normalize(oldTokens: oldValue, newTokens: newValue)
            logStore.searchTokens = searchTokens
            searchTask?.cancel()
            searchTask = Task {
                isLoading = true
                await refreshModels()
                isLoading = false
            }
            saveSearchTokenHistory(oldValue: oldValue, newValue: newValue)
        })
        .onChange(of: selectionLogID, {
            selectionLog = logStore.logs().first { $0.id == selectionLogID }
        })
        .onChange(of: selectionLog, {
            if selectionLog == nil {
                selectionLogID = nil
                subSelectionLogID = nil
            }
        })
        .onChange(of: isRefresh, { oldValue, newValue in
            if newValue {
                Task {
                    await refreshModels()
                    isRefresh = false
                }
            }
        })
        .errorSheet($error)
        .errorSheet($logStore.error)
        .sheet(item: $showing.createNewBranchFrom, content: { _ in
            CreateNewBranchSheet(folder: folder, showingCreateNewBranchFrom: $showing.createNewBranchFrom) {
                Task {
                    await refreshModels()
                }
            }
        })
        .sheet(item: $showing.renameBranch, onDismiss: {
            Task {
                await updateModels()
            }
        }, content: { _ in
            RenameBranchSheet(folder: folder, showingRenameBranch: $showing.renameBranch)
        })
        .sheet(item: $showing.createNewTagAt, content: { _ in
            CreateNewTagSheet(folder: folder, showingCreateNewTagAt: $showing.createNewTagAt) {
                Task {
                    await refreshModels()
                }
            }
        })
        .sheet(item: $showing.amendCommitAt, content: { _ in
            AmendCommitSheet(folder: folder, showingAmendCommitAt: $showing.amendCommitAt) {
                Task {
                    await refreshModels()
                }
            }
        })
        .sheet(isPresented: $showing.stashChanged, content: {
            StashChangedView(folder: folder, showingStashChanged: $showing.stashChanged, onNavigateToUncommitted: {
                if selectionLog == .notCommitted {
                    isRefresh = true
                } else {
                    selectionLog = .notCommitted
                }
            })
        })
        .navigationTitle(branch?.name ?? "")
        .toolbar {
            if isLoading {
                ToolbarItem(placement: .primaryAction) {
                    ProgressView()
                        .scaleEffect(x: 0.5, y: 0.5, anchor: .center)
                }
            } else {
                ToolbarItem(placement: .principal) {
                    Button {
                        NSWorkspace.shared.open(folder.url)
                    } label: {
                        Image(systemName: "folder")
                    }
                    .help("Open in Finder")
                }
                ToolbarItem(placement: .principal) {
                    Button {
                        openInBrowser()
                    } label: {
                        Image(systemName: "globe")
                    }
                    .help("Open in Browser")
                }
                ToolbarItem(placement: .principal) {
                    Button {
                        openInTerminal()
                    } label: {
                        Image(systemName: "terminal")
                    }
                    .help("Open in Terminal")
                    .padding(.trailing)
                }
                ToolbarItem(placement: .principal) {
                    branchesButton()
                }
                ToolbarItem(placement: .principal) {
                    addBranchButton()
                        .padding(.trailing)
                }
                ToolbarItem(placement: .principal) {
                    tagButton()
                        .padding(.trailing)
                }
                ToolbarItem(placement: .principal) {
                    stashButton()
                        .padding(.trailing)
                }
                ToolbarItem(placement: .principal) {
                    stashActionsButton()
                        .padding(.trailing)
                }
                ToolbarItem(placement: .primaryAction) {
                    pullButton()
                }
                ToolbarItem(placement: .primaryAction) {
                    pushButton()
                }
            }
        }
        .onChange(of: showing.stashChanged) { _, new in
            if !new {
                Task {
                    await updateModels()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.willBecomeActiveNotification)) { _ in
            Task {
                await updateModels()
            }
        }
    }

    fileprivate func refreshModels() async {
        do {
            branch = try await Process.output(GitBranch(directory: folder.url)).current
            logStore.directory = folder.url
            syncState.folderURL = folder.url
            syncState.branch = branch
            if Task.isCancelled {
                throw CancellationError()
            }
            await logStore.refresh()
            if Task.isCancelled {
                throw CancellationError()
            }
            if let selectionLog {
                let newSelection = logStore.logs().first { $0.id == selectionLog.id }
                self.selectionLog = newSelection
            }
            try await syncState.sync()
        } catch {
            if !Task.isCancelled {
                self.error = error
                branch = nil
                logStore.removeAll()
            }
        }
    }

    fileprivate func updateModels() async {
        do {
            let currentBranch = try await Process.output(GitBranch(directory: folder.url)).current
            guard currentBranch == branch else { // Support for external changes made outside the app (e.g., via CLI)
                await refreshModels()
                return
            }
            await logStore.update()
            if let selectionLog {
                let newSelection = logStore.logs().first { $0.id == selectionLog.id }
                self.selectionLog = newSelection
            }
            try await syncState.sync()
        } catch {
            self.error = error
        }
    }


    fileprivate func branchesButton() -> some View {
        Button {
                showing.branches.toggle()
            } label: {
                Image(systemName: "arrow.triangle.branch")
            }
            .help("Select Branch")
            .popover(isPresented: $showing.branches) {
                TabView {
                    BranchesView(
                        folder: folder,
                        branch: branch,
                        onSelect: { branch in
                            showing.branches = false
                            Task {
                                do {
                                    try await Process.output(
                                        GitSwitch(directory: folder.url, branchName: branch.name)
                                    )
                                } catch {
                                    self.error = error
                                }
                                await refreshModels()
                            }
                        }, onSelectMergeInto: { mergeIntoBranch in
                            showing.branches = false
                            Task {
                                do {
                                    try await Process.output(GitMerge(directory: folder.url, branchName: mergeIntoBranch.name))
                                } catch {
                                    self.error = error
                                }
                                await refreshModels()
                            }
                        },
                        onSelectNewBranchFrom: { from in
                            showing.createNewBranchFrom = from
                        },
                        onSelectRenameBranch: { old in
                            showing.renameBranch = old
                        }
                    )
                        .tabItem {
                            Text("Local")
                        }
                    BranchesView(
                        folder: folder,
                        branch: branch,
                        isRemote: true,
                        onSelect: { branch in
                            showing.branches = false
                            Task {
                                do {
                                    try await Process.output(
                                        GitSwitchDetach(directory: folder.url, branchName: branch.name)
                                    )
                                } catch {
                                    self.error = error
                                }
                                await refreshModels()
                            }
                        }, onSelectMergeInto: { mergeIntoBranch in
                            showing.branches = false
                            Task {
                                do {
                                    try await Process.output(GitMerge(directory: folder.url, branchName: mergeIntoBranch.name))
                                } catch {
                                    self.error = error
                                }
                                await refreshModels()
                            }
                        },
                        onSelectNewBranchFrom: { from in
                            showing.createNewBranchFrom = from
                        }
                    )
                        .tabItem {
                            Text("Remotes")
                        }
                }
                .frame(width: 300, height: 420)
                .padding()
            }

    }

    fileprivate func saveSearchTokenHistory(oldValue: [SearchToken], newValue: [SearchToken]) {
        let newHistory = SearchTokensHandler.searchTokenHistory(currentHistory: decodedSearchTokenHistory, old: oldValue, new: newValue)
        guard newHistory != decodedSearchTokenHistory else { return }
        do {
            try self.searchTokenHistory = JSONEncoder().encode(newHistory)
        } catch {
            self.error = error
        }
    }

    fileprivate func addBranchButton() -> some View {
        Button {
            showing.createNewBranchFrom = branch
        } label: {
            Image(systemName: "plus")
        }
        .help("Create New Branch")
    }

    fileprivate func tagButton() -> some View {
        Button {
            showing.tags.toggle()
        } label: {
            Image(systemName: "tag")
        }
        .help("Show Tags")
        .popover(isPresented: $showing.tags, content: {
            TagsView(folder: folder, showingTags: $showing.tags)
        })
        .onChange(of: showing.tags) { oldValue, newValue in
            if oldValue && !newValue {
                Task {
                    await refreshModels()
                }
            }
        }
    }

    fileprivate func stashButton() -> some View {
        Button {
            showing.stashChanged.toggle()
        } label: {
            Image(systemName: "tray")
        }
        .help("Show Stashed Changes")
    }

    fileprivate func stashTextRow(_ title: String, help: String, action: @escaping () -> Void) -> some View {
        Text(title)
            .font(.system(size: 13))
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture(perform: action)
            .help(help)
    }

    fileprivate func stashActionsButton() -> some View {
        Button {
            showing.stashMenu.toggle()
        } label: {
            Image(systemName: "tray.and.arrow.down")
        }
        .help("Stash Options")
        .popover(isPresented: $showing.stashMenu) {
            VStack(alignment: .leading, spacing: 0) {
                menuItem("Stash", icon: "tray.and.arrow.down", help: "Stash staged + unstaged. Working tree cleared of changes; untracked files unaffected.") {
                    runStash(keepIndex: false, includeUntracked: false)
                }
                
                menuItem("Stash +Index", icon: "tray.and.arrow.down", help: "Stash staged + unstaged, but keep index (staged) intact. Working tree cleared of unstaged; untracked unaffected.") {
                    runStash(keepIndex: true, includeUntracked: false)
                }
                
                Divider()
                    .padding(.horizontal, 8)
                
                menuItem("Stash Staged", icon: "tray.and.arrow.down.fill", help: "Stash only staged changes. Working tree untouched except staged paths may reflect indexed content; untracked unaffected.") {
                    runStashStaged(keepIndex: false)
                }
                
                Divider()
                    .padding(.horizontal, 8)
                
                menuItem("Stash Untracked", icon: "tray.and.arrow.down", help: "Stash untracked files too. Working tree cleared of untracked and tracked changes.") {
                    runStash(keepIndex: false, includeUntracked: true)
                }
                
                menuItem("Stash Untracked +Index", icon: "tray.and.arrow.down", help: "Stash untracked + staged/unstaged, keep index intact. Working tree cleared of unstaged + untracked.") {
                    runStash(keepIndex: true, includeUntracked: true)
                }
                
                Divider()
                    .padding(.horizontal, 8)
                
                menuItem("Clear all stashes", icon: "trash", help: "Delete all stashes. Irreversible.") {
                    runStashClear()
                }
                
                menuItem("Clear & keep last 5", icon: "trash", help: "Deletes older stashes, keeps the 5 most recent.") {
                    runStashKeepLast(5)
                }
            }
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .shadow(radius: 8)
            .frame(minWidth: 200)
        }
    }
    
    fileprivate func menuItem(_ title: String, icon: String, help: String, action: @escaping () -> Void) -> some View {
        Button(action: {
            showing.stashMenu = false
            action()
        }) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .frame(width: 16)
                    .foregroundColor(.primary)
                Text(title)
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .background(Color.clear)
        .onHover { isHovered in
            // Menu item hover effect could be added here
        }
        .help(help)
    }

    fileprivate func badge() -> some View {
        return Circle()
            .fill(Color.accentColor)
            .foregroundColor(.white)
            .frame(width: 6)
            .offset(x: 2, y: -2)
    }
    
    fileprivate func pullButton() -> some View {
        return Button {
            isLoading = true
            Task {
                do {
                    try await GitFetchExecutor.shared.execute(GitPull(directory: folder.url, refspec: branch!.name))
                    syncState.shouldPull = false
                    isLoading = false
                    await refreshModels()
                } catch {
                    isLoading = false
                    self.error = error
                }
            }
        } label: {
            Image(systemName: "arrow.down")
                .overlay(alignment: .topTrailing, content: {
                    badge()
                        .animation(.default, body: { content in
                            content
                                .opacity(syncState.shouldPull ? 1 : 0)
                        })
                })
        }
        .help("Pull origin \(branch?.name ?? "")" )
    }

    fileprivate func pushButton() -> some View {
        return Button {
            isLoading = true
            Task {
                do {
                    try await Process.output(GitPush(directory: folder.url))
                    syncState.shouldPush = false
                    isLoading = false
                    await updateModels()
                } catch {
                    isLoading = false
                    self.error = error
                }
            }
        } label: {
            Image(systemName: "arrow.up")
                .overlay(alignment: .topTrailing, content: {
                        badge()
                            .animation(.default, body: { content in
                                content
                                    .opacity(syncState.shouldPush ? 1 : 0)
                            })
                })
        }
        .help("Push origin HEAD")
    }

    fileprivate func countText() -> some View {
        if let count = logStore.totalCommitsCount {
            let subText: String
            if count == 1 {
                subText = "Commit"
            } else {
                subText = "Commits"
            }
            return Text("\(count) \(subText)")
        } else {
            return Text("")
        }
    }
    
    fileprivate func runStash(keepIndex: Bool, includeUntracked: Bool) {
        showing.stashMenu = false
        isLoading = true
        Task {
            do {
                try await Process.output(GitStash(directory: folder.url, message: "", keepIndex: keepIndex, includeUntracked: includeUntracked))
                isLoading = false
                await refreshModels()
                await MainActor.run {
                    isRefresh.toggle()
                }
            } catch {
                isLoading = false
                self.error = error
            }
        }
    }

    fileprivate func runStashStaged(keepIndex: Bool) {
        showing.stashMenu = false
        isLoading = true
        Task {
            do {
                try await Process.output(GitStashStaged(directory: folder.url, message: "", keepIndex: keepIndex))
                isLoading = false
                await refreshModels()
                await MainActor.run {
                    isRefresh.toggle()
                }
            } catch {
                isLoading = false
                self.error = error
            }
        }
    }

    fileprivate func runStashClear() {
        showing.stashMenu = false
        isLoading = true
        Task {
            do {
                try await Process.output(GitStashClear(directory: folder.url))
                isLoading = false
                await refreshModels()
            } catch {
                isLoading = false
                self.error = error
            }
        }
    }

    fileprivate func runStashKeepLast(_ keepLast: Int) {
        showing.stashMenu = false
        isLoading = true
        Task {
            do {
                let list = try await Process.output(GitStashList(directory: folder.url))
                if list.count > keepLast {
                    // Drop from oldest to the keepLast-th (descending indices)
                    for idx in stride(from: list.count - 1, through: keepLast, by: -1) {
                        try await Process.output(GitStashDrop(directory: folder.url, index: idx))
                    }
                }
                isLoading = false
                await refreshModels()
            } catch {
                isLoading = false
                self.error = error
            }
        }
    }

    // Deprecated: replaced by stashActionsButton
    @available(*, deprecated)
    fileprivate func stashChangesButton() -> some View {
        Button {
            isLoading = true
            Task {
                do {
                    try await Process.output(GitStash(directory: folder.url))
                    isLoading = false
                    await refreshModels()
                    // Trigger parent view refresh like the built-in stash functionality
                    await MainActor.run {
                        isRefresh.toggle()
                    }
                } catch {
                    isLoading = false
                    self.error = error
                }
            }
        } label: {
            Image(systemName: "tray.and.arrow.down")
        }
        .help("Stash Changes")
    }
    
    // Deprecated: replaced by stashActionsButton
    @available(*, deprecated)
    fileprivate func stashStagedButton() -> some View {
        Button {
            isLoading = true
            Task {
                do {
                    try await Process.output(GitStashStaged(directory: folder.url))
                    isLoading = false
                    await refreshModels()
                    // Trigger parent view refresh like the built-in stash functionality
                    await MainActor.run {
                        isRefresh.toggle()
                    }
                } catch {
                    isLoading = false
                    self.error = error
                }
            }
        } label: {
            Image(systemName: "tray.and.arrow.down.fill")
        }
        .help("Stash Staged Changes Only")
    }
    
    fileprivate func openInBrowser() {
        // Check if there's a remote URL in git config
        let gitConfigURL = folder.url.appendingPathComponent(".git/config")
        
        if FileManager.default.fileExists(atPath: gitConfigURL.path) {
            do {
                let gitConfig = try String(contentsOf: gitConfigURL)
                
                // Look for remote origin URL
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
                        
                        // Convert SSH URLs to HTTPS
                        var webURL = urlString
                        if webURL.hasPrefix("git@github.com:") {
                            webURL = webURL.replacingOccurrences(of: "git@github.com:", with: "https://github.com/")
                        } else if webURL.hasPrefix("git@gitlab.com:") {
                            webURL = webURL.replacingOccurrences(of: "git@gitlab.com:", with: "https://gitlab.com/")
                        } else if webURL.hasPrefix("git@bitbucket.org:") {
                            webURL = webURL.replacingOccurrences(of: "git@bitbucket.org:", with: "https://bitbucket.org/")
                        }
                        
                        // Remove .git suffix
                        if webURL.hasSuffix(".git") {
                            webURL = String(webURL.dropLast(4))
                        }
                        
                        if let url = URL(string: webURL) {
                            NSWorkspace.shared.open(url)
                            return
                        }
                    }
                }
            } catch {
                // If we can't read git config, fall back to opening the folder
            }
        }
        
        // Fallback: open the folder in Finder
        NSWorkspace.shared.open(folder.url)
    }
    
    fileprivate func openInTerminal() {
        // Get terminal settings from app storage
        if let terminalSettingsData = UserDefaults.standard.data(forKey: AppStorageKey.terminalSettings.rawValue) {
            do {
                let terminalSettings = try JSONDecoder().decode(TerminalSettings.self, from: terminalSettingsData)
                if let selectedTerminal = terminalSettings.selectedTerminal {
                    let customArguments = terminalSettings.customArguments(for: selectedTerminal.bundleIdentifier)
                    selectedTerminal.openTerminal(at: folder.url, customArguments: customArguments)
                    return
                }
            } catch {
                // Fall back to default if decoding fails
            }
        }
        
        // Fallback to default Terminal.app
        let defaultTerminal = TerminalApp.availableTerminals.first { $0.bundleIdentifier == "com.apple.Terminal" }
        defaultTerminal?.openTerminal(at: folder.url)
    }
    
}

struct CommitsView_Previews: PreviewProvider {
    @State static var selection: Log?
    @State static var subSelection: String?
    @State static var refresh = false

    static var previews: some View {
        FolderView(
            folder: .init(url: URL(string: "file:///maoyama/Projects/")!),
            selectionLog: $selection,
            subSelectionLogID: $subSelection,
            isRefresh: $refresh
        )
    }
}
