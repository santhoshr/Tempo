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
    @StateObject var logStore: LogStore
    @Binding var selectionLog: Log?
    @Binding var selectionCommit: Commit?
    @Binding var isRefresh: Bool
    @Binding var lastSyncDate: Date?
    @State private var isLoading = false
    @State private var error: Error?
    @State private var showingBranches = false
    @State private var showingCreateNewBranchFrom: Branch?
    @State private var showingStashChanged = false
    @State private var showingTags = false
    @State private var showingCreateNewTagAt: Commit?
    @State private var branch: Branch?
    @State private var selectionLogID: String?

    var body: some View {
        List(logStore.logs(), selection: $selectionLogID) { log in
            logsRow(log)
                .task {
                    await logStore.logViewTask(log)
                }
        }
        .task {
            await refreshModels()
        }
        .onChange(of: selectionLogID, {
            selectionLog = logStore.logs().first { $0.id == selectionLogID }
        })
        .onChange(of: selectionLog, {
            switch selectionLog {
            case .notCommitted, nil:
                selectionCommit = nil
            case .committed(let commit):
                selectionCommit = commit
            }
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
        .sheet(item: $showingCreateNewBranchFrom, content: { _ in
            CreateNewBranchSheet(folder: folder, showingCreateNewBranchFrom: $showingCreateNewBranchFrom) {
                Task {
                    await refreshModels()
                }
            }
        })
        .sheet(item: $showingCreateNewTagAt, content: { _ in
            CreateNewTagSheet(folder: folder, showingCreateNewTagAt: $showingCreateNewTagAt) {
                Task {
                    await refreshModels()
                }
            }
        })
        .sheet(isPresented: $showingStashChanged, content: {
            StashChangedView(folder: folder, showingStashChanged: $showingStashChanged)
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
        .onChange(of: showingStashChanged) { _, new in
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
            if let selectionLog {
                let newSelection = logStore.logs().first { $0.id == selectionLog.id }
                self.selectionLog = newSelection
            }
            lastSyncDate = Date()
        } catch {
            self.error = error
            branch = nil
            logStore.removeAll()
        }
    }

    fileprivate func updateModels() async {
        do {
            let currentBranch = try await Process.output(GitBranch(directory: folder.url)).current
            guard currentBranch == branch else {
                await refreshModels()
                lastSyncDate = Date()
                return
            }
            await logStore.update()
            if let selectionLog {
                let newSelection = logStore.logs().first { $0.id == selectionLog.id }
                self.selectionLog = newSelection
            }
            lastSyncDate = Date()
        } catch {
            self.error = error
        }
    }


    fileprivate func navigationToolbar() -> ToolbarItem<(), some View> {
        return ToolbarItem(placement: .navigation) {
            Button {
                showingBranches.toggle()
            } label: {
                Image(systemName: "chevron.down")
            }
            .help("Select Branch")
            .popover(isPresented: $showingBranches) {
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
                                showingBranches = false
                            }
                        }, onSelectMergeInto: { mergeIntoBranch in
                            Task {
                                do {
                                    try await Process.output(GitMerge(directory: folder.url, branchName: mergeIntoBranch.name))
                                } catch {
                                    self.error = error
                                }
                                await refreshModels()
                                showingBranches = false
                            }
                        },
                        onSelectNewBranchFrom: { from in
                            showingCreateNewBranchFrom = from
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
                                showingBranches = false
                            }
                        }, onSelectMergeInto: { mergeIntoBranch in
                            Task {
                                do {
                                    try await Process.output(GitMerge(directory: folder.url, branchName: mergeIntoBranch.name))
                                } catch {
                                    self.error = error
                                }
                                await refreshModels()
                                showingBranches = false
                            }
                        },
                        onSelectNewBranchFrom: { from in
                            showingCreateNewBranchFrom = from
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

    fileprivate func logsRow(_ log: Log) -> VStack<_ConditionalContent<Text, some View>> {
        return VStack {
            switch log {
            case .notCommitted:
                Text("Not Committed")
                    .foregroundStyle(Color.secondary)
            case .committed(let commit):
                VStack (alignment: .leading) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(commit.title)
                        Spacer()
                        Text(commit.hash.prefix(5))
                            .font(Font.system(.body, design: .rounded))
                            .foregroundStyle(.tertiary)
                        if commit.abbreviatedParentHashes.count == 2 {
                            Image(systemName: "arrow.triangle.merge")
                                .foregroundStyle(.tertiary)
                        }
                    }
                    HStack {
                        AsyncImage(url: URL.gravater(email: commit.authorEmail, size: 14*3)) { image in
                            image.resizable()
                        } placeholder: {
                            RoundedRectangle(cornerSize: .init(width: 3, height: 3), style: .circular)
                                .foregroundStyle(.quinary)
                        }
                            .frame(width: 14, height: 14)
                            .clipShape(RoundedRectangle(cornerSize: .init(width: 3, height: 3), style: .circular))
                        Text(commit.author)
                        Spacer()
                        Text(commit.authorDateRelative)
                    }
                    .lineLimit(1)
                    .foregroundStyle(.tertiary)
                }
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
                    Button("Revert" + (commit.abbreviatedParentHashes.count == 2 ? " -m 1 (\(commit.abbreviatedParentHashes[0]))" : "")) {
                        Task {
                            do {
                                if commit.abbreviatedParentHashes.count == 2 {
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
                        showingCreateNewTagAt = commit
                    }
                }
            }

        }
    }

    fileprivate func tagButton() -> some View {
        Button {
            showingTags.toggle()
        } label: {
            Image(systemName: "tag")
        }
        .help("Tags")
        .popover(isPresented: $showingTags, content: {
            TagsView(folder: folder, showingTags: $showingTags)
        })
        .onChange(of: showingTags) { oldValue, newValue in
            if oldValue && !newValue {
                Task {
                    await refreshModels()
                }
            }
        }
    }

    fileprivate func stashButton() -> some View {
        Button {
            showingStashChanged.toggle()
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
    @State static var selectionCommit: Commit?
    @State static var refresh = false
    @State static var lastSyncDate: Date?

    static var previews: some View {
        FolderView(
            folder: .init(url: URL(string: "file:///maoyama/Projects/")!),
            logStore: .init(directory: URL(string: "file:///maoyama/Projects/")!),
            selectionLog: $selection,
            selectionCommit: $selectionCommit,
            isRefresh: $refresh,
            lastSyncDate: $lastSyncDate
        )
    }
}
