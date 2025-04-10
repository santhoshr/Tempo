//
//  CommitsView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2022/09/25.
//

import SwiftUI

struct Showing {
    var branches = false
    var createNewBranchFrom: Branch?
    var renameBranch: Branch?
    var stashChanged = false
    var tags = false
    var createNewTagAt: Commit?
    var amendCommitAt: Commit?
}

struct FolderView: View {
    @Environment(\.appearsActive) private var appearsActive
    var folder: Folder
    @Binding var selectionLog: Log?
    @Binding var isRefresh: Bool
    @State private var logStore = LogStore()
    @State private var isLoading = false
    @State private var error: Error?
    @State private var showing = Showing()
    @State private var branch: Branch?
    @State private var selectionLogID: String?
    @State private var searchTokens: [SearchToken] = []
    @State private var searchText = ""
    @State private var searchTask: Task<(), Never>?

    var body: some View {
        List(logStore.logs(), selection: $selectionLogID) { log in
            logsRow(log)
                .task {
                    await logStore.logViewTask(log)
                }
        }
        .overlay(content: {
            if logStore.commits.isEmpty && !searchTokens.isEmpty  {
                Text("No Commits History")
                    .foregroundColor(.secondary)
            }
        })
        .searchable(text: $searchText, editableTokens: $searchTokens, prompt: "Search Commits", token: { $token in
            Picker(selection: $token.kind) {
                Text("Message").tag(SearchKind.grep)
                Text("Message(A)").tag(SearchKind.grepAllMatch)
                Text("Changed").tag(SearchKind.g)
                Text("Changed(O)").tag(SearchKind.s)
                Text("Author").tag(SearchKind.author)
            } label: {
                Text(token.text)
            }
        })
        .searchSuggestions({
            if !searchText.isEmpty {
                Text("Message: " + searchText).searchCompletion(SearchToken(kind: .grep, text: searchText))
                    .help("Search log messages matching the given pattern (regular expression).")
                Text("Message(All Match): " + searchText).searchCompletion(SearchToken(kind: .grepAllMatch, text: searchText))
                    .help("Search log messages matching all given patterns instead of at least one.")
                Text("Changed: " + searchText).searchCompletion(SearchToken(kind: .g, text: searchText))
                    .help("Search commits with added/removed lines that match the specified regex. ")
                Text("Changed(Occurrences): " + searchText).searchCompletion(SearchToken(kind: .s, text: searchText))
                    .help("Search commits where the number of occurrences of the specified regex has changed (added/removed).")
                Text("Author: " + searchText).searchCompletion(SearchToken(kind: .author, text: searchText))
                    .help("Search commits by author matching the given pattern (regular expression).")
            }
        })
        .onChange(of: searchTokens, { oldValue, newValue in
            if oldValue != newValue {
                searchTokens = SearchTokensHandler.handle(oldTokens: oldValue, newTokens: newValue)
                logStore.searchTokens = searchTokens
                searchTask?.cancel()
                searchTask = Task {
                    isLoading = true
                    await refreshModels()
                    isLoading = false
                }
            }
        })
        .task {
            await refreshModels()
        }
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
        .errorAlert($error)
        .errorAlert($logStore.error)
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
            await logStore.refresh()
            if Task.isCancelled {
                throw CancellationError()
            }
            if let selectionLog {
                let newSelection = logStore.logs().first { $0.id == selectionLog.id }
                self.selectionLog = newSelection
            }
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
            .help("Select Branch")
            .popover(isPresented: $showing.branches) {
                TabView {
                    BranchesView(
                        folder: folder,
                        branch: branch,
                        onSelect: { branch in
                            Task {
                                do {
                                    try await Process.output(
                                        GitSwitch(directory: folder.url, branchName: branch.name)
                                    )
                                } catch {
                                    self.error = error
                                }
                                await refreshModels()
                                showing.branches = false
                            }
                        }, onSelectMergeInto: { mergeIntoBranch in
                            Task {
                                do {
                                    try await Process.output(GitMerge(directory: folder.url, branchName: mergeIntoBranch.name))
                                } catch {
                                    self.error = error
                                }
                                await refreshModels()
                                showing.branches = false
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
                            Task {
                                do {
                                    try await Process.output(
                                        GitSwitchDetach(directory: folder.url, branchName: branch.name)
                                    )
                                } catch {
                                    self.error = error
                                }
                                await refreshModels()
                                showing.branches = false
                            }
                        }, onSelectMergeInto: { mergeIntoBranch in
                            Task {
                                do {
                                    try await Process.output(GitMerge(directory: folder.url, branchName: mergeIntoBranch.name))
                                } catch {
                                    self.error = error
                                }
                                await refreshModels()
                                showing.branches = false
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

    fileprivate func logsRow(_ log: Log) -> some View {
        return VStack {
            switch log {
            case .notCommitted:
                Text("Not Committed")
                    .foregroundStyle(Color.secondary)
            case .committed(let commit):
                CommitRowView(commit: commit)
                    .contextMenu {
                        Button("Checkout") {
                            Task {
                                do {
                                    try await Process.output(GitCheckout(directory: folder.url, commitHash: commit.hash))
                                    await refreshModels()
                                } catch {
                                    self.error = error
                                }
                            }
                        }
                        Button("Revert" + (commit.parentHashes.count == 2 ? " -m 1 (\(commit.parentHashes[0].prefix(7)))" : "")) {
                            Task {
                                do {
                                    if commit.parentHashes.count == 2 {
                                        try await Process.output(GitRevert(directory: folder.url, commitHash: commit.hash, parentNumber: 1))
                                    } else {
                                        try await Process.output(GitRevert(directory: folder.url, commitHash: commit.hash))
                                    }
                                    await refreshModels()
                                } catch {
                                    self.error = error
                                }
                            }
                        }
                        Button("Tag") {
                            showing.createNewTagAt = commit
                        }
                        if commit == logStore.commits.first {
                            if let notCommitted = logStore.notCommitted {
                                if notCommitted.diffCached.isEmpty {
                                    Button("Amend") {
                                        showing.amendCommitAt = commit
                                    }
                                }
                            } else {
                                Button("Amend") {
                                    showing.amendCommitAt = commit
                                }
                            }
                        }
                    }
            }

        }
    }

    fileprivate func tagButton() -> some View {
        Button {
            showing.tags.toggle()
        } label: {
            Image(systemName: "tag")
        }
        .help("Tags")
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
        .help("Stashed Changes")
    }

    fileprivate func pullButton() -> some View {
        return Button {
            isLoading = true
            Task {
                do {
                    try await Process.output(GitPull(directory: folder.url))
                    await refreshModels()
                } catch {
                    self.error = error
                }
                isLoading = false
            }
        } label: {
            Image(systemName: "arrow.down")
        }
        .help("Pull")
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
        }
        .help("Push origin HEAD")
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
