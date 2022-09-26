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

    var folder: Folder

    init(folder: Folder) {
        self.folder = folder
    }

    var body: some View {
        NavigationLink(folder.displayName) {
            List {
                if !gitDiffOutput.isEmpty {
                    NavigationLink("Not Commited") {
                        ScrollView {
                            Text(gitDiffOutput)
                                .font(Font.system(.body, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                        }
                    }
                    .foregroundColor(.secondary)
                }
                ForEach(commits) { commit in
                    NavigationLink(commit.title) {
                        VStack {
                            Text(commit.title)
                            Text(commit.id)
                        }
                    }
                }
            }
            .onAppear {
                do {
                    self.commits = try Process.run(GitLog(directory: folder.url))
                    let gitDiff = try Process.run(GitDiff(directory: folder.url))
                    let gitDiffCached = try Process.run(GitDiffCached(directory: folder.url))
                    self.gitDiffOutput = gitDiff + gitDiffCached
                } catch {
                    self.error = error
                }
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
                Button {

                } label: {
                    Image(systemName: "arrow.down")
                }
                .help("Pull")
                Button {

                } label: {
                    Image(systemName: "arrow.up")
                }
                .help("Push")
            }
        }
    }
}

struct CommitsView_Previews: PreviewProvider {
    static var previews: some View {
        FolderView(folder: .init(url: URL(string: "file:///maoyama/Projects/")!))
    }
}
