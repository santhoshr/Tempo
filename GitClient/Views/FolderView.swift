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

    var folder: Folder

    init(folder: Folder) {
        self.folder = folder
    }

    fileprivate func setCommitsAndDiff() async {
        do {
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

    var body: some View {
        NavigationLink(folder.displayName) {
            List(logs, selection: $selectedValue) {
                switch $0 {
                case .notCommitted:
                    NavigationLink("Not Committed") {
                        DiffView(diff: gitDiffOutput, folder: folder) {
                            Task {
                                await setCommitsAndDiff()
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
                await setCommitsAndDiff()
            }
            .errorAlert($error)
            .navigationTitle(folder.displayName)
            .navigationSubtitle("main")
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button {
                        showingBranches.toggle()
                    } label: {
                        Image(systemName: "chevron.down")
                    }
                    .help("Change Branch")
                    .popover(isPresented: $showingBranches) {
                        BranchesView()
                    }
                }
            }
            .toolbar {
                if isLoading {
                    ProgressView()
                        .scaleEffect(x: 0.5, y: 0.5, anchor: .center)
                } else {
                    Button {
                        Task {
                            await setCommitsAndDiff()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .keyboardShortcut("r")
                    .help("Reload")

                    Button {

                    } label: {
                        Image(systemName: "arrow.down")
                    }
                    .keyboardShortcut(.init(.downArrow))
                    .help("Pull")

                    Button {
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
            }
        }
    }
}

struct CommitsView_Previews: PreviewProvider {
    static var previews: some View {
        FolderView(folder: .init(url: URL(string: "file:///maoyama/Projects/")!))
    }
}
