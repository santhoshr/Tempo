//
//  MergeCommitContentView.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/10/13.
//

import SwiftUI

struct MergeCommitContentView: View {
    var mergeCommit: CommitDetail
    var directoryURL: URL
    @State private var commits: [Commit] = []
    @State private var filesChanged: FileDiff?
    @State private var error: Error?
    @State private var tab = 0

    var body: some View {
        VStack(alignment: .leading) {
            CommitTabView(tab: $tab)
                .padding(.bottom)
            if tab == 0 {
                HStack(alignment: .top, spacing: 16) {
                    CommitsView(commits: commits)
                    VStack(alignment: .leading) {
                        HStack {
                            Image(systemName: "arrow.triangle.merge")
                            Text("2 parents")
                        }
                        HStack {
                            NavigationLink(mergeCommit.abbreviatedParentHashes[0], value: mergeCommit.abbreviatedParentHashes[0])
                            Text("+")
                            NavigationLink(mergeCommit.abbreviatedParentHashes[1], value: mergeCommit.abbreviatedParentHashes[1])
                        }
                    }
                    .buttonStyle(.link)
                }
            }
        }
        .padding(.bottom)
        .onChange(of: mergeCommit, initial: true) { _, _ in
            Task {
                do {
                    commits = try await Array(Process.output(GitLog(directory: directoryURL, revisionRange: "\(mergeCommit.abbreviatedParentHashes[0])..\(mergeCommit.hash)")).dropFirst())
                } catch {
                    self.error = error
                }
            }
        }
        .errorAlert($error)
    }
}

#Preview {
    ScrollView {
        MergeCommitContentView(
            mergeCommit: .init(
                hash: "11fff",
                abbreviatedParentHashes: ["21fff", "31fff"],
                author: "maoyama",
                authorEmail: "a@aoyama.dev",
                authorDate: "1 seconds ago",
                title: "Hello world!",
                body: "body",
                branches: [],
                tags: [],
                diff: try! Diff(raw: "")),
            directoryURL: URL(string: "file:///maoyama/Projects/")!
        )
    }
}

struct CommitsView: View {
    var commits: [Commit]

    var body: some View {
        LazyVStack {
            ForEach(commits) { commit in
                NavigationLink(value: commit.hash) {
                    VStack (alignment: .leading) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(commit.title)
                            Spacer()
                            Text(commit.hash.prefix(5))
                                .font(Font.system(.body, design: .rounded))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.bottom, 4)
                        HStack {
                            Text(commit.author)
                            Spacer()
                            Text(commit.authorDateRelative)
                        }
                        .lineLimit(1)
                        .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)
                if commits.last != commit {
                    Divider()
                }
            }
            .accentColor(.primary)
        }
    }
}

struct CommitTabView: View {
    @Binding var tab: Int

    var body: some View {
        HStack {
            Button {
                tab = 0
            } label: {
                Image(systemName: "circle.circle")
                Text("Commits")
            }
            .disabled(tab == 0)
            Divider()
            Button {
                tab = 1
            } label: {
                Image(systemName: "plusminus")
                Text("Files Changed")
            }
            .disabled(tab == 1)
        }.buttonStyle(.borderless)
    }
}
