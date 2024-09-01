//
//  CommitsView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2022/09/25.
//

import SwiftUI

struct FolderView: View {
    @State private var logs: [Log] = []
    @State private var error: Error?
    @State private var isLoading = false
    @State private var showingBranches = false
    @State private var showingCreateNewBranchFrom: Branch?
    @State private var branch: Branch?
    @State private var selectionLogID: String? 
    var folder: Folder
    @Binding var selectionLog: Log?
    @Binding var isRefresh: Bool

    var body: some View {
        List(logs, selection: $selectionLogID) {
            switch $0 {
            case .notCommitted:
                Text("Not Committed")
                    .foregroundStyle(Color.secondary)
            case .committed(let commit):
                Text(commit.title)
                    .contextMenu {
                        Button("Checkout") {
                            Task {
                                do {
                                    try await Process.output(GitCheckout(directory: folder.url, commitHash: commit.hash))
                                    await setModels()
                                } catch {
                                    self.error = error
                                }
                            }
                        }
                    }
            }
        }
        .onChange(of: folder, initial: true, {
            Task {
                await setModels()
            }
        })
        .onChange(of: selectionLogID, {
            selectionLog = logs.first { $0.id == selectionLogID }
        })
        .onChange(of: selectionLog, {
            if selectionLog == nil {
                selectionLogID = nil
            }
        })
        .onChange(of: isRefresh, { oldValue, newValue in
            if newValue {
                Task {
                    await setModels()
                    isRefresh = false
                }
            }
        })
        .errorAlert($error)
        .sheet(item: $showingCreateNewBranchFrom, content: { _ in
            CreateNewBranchSheet(folder: folder, showingCreateNewBranchFrom: $showingCreateNewBranchFrom) {
                Task {
                    await setModels()
                }
            }
        })
        .navigationTitle(folder.displayName)
        .navigationSubtitle(branch?.name ?? "")
        .toolbar {
            navigationToolbar()
        }
        .toolbar {
            if isLoading {
                ProgressView()
                    .scaleEffect(x: 0.5, y: 0.5, anchor: .center)
            } else {
                reloadButton()
                pullButton()
                pushButton()
            }
        }
    }

    fileprivate func setModels() async {
        do {
            branch = try await Process.output(GitBranch(directory: folder.url)).current
            var newLogs = try await Process.output(GitLog(directory: folder.url)).map { Log.committed($0) }
            let gitDiff = try await Process.output(GitDiff(directory: folder.url))
            let gitDiffCached = try await Process.output(GitDiffCached(directory: folder.url))
            let newNotCommitted = NotCommitted(diff: gitDiff, diffCached: gitDiffCached)
            if !newNotCommitted.isEmpty {
                newLogs.insert(.notCommitted, at: 0)
            }
            logs = newLogs
        } catch {
            self.error = error
            branch = nil
            logs = []
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
                                await setModels()
                                showingBranches = false
                            }
                        }, onSelectMergeInto: { mergeIntoBranch in
                            Task {
                                do {
                                    try await Process.output(GitMerge(directory: folder.url, branchName: mergeIntoBranch.name))
                                } catch {
                                    self.error = error
                                }
                                await setModels()
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
                                await setModels()
                                showingBranches = false
                            }
                        }, onSelectMergeInto: { mergeIntoBranch in
                            Task {
                                do {
                                    try await Process.output(GitMerge(directory: folder.url, branchName: mergeIntoBranch.name))
                                } catch {
                                    self.error = error
                                }
                                await setModels()
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

    fileprivate func reloadButton() -> some View {
        return Button {
            isRefresh = true
        } label: {
            Image(systemName: "arrow.clockwise")
        }
        .keyboardShortcut("r")
        .help("Reload")
    }

    fileprivate func pullButton() -> some View {
        return Button {
            isLoading = true
            Task {
                do {
                    try await Process.output(GitPull(directory: folder.url))
                    await setModels()
                } catch {
                    self.error = error
                }
                isLoading = false
            }
        } label: {
            Image(systemName: "arrow.down")
        }
        .keyboardShortcut(.init(.downArrow))
        .help("Pull")
    }

    fileprivate func pushButton() -> some View {
        return Button {
            isLoading = true
            Task {
                do {
                    try await Process.output(GitPush(directory: folder.url))
                } catch {
                    self.error = error
                }
                isLoading = false
            }
        } label: {
            Image(systemName: "arrow.up")
        }
        .keyboardShortcut(.init(.upArrow))
        .help("Push origin HEAD")
    }
}

struct CommitsView_Previews: PreviewProvider {
    @State static var selection: Log?
    @State static var refresh = false
    static var previews: some View {
        FolderView(folder: .init(url: URL(string: "file:///maoyama/Projects/")!), selectionLog: $selection, isRefresh: $refresh)
    }
}
