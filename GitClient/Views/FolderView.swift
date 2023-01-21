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
    @State private var gitDiffOutput = ""
    @State private var isLoading = false
    @State private var selectedValue: Log?
    @State private var showingBranches = false
    @State private var showingCreateNewBranchFrom: Branch?
    @State private var branch: Branch?

    var folder: Folder

    init(folder: Folder) {
        self.folder = folder
    }

    fileprivate func setModels() async {
        do {
            branch = try await Process.stdout(GitBranch(directory: folder.url)).current
            logs = try await Process.stdout(GitLog(directory: folder.url)).map { Log.committed($0) }
            let gitDiff = try await Process.stdout(GitDiff(directory: folder.url))
            let gitDiffCached = try await Process.stdout(GitDiffCached(directory: folder.url))
            gitDiffOutput = gitDiff + gitDiffCached
            if !gitDiffOutput.isEmpty {
                logs.insert(.notCommitted, at: 0)
            }
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
                BranchesView(
                    folder: folder,
                    onSelect: { branch in
                        Task {
                            do {
                                print(try await Process.stdout(
                                    GitSwitch(directory: folder.url, branchName: branch.name)
                                ))
                            } catch {
                                self.error = error
                            }
                            // Branch could be switched, but errors can still occur.
                            await setModels()
                            showingBranches = false
                        }
                    },
                    onSelectNewBranchFrom: { from in
                        showingCreateNewBranchFrom = from
                    }
                )
            }
        }
    }

    fileprivate func reloadButton() -> some View {
        return Button {
            Task {
                await setModels()
            }
        } label: {
            Image(systemName: "arrow.clockwise")
        }
        .keyboardShortcut("r")
        .help("Reload")
    }

    fileprivate func pullButton() -> some View {
        return Button {

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
                    print(try await Process.stdout(GitPush(directory: folder.url)))
                } catch {
                    self.error = error
                }
                isLoading = false
            }
        } label: {
            Image(systemName: "arrow.up")
        }
        .keyboardShortcut(.init(.upArrow))
        .help("Push")
    }

    var body: some View {
        NavigationLink(folder.displayName) {
            List(logs, selection: $selectedValue) {
                switch $0 {
                case .notCommitted:
                    NavigationLink("Not Committed") {
                        DiffView(diff: gitDiffOutput, folder: folder) {
                            Task {
                                await setModels()
                                selectedValue = logs.first
                            }
                        }
                    }
                    .foregroundColor(.secondary)
                case .committed(let commit):
                    NavigationLink(commit.title) {
                        VStack {
                            Text(commit.title)
                            Text(commit.hash)
                        }
                    }
                }
            }
            .task {
                await setModels()
            }
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
    }
}

struct CommitsView_Previews: PreviewProvider {
    static var previews: some View {
        FolderView(folder: .init(url: URL(string: "file:///maoyama/Projects/")!))
    }
}
