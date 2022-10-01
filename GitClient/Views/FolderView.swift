//
//  CommitsView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2022/09/25.
//

import SwiftUI

struct FolderView: View {
    @State private var commits: [Commit] = []
    @State private var error: Error?
    @State private var gitDiffOutput = ""
    @State private var isLoading = false
    @State private var selectedValue: Commit?

    var folder: Folder

    init(folder: Folder) {
        self.folder = folder
    }

    fileprivate func setCommitsAndDiff() async {
        do {
            self.commits = try await Process.stdout(GitLog(directory: folder.url))
            let gitDiff = try await Process.stdout(GitDiff(directory: folder.url))
            let gitDiffCached = try await Process.stdout(GitDiffCached(directory: folder.url))
            self.gitDiffOutput = gitDiff + gitDiffCached
        } catch {
            self.error = error
        }
    }

    var body: some View {
        NavigationLink(folder.displayName) {
            List(selection: $selectedValue) {
                if !gitDiffOutput.isEmpty {
                    NavigationLink("Not Commited") {
                        DiffView(diff: gitDiffOutput)
                    }
                    .foregroundColor(.secondary)
                }
                ForEach(commits, id: \.hash) { commit in
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

                    } label: {
                        Image(systemName: "chevron.down")
                    }
                    .help("Change Branch")
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
                    .help("Reload")
                    Button {

                    } label: {
                        Image(systemName: "arrow.down")
                    }
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
