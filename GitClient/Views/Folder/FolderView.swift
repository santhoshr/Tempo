//
//  CommitsView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2022/09/25.
//

import SwiftUI

struct FolderView: View {
    @Environment(\.appearsActive) private var appearsActive
    var folder: Folder
    @Binding var selectionLog: Log?
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
        CommitLogView(
            logStore: $logStore,
            selectionLogID: $selectionLogID,
            showing: $showing,
            isRefresh: $isRefresh,
            error: $error
        )
        .overlay(content: {
            if logStore.commits.isEmpty && !searchTokens.isEmpty {
                Text("No Commits History")
                    .foregroundColor(.secondary)
            }
        })
        .searchable(text: $searchText, editableTokens: $searchTokens, prompt: "Search Commits", token: { $token in
            Picker(selection: $token.kind) {
                ForEach(SearchKind.allCases, id: \.self) { kind in
                    Text(kind.shortLabel).tag(kind)
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
            searchTokens = SearchTokensHandler.handle(oldTokens: oldValue, newTokens: newValue)
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
            StashChangedView(folder: folder, showingStashChanged: $showing.stashChanged)
        })
        .navigationTitle(branch?.name ?? "")
        .toolbar {
            navigationToolbar()
        }
        .toolbar {
            if isLoading {
                ProgressView()
                    .scaleEffect(x: 0.5, y: 0.5, anchor: .center)
            } else {
                addBranchButton()
                    .padding(.trailing)
                tagButton()
                stashButton()
                    .padding(.trailing)
                pullButton()
                pushButton()
            }
        }
        .onChange(of: showing.stashChanged) { _, new in
            if !new {
                Task {
                    await updateModels()
                }
            }
        }
        .onChange(of: appearsActive) { _, new in
            if new {
                Task {
                    await updateModels()
                }
            }
        }
    }

    fileprivate func refreshModels() async {
        do {
            branch = try await Process.output(GitBranch(directory: folder.url)).current
            logStore.directory = folder.url
            syncState.folderURL = folder.url
            syncState.branch = branch

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


    fileprivate func navigationToolbar() -> ToolbarItem<(), some View> {
        return ToolbarItem(placement: .navigation) {
            Button {
                showing.branches.toggle()
            } label: {
                Image(systemName: "chevron.down")
            }
            .help("Select branch.")
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
                .frame(width: 300, height: 660)
                .padding()
            }
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
        .help("Create new branch.")
    }

    fileprivate func tagButton() -> some View {
        Button {
            showing.tags.toggle()
        } label: {
            Image(systemName: "tag")
        }
        .help("Show tags.")
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
        .help("Show stashed changes.")
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
                    try await Process.output(GitPull(directory: folder.url, refspec: branch!.name))
                    await refreshModels()
                } catch {
                    self.error = error
                }
                isLoading = false
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
        .help("Pull origin \(branch?.name ?? "")." )
    }

    fileprivate func pushButton() -> some View {
        return Button {
            isLoading = true
            Task {
                do {
                    try await Process.output(GitPush(directory: folder.url))
                    await updateModels()
                } catch {
                    self.error = error
                }
                isLoading = false
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
        .help("Push origin HEAD.")
    }
}

struct CommitsView_Previews: PreviewProvider {
    @State static var selection: Log?
    @State static var refresh = false

    static var previews: some View {
        FolderView(
            folder: .init(url: URL(string: "file:///maoyama/Projects/")!),
            selectionLog: $selection,
            isRefresh: $refresh
        )
    }
}
